---
title: npm Security Configuration
description: Harden your npm configuration against supply chain attacks
sidebar:
  order: 5
  badge:
    text: Essential
    variant: tip
lastUpdated: 2025-12-05
---

# npm Security Configuration

> Essential npm settings to protect against supply chain attacks

## Quick Hardening

```bash
# Run our hardening script
npx hulud harden

# Or manually:
npm config set ignore-scripts true
npm config set audit true
npm config set fund false
```

## .npmrc Configuration

Create or update `~/.npmrc`:

```ini
# Disable lifecycle scripts (CRITICAL!)
ignore-scripts=true

# Enable security features
audit=true
audit-level=moderate

# Disable telemetry
fund=false
update-notifier=false

# Use lockfile
package-lock=true
save-exact=true

# Registry security (optional: use private registry)
# registry=https://your-private-registry.com
```

## Project-Level .npmrc

Create `.npmrc` in your project root:

```ini
# Inherit from user config
# Add project-specific settings

# Strict engine checking
engine-strict=true

# Exact versions only
save-exact=true

# Lockfile required
package-lock=true
```

## Token Security

### Rotate Tokens Regularly

```bash
# List current tokens
npm token list

# Revoke old tokens
npm token revoke <token-id>

# Create new token with limited scope
npm token create --read-only --cidr=<your-ci-ip>/32
```

### Use Fine-Grained Tokens

1. Go to https://www.npmjs.com/settings/~/tokens
2. Create "Granular Access Token"
3. Set:
   - **Expiration**: 30-90 days
   - **Packages**: Only packages you need
   - **Permissions**: Read-only for CI
   - **IP Allowlist**: Your CI IP ranges

## 2FA Configuration

```bash
# Enable 2FA for all operations
npm profile enable-2fa auth-and-writes

# Check 2FA status
npm profile get
```

## Audit Commands

```bash
# Check for vulnerabilities
npm audit

# Fix automatically (use with caution)
npm audit fix

# Generate report
npm audit --json > audit-report.json
```

## Package Publishing Security

```bash
# Check what will be published
npm pack --dry-run

# Verify package contents
npm publish --dry-run

# Use provenance (npm 9.5+)
npm publish --provenance
```

## Recommended Tools

| Tool       | Purpose                           |
| ---------- | --------------------------------- |
| Socket.dev | Real-time supply chain monitoring |
| Snyk       | Vulnerability scanning            |
| npm audit  | Built-in vulnerability check      |
| Renovate   | Automated dependency updates      |
