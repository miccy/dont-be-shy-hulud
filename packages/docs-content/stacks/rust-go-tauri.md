---
title: Rust, Go & Tauri Security
description: Cross-language projects share npm risks through build tooling
sidebar:
  order: 5
lastUpdated: 2025-12-05
---

# 🦀 Rust, Go & Tauri Security Guide

> **Cross-language projects share npm risks through build tooling!**

Even if your main application is written in Rust, Go, or uses Tauri, you're still exposed to npm supply chain attacks through build tools, WASM compilation, and hybrid architectures.

## ⚠️ Critical Risks

### How npm Affects Non-JS Projects

```
┌─────────────────────────────────────────────────────────────────┐
│  🔗 CROSS-LANGUAGE ATTACK VECTORS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. TAURI FRONTEND                                              │
│     └── Tauri apps have a web frontend (React, Vue, Svelte)     │
│     └── npm install runs during build                           │
│     └── Compromised package = compromised desktop app           │
│                                                                 │
│  2. WASM TOOLING                                                │
│     └── wasm-pack, wasm-bindgen use npm for JS glue             │
│     └── Build scripts can execute malicious code                │
│     └── Published WASM packages may include npm deps            │
│                                                                 │
│  3. NODE-GYP / NATIVE MODULES                                   │
│     └── node-gyp compiles native code during npm install        │
│     └── Build scripts run with full system access               │
│     └── Can download and execute arbitrary binaries             │
│                                                                 │
│  4. CI/CD SHARED ENVIRONMENT                                    │
│     └── Same CI runner for Rust/Go AND npm projects             │
│     └── Shared credentials and secrets                          │
│     └── Cargo/Go credentials exposed to npm scripts             │
│                                                                 │
│  5. SIGNING KEYS                                                │
│     └── Code signing keys in CI environment                     │
│     └── npm malware can steal signing credentials               │
│     └── Signed malware = trusted malware                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Affected Tooling

| Tool                  | Risk       | npm Exposure                |
| --------------------- | ---------- | --------------------------- |
| **Tauri**             | 🔴 Critical | Full frontend npm ecosystem |
| **wasm-pack**         | 🟠 High     | npm publish, JS bindings    |
| **wasm-bindgen**      | 🟠 High     | JS glue code generation     |
| **node-gyp**          | 🔴 Critical | Native compilation          |
| **napi-rs**           | 🟠 High     | Node.js native modules      |
| **electron-builder**  | 🔴 Critical | If migrating from Electron  |
| **trunk** (Rust WASM) | 🟡 Medium   | Asset pipeline              |

## 🔍 Detection

### Check Your Tauri Project

```bash
# Check frontend dependencies
cd src-tauri/../  # or wherever your frontend is
grep -E "(posthog|@postman|@asyncapi|@zapier)" package-lock.json

# Check for IOC files
find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Check if npm scripts ran during build
grep -r "preinstall\|postinstall" package.json
```

### Check WASM Projects

```bash
# Check for npm dependencies in wasm-pack output
ls -la pkg/*.js pkg/package.json 2>/dev/null

# Check wasm-bindgen generated files
find . -name "*.js" -path "*/pkg/*" -exec grep -l "posthog\|@postman" {} \;
```

### Check CI Environment

```bash
# List all credential files that could be exposed
ls -la ~/.cargo/credentials* 2>/dev/null
ls -la ~/.config/gh/hosts.yml 2>/dev/null
ls -la ~/.npmrc 2>/dev/null

# Check for shared secrets in environment
env | grep -iE "(token|key|secret|password)" | head -5
```

## 🛡️ Hardening

### 1. Tauri Build Isolation

**`tauri.conf.json`** security settings:

```json
{
  "build": {
    "beforeBuildCommand": "npm install --ignore-scripts && npm run build",
    "beforeDevCommand": "npm install --ignore-scripts && npm run dev"
  },
  "tauri": {
    "security": {
      "csp": "default-src 'self'; script-src 'self'",
      "dangerousDisableAssetCspModification": false
    },
    "bundle": {
      "active": true,
      "targets": "all"
    }
  }
}
```

### 2. Separate CI Jobs

```yaml
# .github/workflows/build.yml
name: Build

jobs:
  # Frontend build - isolated
  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install frontend deps (SECURE)
        working-directory: ./frontend
        run: |
          npm install --ignore-scripts

          # Security check
          if find node_modules -name "setup_bun.js" 2>/dev/null | grep -q .; then
            echo "🚨 IOC detected!"
            exit 1
          fi

      - name: Build frontend
        run: npm run build

      - name: Upload frontend artifacts
        uses: actions/upload-artifact@v4
        with:
          name: frontend-dist
          path: dist/

  # Rust build - separate job, no npm
  rust:
    runs-on: ubuntu-latest
    # No npm credentials here!
    steps:
      - uses: actions/checkout@v4

      - name: Setup Rust
        uses: dtolnay/rust-toolchain@stable

      - name: Build Rust
        run: cargo build --release

      - name: Upload Rust artifacts
        uses: actions/upload-artifact@v4
        with:
          name: rust-binary
          path: target/release/

  # Final assembly - uses artifacts, no npm install
  package:
    needs: [frontend, rust]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4

      - name: Package application
        run: |
          # Combine artifacts without running npm
          # ...
```

### 3. Protect Signing Keys

```yaml
# Signing job - maximum isolation
sign:
  needs: package
  runs-on: macos-latest  # Or dedicated signing runner
  environment: signing  # Requires approval
  steps:
    - name: Download unsigned binary
      uses: actions/download-artifact@v4

    # NO npm install here!
    # NO untrusted code execution!

    - name: Sign binary
      env:
        APPLE_CERTIFICATE: ${{ secrets.APPLE_CERTIFICATE }}
        APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
      run: |
        # Import certificate
        # Sign binary
        # Notarize
```

### 4. WASM Build Security

**`Cargo.toml`** for WASM projects:

```toml
[package]
name = "my-wasm-lib"
version = "0.1.0"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"

# Avoid npm-heavy dependencies
# Prefer pure Rust alternatives

[package.metadata.wasm-pack.profile.release]
# Don't include npm package.json if not needed
wasm-opt = ["-O4"]
```

**Build without npm publish:**

```bash
# Build WASM without npm packaging
wasm-pack build --target web --no-pack

# Or for bundlers
wasm-pack build --target bundler --no-pack
```

### 5. node-gyp Isolation

If you must use native Node.js modules:

```bash
# Build native modules in isolated container
docker run --rm -v $(pwd):/app -w /app node:20 \
  npm install --ignore-scripts

# Then run node-gyp separately with audit
docker run --rm -v $(pwd):/app -w /app node:20 \
  npx node-gyp rebuild
```

## 🔒 Credential Isolation

### Separate Credential Files

```bash
# Don't share credentials between ecosystems
# Rust/Cargo
~/.cargo/credentials.toml  # Cargo registry tokens

# Go
~/.netrc                   # Go module proxy auth

# npm (DANGER ZONE)
~/.npmrc                   # npm tokens - isolate this!

# In CI, use separate secrets
CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_TOKEN }}
NPM_TOKEN: ${{ secrets.NPM_TOKEN }}  # Different secret!
```

### Environment Isolation

```yaml
# Different environments for different ecosystems
jobs:
  rust-publish:
    environment: cargo-publish
    env:
      CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_TOKEN }}
      # NO NPM_TOKEN here!

  npm-publish:
    environment: npm-publish
    env:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      # NO CARGO_TOKEN here!
```

## 🚨 Tauri-Specific Concerns

### Frontend Dependency Audit

```bash
# Audit Tauri frontend
cd src-tauri/../
npm audit --audit-level=high

# Check for compromised packages
npx hulud scan .
```

### Tauri Updater Security

If using Tauri's auto-updater:

```json
{
  "tauri": {
    "updater": {
      "active": true,
      "endpoints": [
        "https://YOUR-DOMAIN.com/updates/{{target}}/{{current_version}}"
      ],
      "pubkey": "YOUR_PUBLIC_KEY"
    }
  }
}
```

> ⚠️ **Critical**: If your signing key is stolen, attackers can push malicious updates!

### CSP for Tauri

```json
{
  "tauri": {
    "security": {
      "csp": {
        "default-src": "'self'",
        "script-src": "'self'",
        "style-src": "'self' 'unsafe-inline'",
        "connect-src": "'self' https://api.yourdomain.com",
        "img-src": "'self' data: https:"
      }
    }
  }
}
```

## 📚 Related Documentation

- [Main Detection Guide](../DETECTION.md)
- [Remediation Guide](../REMEDIATION.md)
- [Monorepo Security Guide](./MONOREPO.md)
- [Bun Security Guide](./BUN.md)

## 🔗 External Resources

- [Tauri Security](https://tauri.app/v1/guides/security/)
- [wasm-pack Documentation](https://rustwasm.github.io/wasm-pack/)
- [Cargo Security](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)
- [Go Module Security](https://go.dev/blog/module-mirror-launch)

---

> ⚠️ **Remember**: Your Rust/Go code may be secure, but if your build process touches npm, you inherit all of npm's risks. Isolate, verify, and never trust.
