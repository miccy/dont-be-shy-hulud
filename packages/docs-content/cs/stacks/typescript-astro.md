---
title: TypeScript & Astro Security
description: Build pipelines are prime targets for supply chain attacks
sidebar:
  order: 4
lastUpdated: 2025-12-05
---

# 🚀 TypeScript & Astro Security Guide

> **Build pipelines jsou hlavním cílem supply chain útoků!**

Astro, Vite a TypeScript projekty mají unikátní útočné plochy kvůli build-time spouštění kódu a plugin ekosystémům.

## ⚠️ Kritická rizika

### Kompromitované balíčky ovlivňující Astro/Vite

| Balíček                           | Riziko     | Dopad                     |
| --------------------------------- | ---------- | ------------------------- |
| `@asyncapi/specs`                 | 🔴 Kritické | OpenAPI/AsyncAPI tooling  |
| `@asyncapi/openapi-schema-parser` | 🔴 Kritické | Schema parsing            |
| `@asyncapi/*`                     | 🔴 Kritické | Více balíčků              |
| Vite pluginy                      | 🟠 Vysoké   | Build-time spouštění kódu |
| PostCSS pluginy                   | 🟠 Vysoké   | CSS processing            |
| Rollup pluginy                    | 🟠 Vysoké   | Bundle manipulace         |

### Proč jsou build nástroje vysoce rizikové

```
┌─────────────────────────────────────────────────────────────────┐
│  🔧 BUILD-TIME ÚTOČNÉ VEKTORY                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. VITE DEV SERVER                                             │
│     └── Běží s plným přístupem k systému                        │
│     └── Hot Module Replacement může spustit libovolný kód       │
│     └── Pluginy běží při každé změně souboru                    │
│                                                                 │
│  2. ASTRO BUILD                                                 │
│     └── SSR/SSG spouští kód při buildu                          │
│     └── Integrace mají plný Node.js přístup                     │
│     └── Content collections mohou spouštět transformace         │
│                                                                 │
│  3. TYPESCRIPT COMPILER                                         │
│     └── tsconfig pluginy mohou spouštět kód                     │
│     └── Type checking běží při každém uložení                   │
│     └── ts-node/tsx spouští TS přímo                            │
│                                                                 │
│  4. POSTCSS/TAILWIND                                            │
│     └── PostCSS pluginy běží při každé CSS změně                │
│     └── Tailwind config je spouštěný JavaScript                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🔍 Detekce

### Kontrola vašeho projektu

```bash
# Kontrola kompromitovaných balíčků
grep -E "(@asyncapi|posthog|@postman|@zapier)" package-lock.json
grep -E "(@asyncapi|posthog|@postman|@zapier)" pnpm-lock.yaml

# Kontrola IOC souborů v node_modules
find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Kontrola Vite cache na podezřelé soubory
find node_modules/.vite -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null

# Kontrola Astro cache
find .astro -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null
```

### Audit Vite pluginů

```bash
# Seznam všech Vite pluginů ve vašem configu
grep -E "vite-plugin|@vitejs" package.json

# Kontrola zdrojů pluginů
npm ls | grep -E "vite-plugin"
```

## 🛡️ Hardening

### 1. Bezpečný `vite.config.ts`

```typescript
import { defineConfig } from 'vite';

export default defineConfig({
  // Zakázat automatickou optimalizaci závislostí v CI
  optimizeDeps: {
    // Zahrnout pouze známé bezpečné závislosti
    include: ['react', 'react-dom'],
    // Vyloučit podezřelé balíčky
    exclude: ['@asyncapi/*', 'posthog-*'],
  },

  // Omezit přístup serveru
  server: {
    // Nevystavovat do sítě defaultně
    host: '127.0.0.1',
    // Zakázat automatické otevírání prohlížeče
    open: false,
    // Striktní CORS
    cors: false,
  },

  // Build security
  build: {
    // Generovat source maps pouze ve vývoji
    sourcemap: process.env.NODE_ENV !== 'production',
    // Neminifikovat v CI pro snazší audit
    minify: process.env.CI ? false : 'esbuild',
  },

  // Logovat veškerou aktivitu pluginů
  plugins: [
    {
      name: 'security-audit',
      configResolved(config) {
        console.log('[SECURITY] Načtené pluginy:', config.plugins.map(p => p.name));
      },
      resolveId(source) {
        if (process.env.VITE_AUDIT === 'true') {
          console.log(`[AUDIT] Resolving: ${source}`);
        }
      },
    },
  ],
});
```

### 2. Bezpečný `astro.config.mjs`

```javascript
import { defineConfig } from 'astro/config';

export default defineConfig({
  // Zakázat telemetrii
  telemetry: false,

  // Omezit integrace
  integrations: [
    // Používat pouze ověřené integrace
  ],

  // Build security
  build: {
    // Inline malé assety pro snížení externích požadavků
    inlineStylesheets: 'auto',
  },

  // Vite konfigurace
  vite: {
    optimizeDeps: {
      exclude: ['@asyncapi/*', 'posthog-*'],
    },
    server: {
      host: '127.0.0.1',
    },
  },
});
```

### 3. Bezpečný `tsconfig.json`

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "skipLibCheck": false,
    "plugins": []
  },
  "exclude": [
    "node_modules",
    ".astro",
    "dist"
  ]
}
```

> ⚠️ **Varování**: Vyhněte se TypeScript pluginům z nedůvěryhodných zdrojů. Spouští se během type checkingu!

### 4. Bezpečný `postcss.config.js`

```javascript
module.exports = {
  plugins: {
    // Používat pouze známé, auditované pluginy
    tailwindcss: {},
    autoprefixer: {},
    // Vyhýbat se: náhodným PostCSS pluginům z npm
  },
};
```

### 5. Uzamknutí `tailwind.config.js`

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
    // Nezahrnovat node_modules!
  ],
  theme: {
    extend: {},
  },
  plugins: [
    // Používat pouze oficiální Tailwind pluginy
    // require('@tailwindcss/forms'),
    // require('@tailwindcss/typography'),
  ],
};
```

## 🔒 CI/CD konfigurace

### GitHub Actions pro Astro

```yaml
name: Build Astro Site

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies (SECURE)
        run: |
          npm install --ignore-scripts

          # Bezpečnostní kontrola
          if find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
            echo "🚨 Detekovány IOC soubory!"
            exit 1
          fi

      - name: Security audit
        run: npm audit --audit-level=high

      - name: Build
        run: npm run build
        env:
          NODE_ENV: production
          # Zakázat telemetrii
          ASTRO_TELEMETRY_DISABLED: '1'

      - name: Verify build output
        run: |
          # Kontrola dist na podezřelé patterny
          if grep -r "Sha1-Hulud\|Second Coming" dist/ 2>/dev/null; then
            echo "🚨 Podezřelé patterny v build outputu!"
            exit 1
          fi
```

### Vercel/Netlify Security

```toml
# netlify.toml
[build]
  command = "npm install --ignore-scripts && npm run build"

[build.environment]
  NPM_CONFIG_IGNORE_SCRIPTS = "true"
  ASTRO_TELEMETRY_DISABLED = "1"
```

```json
// vercel.json
{
  "buildCommand": "npm install --ignore-scripts && npm run build",
  "env": {
    "NPM_CONFIG_IGNORE_SCRIPTS": "true"
  }
}
```

## 🚨 Dopad @asyncapi/*

Balíčky `@asyncapi/*` byly kompromitovány v útoku Shai-Hulud 2.0. Pokud používáte AsyncAPI:

### Kontrola vašeho použití

```bash
# Najít všechny @asyncapi balíčky
npm ls | grep @asyncapi

# Kontrola verzí
npm ls @asyncapi/specs @asyncapi/openapi-schema-parser
```

### Bezpečné verze

Pinujte na verze **před 21. listopadem 2025**:

```json
{
  "dependencies": {
    "@asyncapi/specs": "5.0.0",
    "@asyncapi/openapi-schema-parser": "3.0.0"
  },
  "overrides": {
    "@asyncapi/specs": "5.0.0",
    "@asyncapi/openapi-schema-parser": "3.0.0"
  }
}
```

> ⚠️ Ověřte, že tyto verze jsou skutečně čisté před použitím!

## 📚 Související dokumentace

- [Hlavní detekční guide](../DETECTION.md)
- [Remediation guide](../REMEDIATION.md)
- [Bun Security Guide](./BUN.md)
- [Monorepo Security Guide](./MONOREPO.md)

## 🔗 Externí zdroje

- [Astro Security](https://docs.astro.build/en/guides/security/)
- [Vite Security Considerations](https://vitejs.dev/guide/security.html)
- [TypeScript Security](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html)

---

> ⚠️ **Pamatujte**: Každý build tool plugin je kód, který běží s vašimi oprávněními. Pravidelně auditujte `vite.config.ts`, `astro.config.mjs` a `postcss.config.js`.
