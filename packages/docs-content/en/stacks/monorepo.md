---
title: Monorepo Security Guide
description: "Shared dependencies = shared risk in Turborepo, Nx, pnpm workspaces"
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# 🏗️ Monorepo Security Guide

> **Shared dependencies = shared risk!**

Monorepos using Turborepo, Nx, or pnpm workspaces have amplified attack surfaces because a single compromised package can affect all projects.

## ⚠️ Critical Risks

### Why Monorepos Are High-Risk

```
┌─────────────────────────────────────────────────────────────────┐
│  🏗️ MONOREPO-SPECIFIC ATTACK VECTORS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. SHARED TOKEN EXPOSURE                                       │
│     └── Single npm/GitHub token used across all packages        │
│     └── Compromise of one = compromise of all                   │
│     └── CI/CD secrets shared across workspace                   │
│                                                                 │
│  2. HOISTED DEPENDENCIES                                        │
│     └── Malicious package hoisted to root affects everything    │
│     └── Phantom dependencies can hide malware                   │
│     └── Version conflicts can introduce vulnerable versions     │
│                                                                 │
│  3. TURBOREPO/NX CACHE                                          │
│     └── Cached build outputs can contain malicious code         │
│     └── Remote cache can be poisoned                            │
│     └── Task pipelines execute across all packages              │
│                                                                 │
│  4. WORKSPACE SCRIPTS                                           │
│     └── Root package.json scripts run with elevated access      │
│     └── Lifecycle scripts propagate to all packages             │
│     └── Pre/post hooks can be hijacked                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Compromised Packages in Monorepo Context

| Package       | Risk       | Monorepo Impact              |
| ------------- | ---------- | ---------------------------- |
| `posthog-*`   | 🔴 Critical | Analytics in multiple apps   |
| `@postman/*`  | 🔴 Critical | API tooling across services  |
| `@asyncapi/*` | 🔴 Critical | Schema validation everywhere |
| `turbo`       | 🟠 High     | Build orchestration          |
| `nx`          | 🟠 High     | Build orchestration          |

## 🔍 Detection

### Scan Entire Workspace

```bash
# Check all lockfiles in workspace
find . -name "package-lock.json" -o -name "pnpm-lock.yaml" -o -name "yarn.lock" | \
  xargs grep -l -E "(posthog|@postman|@asyncapi|@zapier)"

# Check for IOC files across all packages
find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Check all node_modules (including nested)
find . -path "*/node_modules/*" -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null

# Check Turborepo cache
find .turbo -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null

# Check Nx cache
find .nx -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null
```

### Audit Workspace Dependencies

```bash
# pnpm workspace audit
pnpm audit --recursive

# npm workspaces audit
npm audit --workspaces

# List all packages with versions
pnpm ls --recursive --depth=0
```

## 🛡️ Hardening

### 1. Secure `pnpm-workspace.yaml`

```yaml
packages:
  - 'packages/*'
  - 'apps/*'
  # Exclude test fixtures
  - '!**/test-fixtures/**'
  - '!**/fixtures/**'
```

### 2. Secure Root `.npmrc`

```ini
# Disable lifecycle scripts globally
ignore-scripts=true

# Strict peer dependencies
strict-peer-dependencies=true

# Exact versions
save-exact=true

# Hoist patterns - limit what gets hoisted
public-hoist-pattern[]=*types*
public-hoist-pattern[]=*eslint*
public-hoist-pattern[]=*prettier*

# Disable shamefully-hoist for security
shamefully-hoist=false

# Side effects cache - disable for security
side-effects-cache=false
```

### 3. Secure `turbo.json`

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": [
    ".env"
  ],
  "globalEnv": [
    "NODE_ENV",
    "NPM_CONFIG_IGNORE_SCRIPTS"
  ],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"],
      "env": [
        "NPM_CONFIG_IGNORE_SCRIPTS"
      ]
    },
    "lint": {
      "outputs": []
    },
    "test": {
      "outputs": [],
      "env": [
        "CI"
      ]
    }
  },
  "remoteCache": {
    "signature": true
  }
}
```

> ⚠️ **Important**: Enable `signature: true` for remote cache to prevent cache poisoning!

### 4. Secure `nx.json`

```json
{
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "tasksRunnerOptions": {
    "default": {
      "runner": "nx/tasks-runners/default",
      "options": {
        "cacheableOperations": ["build", "lint", "test"],
        "parallel": 3
      }
    }
  },
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"]
    }
  },
  "namedInputs": {
    "production": [
      "default",
      "!{projectRoot}/**/*.spec.ts",
      "!{projectRoot}/test/**/*"
    ]
  }
}
```

### 5. Per-Package Security

Create `.npmrc` in each package that needs scripts:

```ini
# packages/needs-scripts/.npmrc
# Only enable scripts for this specific package
ignore-scripts=false

# But still audit
audit=true
```

## 🔒 CI/CD Configuration

### GitHub Actions for Monorepo

```yaml
name: Monorepo CI

on: [push, pull_request]

jobs:
  security-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Install dependencies (SECURE)
        run: |
          pnpm install --frozen-lockfile --ignore-scripts

      - name: Security scan
        run: |
          # Check for IOC files
          if find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
            echo "🚨 IOC files detected!"
            exit 1
          fi

          # Audit all packages
          pnpm audit --recursive

  build:
    needs: security-check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Install
        run: pnpm install --frozen-lockfile --ignore-scripts

      - name: Build with Turbo
        run: pnpm turbo build
        env:
          NPM_CONFIG_IGNORE_SCRIPTS: 'true'
          TURBO_TELEMETRY_DISABLED: '1'
```

### Turborepo Remote Cache Security

```yaml
# Only use remote cache from trusted sources
- name: Setup Turbo Remote Cache
  run: |
    # Verify cache signature
    echo "TURBO_REMOTE_CACHE_SIGNATURE_KEY=${{ secrets.TURBO_SIGNATURE_KEY }}" >> $GITHUB_ENV
```

## 🚨 Token Isolation Strategy

### Separate Tokens Per Package

Instead of one npm token for all packages:

```yaml
# .github/workflows/publish.yml
jobs:
  publish-package-a:
    env:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN_PACKAGE_A }}

  publish-package-b:
    env:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN_PACKAGE_B }}
```

### Scoped Token Permissions

```bash
# Create scoped tokens for each package
npm token create --read-only  # For CI builds
npm token create --cidr=<IP>  # Restrict to CI IPs
```

## 🧹 Cache Hygiene

### Clear Potentially Poisoned Caches

```bash
# Clear Turborepo cache
rm -rf .turbo
rm -rf node_modules/.cache/turbo

# Clear Nx cache
rm -rf .nx
rm -rf node_modules/.cache/nx

# Clear pnpm store
pnpm store prune

# Clear all node_modules
find . -name "node_modules" -type d -prune -exec rm -rf {} +

# Reinstall clean
pnpm install --frozen-lockfile --ignore-scripts
```

### Verify Cache Integrity

```bash
# Check Turbo cache for suspicious files
find .turbo -name "*.js" -exec grep -l "eval\|Function\|Sha1-Hulud" {} \;

# Check for unexpected executables
find .turbo -type f -executable
```

## 📚 Related Documentation

- [Main Detection Guide](../DETECTION.md)
- [Remediation Guide](../REMEDIATION.md)
- [pnpm-workspace-secure.yaml](../../configs/pnpm-workspace-secure.yaml)
- [Bun Security Guide](./BUN.md)

## 🔗 External Resources

- [Turborepo Security](https://turbo.build/repo/docs/core-concepts/remote-caching#artifact-integrity-and-authenticity-verification)
- [Nx Security](https://nx.dev/concepts/security)
- [pnpm Security](https://pnpm.io/cli/audit)

---

> ⚠️ **Remember**: In a monorepo, you're only as secure as your least secure package. Audit everything, trust nothing.
