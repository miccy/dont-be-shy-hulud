---
title: Expo & React Native Security
description: Mobile apps are NOT immune to npm supply chain attacks
sidebar:
  order: 2
lastUpdated: 2025-12-05
---

# 📱 Expo & React Native Security Guide

> **Mobile apps are NOT immune to npm supply chain attacks!**

React Native and Expo projects are particularly vulnerable because they combine npm ecosystem risks with mobile-specific attack surfaces.

## ⚠️ Critical Risks

### Compromised Packages Affecting Mobile

| Package                | Risk       | Impact                                   |
| ---------------------- | ---------- | ---------------------------------------- |
| `posthog-react-native` | 🔴 Critical | Analytics SDK - runs on every app launch |
| `posthog-js`           | 🔴 Critical | Often bundled in React Native web builds |
| `@segment/*`           | 🟠 High     | Analytics - similar attack surface       |
| `react-native-*`       | 🟠 High     | Many community packages affected         |

### Why Mobile is High-Risk

```
┌─────────────────────────────────────────────────────────────────┐
│  📱 MOBILE-SPECIFIC ATTACK VECTORS                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. METRO BUNDLER                                               │
│     └── Runs during development with full system access         │
│     └── Can execute malicious code during bundle                │
│                                                                 │
│  2. EXPO CLI                                                    │
│     └── Has access to EAS credentials                           │
│     └── Can modify app builds                                   │
│                                                                 │
│  3. BUILD SERVERS                                               │
│     └── EAS Build runs npm install with your credentials        │
│     └── Compromised package = compromised build                 │
│                                                                 │
│  4. ANALYTICS SDKS                                              │
│     └── Run on EVERY app launch                                 │
│     └── Have network access                                     │
│     └── Can exfiltrate user data                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🔍 Detection

### Check Your Project

```bash
# Check for compromised packages in your lockfile
grep -E "(posthog|@postman|@asyncapi|@zapier)" package-lock.json
grep -E "(posthog|@postman|@asyncapi|@zapier)" yarn.lock
grep -E "(posthog|@postman|@asyncapi|@zapier)" pnpm-lock.yaml

# Check for IOC files
find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Check node_modules for suspicious files
find node_modules -name "*.js" -exec grep -l "Sha1-Hulud\|Second Coming" {} \; 2>/dev/null
```

### Check Expo/EAS Environment

```bash
# Check EAS credentials (don't share output!)
eas credentials:configure --platform ios
eas credentials:configure --platform android

# Check for unauthorized builds
eas build:list --status=finished --limit=10

# Check EAS secrets
eas secret:list
```

## 🛡️ Hardening

### 1. Lock Down `package.json`

```json
{
  "scripts": {
    "preinstall": "echo 'Scripts disabled for security'",
    "postinstall": "echo 'Scripts disabled for security'"
  }
}
```

### 2. Use `--ignore-scripts` ALWAYS

```bash
# Local development
npm install --ignore-scripts
# or
yarn install --ignore-scripts
# or
bun install --ignore-scripts  # REQUIRED for Bun!
```

### 3. Pin Analytics SDKs

If you use PostHog or similar analytics:

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

> ⚠️ **Verify these versions are clean** before pinning! Check dates against Nov 21, 2025.

### 4. Configure `eas.json` for Security

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

Create or update `metro.config.js`:

```javascript
const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Block suspicious file patterns
config.resolver.blockList = [
  /setup_bun\.js$/,
  /bun_environment\.js$/,
  /\.truffler-cache/,
];

// Log all resolved modules (for auditing)
const originalResolveRequest = config.resolver.resolveRequest;
config.resolver.resolveRequest = (context, moduleName, platform) => {
  if (process.env.METRO_AUDIT === 'true') {
    console.log(`[METRO] Resolving: ${moduleName}`);
  }
  return originalResolveRequest(context, moduleName, platform);
};

module.exports = config;
```

## 🔒 CI/CD Configuration

### GitHub Actions for Expo

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

          # Check for IOC files
          if find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
            echo "🚨 IOC files detected in node_modules!"
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

Create `eas-build-pre-install.sh`:

```bash
#!/bin/bash
# EAS Build pre-install hook

echo "🔒 Running security checks..."

# Set ignore-scripts
export NPM_CONFIG_IGNORE_SCRIPTS=true

# After install, check for IOCs
check_iocs() {
  if find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
    echo "🚨 SECURITY ALERT: IOC files detected!"
    echo "Build aborted for security reasons."
    exit 1
  fi
}

trap check_iocs EXIT
```

Reference in `eas.json`:

```json
{
  "build": {
    "production": {
      "preInstall": "./eas-build-pre-install.sh"
    }
  }
}
```

## 🚨 If You Suspect Compromise

### Immediate Actions

1. **Revoke EAS credentials**:
   ```bash
   eas credentials:configure --platform ios --clear
   eas credentials:configure --platform android --clear
   ```

2. **Rotate all secrets**:
   ```bash
   eas secret:delete --scope project --name <SECRET_NAME>
   # Re-create with new values
   ```

3. **Check for unauthorized builds**:
   ```bash
   eas build:list --status=finished
   # Look for builds you didn't trigger
   ```

4. **Revoke app store credentials**:
   - Apple: Revoke API keys in App Store Connect
   - Google: Revoke service account in Google Cloud Console

5. **Check published apps**:
   - Review recent app updates
   - Check for unauthorized versions

### Recovery Steps

1. **Clean install**:
   ```bash
   rm -rf node_modules
   rm -rf .expo
   rm package-lock.json  # or yarn.lock

   # Reinstall with clean versions
   npm install --ignore-scripts
   ```

2. **Audit dependencies**:
   ```bash
   npm audit
   npx socket-security scan
   ```

3. **Rebuild from clean state**:
   ```bash
   eas build --platform all --clear-cache
   ```

## 📚 Related Documentation

- [Main Detection Guide](../DETECTION.md)
- [Remediation Guide](../REMEDIATION.md)
- [Bun Security Guide](./BUN.md)
- [Threat Overview](../THREAT-OVERVIEW.md)

## 🔗 External Resources

- [Expo Security Best Practices](https://docs.expo.dev/guides/security/)
- [React Native Security](https://reactnative.dev/docs/security)
- [EAS Build Documentation](https://docs.expo.dev/build/introduction/)
- [PostHog Incident Response](https://posthog.com/blog/security-incident-nov-2025) (if available)

---

> ⚠️ **Remember**: Your mobile app's security is only as strong as your weakest npm dependency. Treat every `npm install` as a potential attack vector.
