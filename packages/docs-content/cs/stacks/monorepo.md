---
title: Monorepo Security Guide
description: "Shared dependencies = shared risk in Turborepo, Nx, pnpm workspaces"
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# 🏗️ Monorepo Security Guide

> **Sdílené závislosti = sdílené riziko!**

Monorepa používající Turborepo, Nx nebo pnpm workspaces mají zesílenou útočnou plochu, protože jediný kompromitovaný balíček může ovlivnit všechny projekty.

## ⚠️ Kritická rizika

### Proč jsou monorepa vysoce riziková

```
┌─────────────────────────────────────────────────────────────────┐
│  🏗️ MONOREPO-SPECIFICKÉ ÚTOČNÉ VEKTORY                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. SDÍLENÁ EXPOZICE TOKENŮ                                     │
│     └── Jeden npm/GitHub token použitý napříč všemi balíčky     │
│     └── Kompromitace jednoho = kompromitace všech               │
│     └── CI/CD secrets sdílené napříč workspace                  │
│                                                                 │
│  2. HOISTOVANÉ ZÁVISLOSTI                                       │
│     └── Škodlivý balíček hoistovaný do rootu ovlivní vše        │
│     └── Phantom dependencies mohou skrývat malware              │
│     └── Konflikty verzí mohou zavést zranitelné verze           │
│                                                                 │
│  3. TURBOREPO/NX CACHE                                          │
│     └── Cachované build outputy mohou obsahovat škodlivý kód    │
│     └── Remote cache může být otráven                           │
│     └── Task pipelines se spouští napříč všemi balíčky          │
│                                                                 │
│  4. WORKSPACE SCRIPTY                                           │
│     └── Root package.json scripty běží se zvýšeným přístupem    │
│     └── Lifecycle scripty se propagují do všech balíčků         │
│     └── Pre/post hooks mohou být uneseny                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Kompromitované balíčky v kontextu monorepa

| Balíček       | Riziko     | Dopad na monorepo            |
| ------------- | ---------- | ---------------------------- |
| `posthog-*`   | 🔴 Kritické | Analytics ve více aplikacích |
| `@postman/*`  | 🔴 Kritické | API tooling napříč službami  |
| `@asyncapi/*` | 🔴 Kritické | Schema validace všude        |
| `turbo`       | 🟠 Vysoké   | Build orchestrace            |
| `nx`          | 🟠 Vysoké   | Build orchestrace            |

## 🔍 Detekce

### Skenování celého workspace

```bash
# Kontrola všech lockfiles ve workspace
find . -name "package-lock.json" -o -name "pnpm-lock.yaml" -o -name "yarn.lock" | \
  xargs grep -l -E "(posthog|@postman|@asyncapi|@zapier)"

# Kontrola IOC souborů napříč všemi balíčky
find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Kontrola všech node_modules (včetně vnořených)
find . -path "*/node_modules/*" -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null

# Kontrola Turborepo cache
find .turbo -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null

# Kontrola Nx cache
find .nx -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null
```

### Audit workspace závislostí

```bash
# pnpm workspace audit
pnpm audit --recursive

# npm workspaces audit
npm audit --workspaces

# Seznam všech balíčků s verzemi
pnpm ls --recursive --depth=0
```

## 🛡️ Hardening

### 1. Bezpečný `pnpm-workspace.yaml`

```yaml
packages:
  - 'packages/*'
  - 'apps/*'
  # Vyloučit test fixtures
  - '!**/test-fixtures/**'
  - '!**/fixtures/**'
```

### 2. Bezpečný root `.npmrc`

```ini
# Zakázat lifecycle scripty globálně
ignore-scripts=true

# Striktní peer dependencies
strict-peer-dependencies=true

# Přesné verze
save-exact=true

# Hoist patterns - omezit co se hoistuje
public-hoist-pattern[]=*types*
public-hoist-pattern[]=*eslint*
public-hoist-pattern[]=*prettier*

# Zakázat shamefully-hoist pro bezpečnost
shamefully-hoist=false

# Side effects cache - zakázat pro bezpečnost
side-effects-cache=false
```

### 3. Bezpečný `turbo.json`

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

> ⚠️ **Důležité**: Povolte `signature: true` pro remote cache k prevenci cache poisoning!

### 4. Bezpečný `nx.json`

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

Vytvořte `.npmrc` v každém balíčku, který potřebuje scripty:

```ini
# packages/needs-scripts/.npmrc
# Povolit scripty pouze pro tento konkrétní balíček
ignore-scripts=false

# Ale stále auditovat
audit=true
```

## 🔒 CI/CD konfigurace

### GitHub Actions pro Monorepo

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
          # Kontrola IOC souborů
          if find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
            echo "🚨 Detekovány IOC soubory!"
            exit 1
          fi

          # Audit všech balíčků
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
# Používat remote cache pouze z důvěryhodných zdrojů
- name: Setup Turbo Remote Cache
  run: |
    # Ověřit podpis cache
    echo "TURBO_REMOTE_CACHE_SIGNATURE_KEY=${{ secrets.TURBO_SIGNATURE_KEY }}" >> $GITHUB_ENV
```

## 🚨 Strategie izolace tokenů

### Oddělené tokeny pro každý balíček

Místo jednoho npm tokenu pro všechny balíčky:

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
# Vytvořit scoped tokeny pro každý balíček
npm token create --read-only  # Pro CI buildy
npm token create --cidr=<IP>  # Omezit na CI IP adresy
```

## 🧹 Cache Hygiene

### Vyčištění potenciálně otrávených cache

```bash
# Vyčistit Turborepo cache
rm -rf .turbo
rm -rf node_modules/.cache/turbo

# Vyčistit Nx cache
rm -rf .nx
rm -rf node_modules/.cache/nx

# Vyčistit pnpm store
pnpm store prune

# Vyčistit všechny node_modules
find . -name "node_modules" -type d -prune -exec rm -rf {} +

# Reinstalovat čistě
pnpm install --frozen-lockfile --ignore-scripts
```

### Ověření integrity cache

```bash
# Kontrola Turbo cache na podezřelé soubory
find .turbo -name "*.js" -exec grep -l "eval\|Function\|Sha1-Hulud" {} \;

# Kontrola neočekávaných spustitelných souborů
find .turbo -type f -executable
```

## 📚 Související dokumentace

- [Hlavní detekční guide](../DETECTION.md)
- [Remediation guide](../REMEDIATION.md)
- [pnpm-workspace-secure.yaml](../../configs/pnpm-workspace-secure.yaml)
- [Bun Security Guide](./BUN.md)

## 🔗 Externí zdroje

- [Turborepo Security](https://turbo.build/repo/docs/core-concepts/remote-caching#artifact-integrity-and-authenticity-verification)
- [Nx Security](https://nx.dev/concepts/security)
- [pnpm Security](https://pnpm.io/cli/audit)

---

> ⚠️ **Pamatujte**: V monorepu jste pouze tak bezpeční jako váš nejméně bezpečný balíček. Auditujte vše, nevěřte ničemu.
