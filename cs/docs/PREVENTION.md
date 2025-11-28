# 🛡️ Prevention Guide

> Jak se chránit proti npm supply-chain útokům

## Úrovně ochrany

```
┌─────────────────────────────────────────────────────┐
│  Level 4: Monitoring & Response                     │
├─────────────────────────────────────────────────────┤
│  Level 3: CI/CD Hardening                           │
├─────────────────────────────────────────────────────┤
│  Level 2: Dependency Management                     │
├─────────────────────────────────────────────────────┤
│  Level 1: Authentication & Access Control           │
└─────────────────────────────────────────────────────┘
```

## Level 1: Authentication & Access Control

### npm Account Security

```bash
# 1. Povol 2FA (povinné pro publish)
npm profile enable-2fa auth-and-writes

# 2. Použij fine-grained tokens
# https://www.npmjs.com/settings/~/tokens
# Nastav:
# - Expiration: max 90 dní
# - Allowed IP ranges
# - Read-only pro CI (kde je to možné)

# 3. Zkontroluj access
npm access ls-packages
npm access ls-collaborators PACKAGE
```

### GitHub Account Security

1. **2FA** - https://github.com/settings/security
2. **Fine-grained PATs** místo classic tokens
3. **SSH keys** s passphrase
4. **Verified commits** - GPG signing

```bash
# Nastav GPG signing
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_KEY_ID
```

### Secrets Management

```bash
# NIKDY neukládej secrets v:
# - .env soubory v git
# - package.json
# - Environment variables v CI/CD (pokud není nutné)

# Použij secret managers:
# - 1Password CLI
# - HashiCorp Vault
# - AWS Secrets Manager
# - GitHub Actions secrets (encrypted)
```

## Level 2: Dependency Management

### Lockfile Strategy

```bash
# Vždy commituj lockfiles
# package-lock.json / bun.lockb / yarn.lock

# Používej --frozen-lockfile v CI
npm ci  # místo npm install
bun install --frozen-lockfile
```

### Version Pinning

```json
// package.json - DOPORUČENO
{
  "dependencies": {
    "lodash": "4.17.21"  // Exact version
  }
}

// NE toto:
{
  "dependencies": {
    "lodash": "^4.17.21",  // Allows minor updates
    "lodash": "~4.17.21",  // Allows patch updates
    "lodash": "*"          // NIKDY
  }
}
```

### Disable Lifecycle Scripts

```bash
# Globálně (pro development)
npm config set ignore-scripts true

# Per-project (.npmrc)
echo "ignore-scripts=true" >> .npmrc

# Pak manuálně spusť potřebné scripts
npm rebuild
npm run postinstall  # pokud je bezpečný
```

### Allowlist Strategy

```json
// package.json
{
  "bundleDependencies": true,
  "bundledDependencies": [
    "critical-package"
  ]
}
```

### Renovate Configuration

```json
// renovate.json - Hardened config
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  
  "automerge": false,
  "stabilityDays": 7,
  "prConcurrentLimit": 3,
  
  "packageRules": [
    {
      "matchManagers": ["npm", "bun"],
      "automerge": false,
      "labels": ["dependencies", "security-review"]
    },
    {
      "matchManagers": ["github-actions"],
      "pinDigests": true,
      "automerge": true
    }
  ],
  
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security", "critical"]
  }
}
```

## Level 3: CI/CD Hardening

### GitHub Actions Security

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read  # Minimální permissions

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
        # Pin to SHA, not tag
        # uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'
      
      # Disable scripts during install
      - run: npm ci --ignore-scripts
      
      # Run security scan
      - run: npm audit --audit-level=high
      
      # Socket.dev scan
      - uses: socket/socket-action@v1
        with:
          socket-token: ${{ secrets.SOCKET_TOKEN }}
```

### Restrict Workflow Permissions

```yaml
# Repository settings → Actions → General
# Workflow permissions: Read repository contents

# Nebo per-workflow:
permissions:
  contents: read
  packages: read
  # NE: write-all
```

### Network Restrictions

```yaml
# Omez outbound network
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: node:20
      options: --network=none  # No network after setup
    
    steps:
      - uses: actions/checkout@v4
      
      # Network enabled jen pro install
      - run: npm ci --ignore-scripts
        env:
          NETWORK: enabled
      
      # Zbytek bez sítě
      - run: npm test
      - run: npm run build
```

### Pull Request Reviews

```yaml
# .github/CODEOWNERS
# Vyžaduj review pro package files
package.json @security-team
package-lock.json @security-team
bun.lockb @security-team
.github/workflows/ @security-team
```

### Branch Protection

```
Settings → Branches → Branch protection rules (main):
✅ Require a pull request before merging
  ✅ Require approvals (2+)
  ✅ Dismiss stale reviews
  ✅ Require review from Code Owners
✅ Require status checks to pass
  ✅ security-scan
  ✅ socket-scan
✅ Require signed commits
✅ Do not allow bypassing
```

## Level 4: Monitoring & Response

### Socket.dev Integration

```yaml
# .socket.yml
version: 2

# Blokuj risky behaviors
block:
  - installScripts
  - shellAccess
  - networkAccess
  - envVars
  - fsAccess
  
warn:
  - newAuthor
  - criticalSeverity
  - highSeverity

issues:
  - severity: high
    action: error
```

### npm Audit Integration

```yaml
# GitHub Action pro pravidelný audit
name: Security Audit

on:
  schedule:
    - cron: '0 8 * * *'  # Denně v 8:00
  workflow_dispatch:

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - run: npm ci --ignore-scripts
      - run: npm audit --audit-level=high
      
      - name: Create issue on failure
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: '🚨 Security audit failed',
              body: 'npm audit found high/critical vulnerabilities',
              labels: ['security', 'critical']
            })
```

### Alerting

```bash
# Webhook pro npm publish events
# Nastav v npm organization settings

# Slack notification příklad
curl -X POST \
  -H 'Content-type: application/json' \
  --data '{"text":"🚨 New npm publish detected: package@version"}' \
  $SLACK_WEBHOOK_URL
```

### Log Analysis

```bash
# Sbírej a analyzuj:
# - npm install logy
# - CI/CD build logy
# - GitHub audit logy
# - Network traffic

# Příklad: GitHub audit log export
gh api /orgs/YOUR_ORG/audit-log --paginate > audit-log.json
```

## Nástroje

### Security Scanning

| Nástroj | Popis | Cena |
|---------|-------|------|
| [Socket.dev](https://socket.dev) | Supply-chain security | Free/Paid |
| [Snyk](https://snyk.io) | Vulnerability scanner | Free/Paid |
| [npm audit](https://docs.npmjs.com/cli/audit) | Built-in | Free |
| [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/) | Multi-language | Free |
| [Datadog SCFW](https://github.com/DataDog/supply-chain-firewall) | Firewall | Free (OSS) |

### Monitoring

| Nástroj | Popis |
|---------|-------|
| [Dependabot](https://docs.github.com/en/code-security/dependabot) | GitHub native |
| [Renovate](https://renovatebot.com) | Dependency updates |
| [WhiteSource Bolt](https://www.whitesourcesoftware.com/free-developer-tools/bolt) | Free scanning |

## Checklist

### Denní

- [ ] Zkontroluj security alerts
- [ ] Review pending PRs s dependency changes

### Týdenní

- [ ] `npm audit` / `socket scan` všech projektů
- [ ] Review GitHub audit log
- [ ] Zkontroluj expiraci tokenů

### Měsíční

- [ ] Rotace credentials (pokud máš policy)
- [ ] Review dependency tree
- [ ] Update security tools
- [ ] Review a cleanup npm access

### Po každém security incidentu

- [ ] Full credential rotation
- [ ] Audit všech projektů
- [ ] Update prevention measures
- [ ] Dokumentuj lessons learned

## Quick Wins

### Hned teď (5 minut)

```bash
# 1. Vypni auto-merge
# V Renovate/Dependabot config

# 2. Povol 2FA
npm profile enable-2fa auth-and-writes

# 3. Nastav ignore-scripts
npm config set ignore-scripts true
```

### Tento týden

1. Nastav Socket.dev nebo Snyk
2. Review všech npm tokens
3. Update Renovate config
4. Nastav branch protection

### Tento měsíc

1. Implementuj full CI/CD hardening
2. Nastav monitoring a alerting
3. Dokumentuj incident response proces
4. Školení pro tým
