---
title: TypeScript & Astro Security
description: Build pipelines are prime targets for supply chain attacks
sidebar:
  order: 4
lastUpdated: 2025-12-05
---

# 🚀 TypeScript & Astro Security Guide

> **Build pipelines are prime targets for supply chain attacks!**

Astro, Vite, and TypeScript projects have unique attack surfaces due to their build-time code execution and plugin ecosystems.

## ⚠️ Critical Risks

### Compromised Packages Affecting Astro/Vite

| Package                           | Risk       | Impact                    |
| --------------------------------- | ---------- | ------------------------- |
| `@asyncapi/specs`                 | 🔴 Critical | OpenAPI/AsyncAPI tooling  |
| `@asyncapi/openapi-schema-parser` | 🔴 Critical | Schema parsing            |
| `@asyncapi/*`                     | 🔴 Critical | Multiple packages         |
| Vite plugins                      | 🟠 High     | Build-time code execution |
| PostCSS plugins                   | 🟠 High     | CSS processing            |
| Rollup plugins                    | 🟠 High     | Bundle manipulation       |

### Why Build Tools Are High-Risk

```
┌─────────────────────────────────────────────────────────────────┐
│  🔧 BUILD-TIME ATTACK VECTORS                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. VITE DEV SERVER                                             │
│     └── Runs with full system access                            │
│     └── Hot Module Replacement can execute arbitrary code       │
│     └── Plugins run during every file change                    │
│                                                                 │
│  2. ASTRO BUILD                                                 │
│     └── SSR/SSG executes code at build time                     │
│     └── Integrations have full Node.js access                   │
│     └── Content collections can run arbitrary transforms        │
│                                                                 │
│  3. TYPESCRIPT COMPILER                                         │
│     └── tsconfig plugins can execute code                       │
│     └── Type checking runs on every save                        │
│     └── ts-node/tsx execute TS directly                         │
│                                                                 │
│  4. POSTCSS/TAILWIND                                            │
│     └── PostCSS plugins run on every CSS change                 │
│     └── Tailwind config is executed JavaScript                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🔍 Detection

### Check Your Project

```bash
# Check for compromised packages
grep -E "(@asyncapi|posthog|@postman|@zapier)" package-lock.json
grep -E "(@asyncapi|posthog|@postman|@zapier)" pnpm-lock.yaml

# Check for IOC files in node_modules
find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Check Vite cache for suspicious files
find node_modules/.vite -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null

# Check Astro cache
find .astro -name "*.js" -exec grep -l "Sha1-Hulud" {} \; 2>/dev/null
```

### Audit Vite Plugins

```bash
# List all Vite plugins in your config
grep -E "vite-plugin|@vitejs" package.json

# Check plugin sources
npm ls | grep -E "vite-plugin"
```

## 🛡️ Hardening

### 1. Secure `vite.config.ts`

```typescript
import { defineConfig } from 'vite';

export default defineConfig({
  // Disable automatic dependency optimization in CI
  optimizeDeps: {
    // Only include known-safe dependencies
    include: ['react', 'react-dom'],
    // Exclude suspicious packages
    exclude: ['@asyncapi/*', 'posthog-*'],
  },

  // Restrict server access
  server: {
    // Don't expose to network by default
    host: '127.0.0.1',
    // Disable opening browser automatically
    open: false,
    // Strict CORS
    cors: false,
  },

  // Build security
  build: {
    // Generate source maps only in development
    sourcemap: process.env.NODE_ENV !== 'production',
    // Don't minify in CI for easier auditing
    minify: process.env.CI ? false : 'esbuild',
  },

  // Log all plugin activity
  plugins: [
    {
      name: 'security-audit',
      configResolved(config) {
        console.log('[SECURITY] Loaded plugins:', config.plugins.map(p => p.name));
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

### 2. Secure `astro.config.mjs`

```javascript
import { defineConfig } from 'astro/config';

export default defineConfig({
  // Disable telemetry
  telemetry: false,

  // Restrict integrations
  integrations: [
    // Only use verified integrations
  ],

  // Build security
  build: {
    // Inline small assets to reduce external requests
    inlineStylesheets: 'auto',
  },

  // Vite configuration
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

### 3. Secure `tsconfig.json`

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

> ⚠️ **Warning**: Avoid TypeScript plugins from untrusted sources. They execute during type checking!

### 4. Secure `postcss.config.js`

```javascript
module.exports = {
  plugins: {
    // Only use well-known, audited plugins
    tailwindcss: {},
    autoprefixer: {},
    // Avoid: random PostCSS plugins from npm
  },
};
```

### 5. Lock Down `tailwind.config.js`

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
    // Don't include node_modules!
  ],
  theme: {
    extend: {},
  },
  plugins: [
    // Only use official Tailwind plugins
    // require('@tailwindcss/forms'),
    // require('@tailwindcss/typography'),
  ],
};
```

## 🔒 CI/CD Configuration

### GitHub Actions for Astro

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

          # Security check
          if find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
            echo "🚨 IOC files detected!"
            exit 1
          fi

      - name: Security audit
        run: npm audit --audit-level=high

      - name: Build
        run: npm run build
        env:
          NODE_ENV: production
          # Disable telemetry
          ASTRO_TELEMETRY_DISABLED: '1'

      - name: Verify build output
        run: |
          # Check dist for suspicious patterns
          if grep -r "Sha1-Hulud\|Second Coming" dist/ 2>/dev/null; then
            echo "🚨 Suspicious patterns in build output!"
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

## 🚨 @asyncapi/* Impact

The `@asyncapi/*` packages were compromised in the Shai-Hulud 2.0 attack. If you use AsyncAPI:

### Check Your Usage

```bash
# Find all @asyncapi packages
npm ls | grep @asyncapi

# Check versions
npm ls @asyncapi/specs @asyncapi/openapi-schema-parser
```

### Safe Versions

Pin to versions **before November 21, 2025**:

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

> ⚠️ Verify these versions are actually clean before using!

## 📚 Related Documentation

- [Main Detection Guide](../DETECTION.md)
- [Remediation Guide](../REMEDIATION.md)
- [Bun Security Guide](./BUN.md)
- [Monorepo Security Guide](./MONOREPO.md)

## 🔗 External Resources

- [Astro Security](https://docs.astro.build/en/guides/security/)
- [Vite Security Considerations](https://vitejs.dev/guide/security.html)
- [TypeScript Security](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html)

---

> ⚠️ **Remember**: Every build tool plugin is code that runs with your permissions. Audit your `vite.config.ts`, `astro.config.mjs`, and `postcss.config.js` regularly.
