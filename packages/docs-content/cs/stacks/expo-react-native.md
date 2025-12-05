---
title: Expo & React Native Security
description: Mobile apps are NOT immune to npm supply chain attacks
sidebar:
  order: 2
lastUpdated: 2025-12-05
---

# 📱 Expo & React Native Security Guide

> **Mobilní aplikace NEJSOU imunní vůči npm supply chain útokům!**

React Native a Expo projekty jsou obzvláště zranitelné, protože kombinují rizika npm ekosystému s mobilně-specifickými útočnými vektory.

## ⚠️ Kritická rizika

### Kompromitované balíčky ovlivňující mobilní aplikace

| Balíček                | Riziko     | Dopad                                             |
| ---------------------- | ---------- | ------------------------------------------------- |
| `posthog-react-native` | 🔴 Kritické | Analytics SDK - běží při každém spuštění aplikace |
| `posthog-js`           | 🔴 Kritické | Často bundlován v React Native web buildech       |
| `@segment/*`           | 🟠 Vysoké   | Analytics - podobná útočná plocha                 |
| `react-native-*`       | 🟠 Vysoké   | Mnoho community balíčků postiženo                 |

### Proč je mobilní vývoj vysoce rizikový

```
┌─────────────────────────────────────────────────────────────────┐
│  📱 MOBILNĚ-SPECIFICKÉ ÚTOČNÉ VEKTORY                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. METRO BUNDLER                                               │
│     └── Běží během vývoje s plným přístupem k systému           │
│     └── Může spustit škodlivý kód během bundlování              │
│                                                                 │
│  2. EXPO CLI                                                    │
│     └── Má přístup k EAS credentials                            │
│     └── Může modifikovat buildy aplikací                        │
│                                                                 │
│  3. BUILD SERVERY                                               │
│     └── EAS Build spouští npm install s vašimi credentials      │
│     └── Kompromitovaný balíček = kompromitovaný build           │
│                                                                 │
│  4. ANALYTICS SDK                                               │
│     └── Běží při KAŽDÉM spuštění aplikace                       │
│     └── Mají síťový přístup                                     │
│     └── Mohou exfiltrovat uživatelská data                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🔍 Detekce

### Kontrola vašeho projektu

```bash
# Kontrola kompromitovaných balíčků v lockfile
grep -E "(posthog|@postman|@asyncapi|@zapier)" package-lock.json
grep -E "(posthog|@postman|@asyncapi|@zapier)" yarn.lock
grep -E "(posthog|@postman|@asyncapi|@zapier)" pnpm-lock.yaml

# Kontrola IOC souborů
find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Kontrola node_modules na podezřelé soubory
find node_modules -name "*.js" -exec grep -l "Sha1-Hulud\|Second Coming" {} \; 2>/dev/null
```

### Kontrola Expo/EAS prostředí

```bash
# Kontrola EAS credentials (nesdílejte výstup!)
eas credentials:configure --platform ios
eas credentials:configure --platform android

# Kontrola neautorizovaných buildů
eas build:list --status=finished --limit=10

# Kontrola EAS secrets
eas secret:list
```

## 🛡️ Hardening

### 1. Uzamknutí `package.json`

```json
{
  "scripts": {
    "preinstall": "echo 'Scripts disabled for security'",
    "postinstall": "echo 'Scripts disabled for security'"
  }
}
```

### 2. Používejte `--ignore-scripts` VŽDY

```bash
# Lokální vývoj
npm install --ignore-scripts
# nebo
yarn install --ignore-scripts
# nebo
bun install --ignore-scripts  # POVINNÉ pro Bun!
```

### 3. Pinování Analytics SDK

Pokud používáte PostHog nebo podobné analytics:

```json
{
  "dependencies": {
    "posthog-react-native": "3.0.0"
  },
  "overrides": {
    "posthog-react-native": "3.0.0",
    "posthog-js": "1.96.0"
  }
}
```

> ⚠️ **Ověřte, že tyto verze jsou čisté** před pinováním! Zkontrolujte data proti 21. listopadu 2025.

### 4. Konfigurace `eas.json` pro bezpečnost

```json
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "production": {
      "env": {
        "NPM_CONFIG_IGNORE_SCRIPTS": "true"
      },
      "cache": {
        "disabled": true
      }
    },
    "preview": {
      "env": {
        "NPM_CONFIG_IGNORE_SCRIPTS": "true"
      }
    }
  }
}
```

### 5. Metro Bundler Security

Vytvořte nebo aktualizujte `metro.config.js`:

```javascript
const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Blokovat podezřelé file patterns
config.resolver.blockList = [
  /setup_bun\.js$/,
  /bun_environment\.js$/,
  /\.truffler-cache/,
];

// Logovat všechny resolved moduly (pro audit)
const originalResolveRequest = config.resolver.resolveRequest;
config.resolver.resolveRequest = (context, moduleName, platform) => {
  if (process.env.METRO_AUDIT === 'true') {
    console.log(`[METRO] Resolving: ${moduleName}`);
  }
  return originalResolveRequest(context, moduleName, platform);
};

module.exports = config;
```

## 🔒 CI/CD konfigurace

### GitHub Actions pro Expo

```yaml
name: Build Expo App

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

          # Kontrola IOC souborů
          if find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
            echo "🚨 IOC soubory detekovány v node_modules!"
            exit 1
          fi

      - name: Security audit
        run: npm audit --audit-level=high

      - name: Build with Expo
        run: npx expo export
        env:
          NPM_CONFIG_IGNORE_SCRIPTS: 'true'
```

### EAS Build Hooks

Vytvořte `eas-build-pre-install.sh`:

```bash
#!/bin/bash
# EAS Build pre-install hook

echo "🔒 Spouštím bezpečnostní kontroly..."

# Nastavit ignore-scripts
export NPM_CONFIG_IGNORE_SCRIPTS=true

# Po instalaci zkontrolovat IOCs
check_iocs() {
  if find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
    echo "🚨 BEZPEČNOSTNÍ ALERT: Detekovány IOC soubory!"
    echo "Build přerušen z bezpečnostních důvodů."
    exit 1
  fi
}

trap check_iocs EXIT
```

Reference v `eas.json`:

```json
{
  "build": {
    "production": {
      "preInstall": "./eas-build-pre-install.sh"
    }
  }
}
```

## 🚨 Pokud máte podezření na kompromitaci

### Okamžité akce

1. **Revokujte EAS credentials**:
   ```bash
   eas credentials:configure --platform ios --clear
   eas credentials:configure --platform android --clear
   ```

2. **Rotujte všechny secrets**:
   ```bash
   eas secret:delete --scope project --name <SECRET_NAME>
   # Znovu vytvořte s novými hodnotami
   ```

3. **Zkontrolujte neautorizované buildy**:
   ```bash
   eas build:list --status=finished
   # Hledejte buildy, které jste nespustili
   ```

4. **Revokujte app store credentials**:
   - Apple: Revokujte API klíče v App Store Connect
   - Google: Revokujte service account v Google Cloud Console

5. **Zkontrolujte publikované aplikace**:
   - Zkontrolujte nedávné aktualizace aplikací
   - Hledejte neautorizované verze

### Kroky obnovy

1. **Čistá instalace**:
   ```bash
   rm -rf node_modules
   rm -rf .expo
   rm package-lock.json  # nebo yarn.lock

   # Reinstalace s čistými verzemi
   npm install --ignore-scripts
   ```

2. **Audit závislostí**:
   ```bash
   npm audit
   npx socket-security scan
   ```

3. **Rebuild z čistého stavu**:
   ```bash
   eas build --platform all --clear-cache
   ```

## 📚 Související dokumentace

- [Hlavní detekční guide](../DETECTION.md)
- [Remediation guide](../REMEDIATION.md)
- [Bun Security Guide](./BUN.md)
- [Přehled hrozby](../THREAT-OVERVIEW.md)

## 🔗 Externí zdroje

- [Expo Security Best Practices](https://docs.expo.dev/guides/security/)
- [React Native Security](https://reactnative.dev/docs/security)
- [EAS Build Documentation](https://docs.expo.dev/build/introduction/)
- [PostHog Incident Response](https://posthog.com/blog/security-incident-nov-2025) (pokud dostupné)

---

> ⚠️ **Pamatujte**: Bezpečnost vaší mobilní aplikace je pouze tak silná jako vaše nejslabší npm závislost. Zacházejte s každým `npm install` jako s potenciálním útočným vektorem.
