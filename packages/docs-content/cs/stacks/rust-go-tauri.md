---
title: Rust, Go & Tauri Security
description: Cross-language projects share npm risks through build tooling
sidebar:
  order: 5
lastUpdated: 2025-12-05
---

# 🦀 Rust, Go & Tauri Security Guide

> **Cross-language projekty sdílejí npm rizika přes build tooling!**

I když je vaše hlavní aplikace napsaná v Rustu, Go nebo používá Tauri, stále jste vystaveni npm supply chain útokům přes build nástroje, WASM kompilaci a hybridní architektury.

## ⚠️ Kritická rizika

### Jak npm ovlivňuje non-JS projekty

```
┌─────────────────────────────────────────────────────────────────┐
│  🔗 CROSS-LANGUAGE ÚTOČNÉ VEKTORY                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. TAURI FRONTEND                                              │
│     └── Tauri aplikace mají web frontend (React, Vue, Svelte)   │
│     └── npm install běží během buildu                           │
│     └── Kompromitovaný balíček = kompromitovaná desktop app     │
│                                                                 │
│  2. WASM TOOLING                                                │
│     └── wasm-pack, wasm-bindgen používají npm pro JS glue       │
│     └── Build scripty mohou spouštět škodlivý kód               │
│     └── Publikované WASM balíčky mohou obsahovat npm deps       │
│                                                                 │
│  3. NODE-GYP / NATIVE MODULES                                   │
│     └── node-gyp kompiluje nativní kód během npm install        │
│     └── Build scripty běží s plným přístupem k systému          │
│     └── Může stahovat a spouštět libovolné binárky              │
│                                                                 │
│  4. CI/CD SDÍLENÉ PROSTŘEDÍ                                     │
│     └── Stejný CI runner pro Rust/Go A npm projekty             │
│     └── Sdílené credentials a secrets                           │
│     └── Cargo/Go credentials vystaveny npm scriptům             │
│                                                                 │
│  5. SIGNING KEYS                                                │
│     └── Code signing klíče v CI prostředí                       │
│     └── npm malware může ukrást signing credentials             │
│     └── Podepsaný malware = důvěryhodný malware                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Ovlivněné nástroje

| Nástroj               | Riziko     | npm Expozice                |
| --------------------- | ---------- | --------------------------- |
| **Tauri**             | 🔴 Kritické | Celý frontend npm ekosystém |
| **wasm-pack**         | 🟠 Vysoké   | npm publish, JS bindings    |
| **wasm-bindgen**      | 🟠 Vysoké   | JS glue code generování     |
| **node-gyp**          | 🔴 Kritické | Nativní kompilace           |
| **napi-rs**           | 🟠 Vysoké   | Node.js nativní moduly      |
| **electron-builder**  | 🔴 Kritické | Při migraci z Electronu     |
| **trunk** (Rust WASM) | 🟡 Střední  | Asset pipeline              |

## 🔍 Detekce

### Kontrola vašeho Tauri projektu

```bash
# Kontrola frontend závislostí
cd src-tauri/../  # nebo kde je váš frontend
grep -E "(posthog|@postman|@asyncapi|@zapier)" package-lock.json

# Kontrola IOC souborů
find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Kontrola zda npm scripty běžely během buildu
grep -r "preinstall\|postinstall" package.json
```

### Kontrola WASM projektů

```bash
# Kontrola npm závislostí ve wasm-pack outputu
ls -la pkg/*.js pkg/package.json 2>/dev/null

# Kontrola wasm-bindgen generovaných souborů
find . -name "*.js" -path "*/pkg/*" -exec grep -l "posthog\|@postman" {} \;
```

### Kontrola CI prostředí

```bash
# Seznam všech credential souborů které mohou být vystaveny
ls -la ~/.cargo/credentials* 2>/dev/null
ls -la ~/.config/gh/hosts.yml 2>/dev/null
ls -la ~/.npmrc 2>/dev/null

# Kontrola sdílených secrets v environment
env | grep -iE "(token|key|secret|password)" | head -5
```

## 🛡️ Hardening

### 1. Tauri Build Isolation

**`tauri.conf.json`** bezpečnostní nastavení:

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

### 2. Oddělené CI Jobs

```yaml
# .github/workflows/build.yml
name: Build

jobs:
  # Frontend build - izolovaný
  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install frontend deps (SECURE)
        working-directory: ./frontend
        run: |
          npm install --ignore-scripts

          # Bezpečnostní kontrola
          if find node_modules -name "setup_bun.js" 2>/dev/null | grep -q .; then
            echo "🚨 IOC detekován!"
            exit 1
          fi

      - name: Build frontend
        run: npm run build

      - name: Upload frontend artifacts
        uses: actions/upload-artifact@v4
        with:
          name: frontend-dist
          path: dist/

  # Rust build - oddělený job, bez npm
  rust:
    runs-on: ubuntu-latest
    # Žádné npm credentials zde!
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

  # Finální sestavení - používá artifacts, žádný npm install
  package:
    needs: [frontend, rust]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4

      - name: Package application
        run: |
          # Kombinace artifacts bez spouštění npm
          # ...
```

### 3. Ochrana Signing Keys

```yaml
# Signing job - maximální izolace
sign:
  needs: package
  runs-on: macos-latest  # Nebo dedikovaný signing runner
  environment: signing  # Vyžaduje schválení
  steps:
    - name: Download unsigned binary
      uses: actions/download-artifact@v4

    # ŽÁDNÝ npm install zde!
    # ŽÁDNÉ spouštění nedůvěryhodného kódu!

    - name: Sign binary
      env:
        APPLE_CERTIFICATE: ${{ secrets.APPLE_CERTIFICATE }}
        APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
      run: |
        # Import certifikátu
        # Podepsání binárky
        # Notarizace
```

### 4. WASM Build Security

**`Cargo.toml`** pro WASM projekty:

```toml
[package]
name = "my-wasm-lib"
version = "0.1.0"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"

# Vyhýbat se npm-heavy závislostem
# Preferovat čisté Rust alternativy

[package.metadata.wasm-pack.profile.release]
# Nezahrnovat npm package.json pokud není potřeba
wasm-opt = ["-O4"]
```

**Build bez npm publish:**

```bash
# Build WASM bez npm packaging
wasm-pack build --target web --no-pack

# Nebo pro bundlery
wasm-pack build --target bundler --no-pack
```

### 5. node-gyp Isolation

Pokud musíte používat nativní Node.js moduly:

```bash
# Build nativních modulů v izolovaném kontejneru
docker run --rm -v $(pwd):/app -w /app node:20 \
  npm install --ignore-scripts

# Pak spustit node-gyp odděleně s auditem
docker run --rm -v $(pwd):/app -w /app node:20 \
  npx node-gyp rebuild
```

## 🔒 Izolace Credentials

### Oddělené Credential soubory

```bash
# Nesdílet credentials mezi ekosystémy
# Rust/Cargo
~/.cargo/credentials.toml  # Cargo registry tokeny

# Go
~/.netrc                   # Go module proxy auth

# npm (DANGER ZONE)
~/.npmrc                   # npm tokeny - izolovat!

# V CI používat oddělené secrets
CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_TOKEN }}
NPM_TOKEN: ${{ secrets.NPM_TOKEN }}  # Jiný secret!
```

### Environment Isolation

```yaml
# Různá prostředí pro různé ekosystémy
jobs:
  rust-publish:
    environment: cargo-publish
    env:
      CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_TOKEN }}
      # ŽÁDNÝ NPM_TOKEN zde!

  npm-publish:
    environment: npm-publish
    env:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      # ŽÁDNÝ CARGO_TOKEN zde!
```

## 🚨 Tauri-Specifické obavy

### Frontend Dependency Audit

```bash
# Audit Tauri frontendu
cd src-tauri/../
npm audit --audit-level=high

# Kontrola kompromitovaných balíčků
npx hulud scan .
```

### Tauri Updater Security

Pokud používáte Tauri auto-updater:

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

> ⚠️ **Kritické**: Pokud je váš signing klíč ukraden, útočníci mohou pushovat škodlivé aktualizace!

### CSP pro Tauri

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

## 📚 Související dokumentace

- [Hlavní detekční guide](../DETECTION.md)
- [Remediation guide](../REMEDIATION.md)
- [Monorepo Security Guide](./MONOREPO.md)
- [Bun Security Guide](./BUN.md)

## 🔗 Externí zdroje

- [Tauri Security](https://tauri.app/v1/guides/security/)
- [wasm-pack Documentation](https://rustwasm.github.io/wasm-pack/)
- [Cargo Security](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)
- [Go Module Security](https://go.dev/blog/module-mirror-launch)

---

> ⚠️ **Pamatujte**: Váš Rust/Go kód může být bezpečný, ale pokud váš build proces dotýká npm, zdědíte všechna rizika npm. Izolujte, ověřujte a nikdy nevěřte.
