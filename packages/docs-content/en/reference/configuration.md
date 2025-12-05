---
title: Configuration Reference
description: Configuration options for security hardening
sidebar:
  order: 4
lastUpdated: 2025-12-05
---

# Configuration Reference

> Security configuration templates and options

## Available Configurations

The toolkit provides pre-configured security templates in `packages/configs/`:

| File                     | Purpose                    |
| ------------------------ | -------------------------- |
| `.npmrc-secure`          | Hardened npm configuration |
| `bunfig-secure.toml`     | Hardened Bun configuration |
| `renovate-defense.json`  | Anti-worm Renovate config  |
| `renovate-hardened.json` | Strict Renovate config     |
| `socket.yml`             | Socket.dev configuration   |

## npm Configuration

### `.npmrc-secure`

```ini
# Disable lifecycle scripts (CRITICAL!)
ignore-scripts=true

# Security settings
audit=true
audit-level=moderate

# Disable telemetry
fund=false
update-notifier=false

# Lockfile settings
package-lock=true
save-exact=true
```

### Usage

```bash
# Copy to home directory
cp packages/configs/.npmrc-secure ~/.npmrc

# Or use our script
npx hulud harden
```

## Bun Configuration

### `bunfig-secure.toml`

```toml
[install]
# Disable lifecycle scripts
lifecycle = false

# Use lockfile
frozen = true

# Security
audit = true
```

### Usage

```bash
cp packages/configs/bunfig-secure.toml ~/bunfig.toml
```

## Renovate Configuration

### `renovate-defense.json`

Anti-worm configuration that:
- Pins all dependencies to exact versions
- Requires manual approval for updates
- Blocks known malicious packages
- Enables security-only updates

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "rangeStrategy": "pin",
  "automerge": false,
  "prCreation": "immediate",
  "vulnerabilityAlerts": {
    "enabled": true
  }
}
```

### Usage

```bash
cp packages/configs/renovate-defense.json renovate.json
```

## Socket.dev Configuration

### `socket.yml`

```yaml
version: 2
projectIgnorePaths:
  - "node_modules/**"
  - ".git/**"

issueRules:
  criticalCVE:
    action: error
  highCVE:
    action: warn
  installScripts:
    action: error
  networkAccess:
    action: warn
```

### Usage

```bash
cp packages/configs/socket.yml socket.yml
```

## Environment Variables

| Variable                    | Default    | Description         |
| --------------------------- | ---------- | ------------------- |
| `NPM_CONFIG_IGNORE_SCRIPTS` | `false`    | Disable npm scripts |
| `NPM_CONFIG_AUDIT`          | `true`     | Enable npm audit    |
| `HULUD_IOC_URL`             | (built-in) | Custom IOC database |

## CI/CD Integration

### GitHub Actions

```yaml
- name: Setup secure npm
  run: |
    npm config set ignore-scripts true
    npm config set audit true
```

### GitLab CI

```yaml
before_script:
  - npm config set ignore-scripts true
  - npm ci --ignore-scripts
```
