# 🛡️ Prevention Guide

> How to protect against npm supply-chain attacks

## Protection Levels

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
# 1. Enable 2FA (required for publish)
npm profile enable-2fa auth-and-writes

# 2. Use fine-grained tokens
# https://www.npmjs.com/settings/~/tokens
# Set:
# - Expiration: max 90 days
# - Allowed IP ranges
# - Read-only for CI (where possible)

# 3. Check access
npm access ls-packages
npm access ls-collaborators PACKAGE
```

### GitHub Account Security

1. **2FA** - https://github.com/settings/security
2. **Fine-grained PATs** instead of classic tokens
3. **SSH keys** with passphrase
4. **Verified commits** - GPG signing

```bash
# Set up GPG signing
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_KEY_ID
```

### Secrets Management

```bash
# NEVER store secrets in:
# - .env files in git
# - package.json
# - Environment variables in CI/CD (unless necessary)

# Use secret managers:
# - 1Password CLI
# - HashiCorp Vault
# - AWS Secrets Manager
# - GitHub Actions secrets (encrypted)
```

## Level 2: Dependency Management

### Lockfile Strategy

```bash
# Always commit lockfiles
# package-lock.json / bun.lockb / yarn.lock

# Use --frozen-lockfile in CI
npm ci  # instead of npm install
bun install --frozen-lockfile
```

### Version Pinning

```json
// package.json - RECOMMENDED
{
  "dependencies": {
    "lodash": "4.17.21"  // Exact version
  }
}

// NOT this:
{
  "dependencies": {
    "lodash": "^4.17.21",  // Allows minor updates
    "lodash": "~4.17.21",  // Allows patch updates
    "lodash": "*"          // NEVER
  }
}
```

### Disable Lifecycle Scripts

```bash
# Globally (for development)
npm config set ignore-scripts true

# Per-project (.npmrc)
echo "ignore-scripts=true" >> .npmrc

# Then manually run needed scripts
npm rebuild
npm run postinstall  # if it's safe
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
  contents: read  # Minimal permissions

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

# Or per-workflow:
permissions:
  contents: read
  packages: read
  # NOT: write-all
```

### Network Restrictions

```yaml
# Limit outbound network
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: node:20
      options: --network=none  # No network after setup
    
    steps:
      - uses: actions/checkout@v4
      
      # Network enabled only for install
      - run: npm ci --ignore-scripts
        env:
          NETWORK: enabled
      
      # Rest without network
      - run: npm test
      - run: npm run build
```

### Pull Request Reviews

```yaml
# .github/CODEOWNERS
# Require review for package files
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

# Block risky behaviors
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
# GitHub Action for regular audit
name: Security Audit

on:
  schedule:
    - cron: '0 8 * * *'  # Daily at 8:00
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
# Webhook for npm publish events
# Set in npm organization settings

# Slack notification example
curl -X POST \
  -H 'Content-type: application/json' \
  --data '{"text":"🚨 New npm publish detected: package@version"}' \
  $SLACK_WEBHOOK_URL
```

### Log Analysis

```bash
# Collect and analyze:
# - npm install logs
# - CI/CD build logs
# - GitHub audit logs
# - Network traffic

# Example: GitHub audit log export
gh api /orgs/YOUR_ORG/audit-log --paginate > audit-log.json
```

## Tools

### Security Scanning

| Tool | Description | Cost |
|------|-------------|------|
| [Socket.dev](https://socket.dev) | Supply-chain security | Free/Paid |
| [Snyk](https://snyk.io) | Vulnerability scanner | Free/Paid |
| [npm audit](https://docs.npmjs.com/cli/audit) | Built-in | Free |
| [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/) | Multi-language | Free |
| [Datadog SCFW](https://github.com/DataDog/supply-chain-firewall) | Firewall | Free (OSS) |

### Monitoring

| Tool | Description |
|------|-------------|
| [Dependabot](https://docs.github.com/en/code-security/dependabot) | GitHub native |
| [Renovate](https://renovatebot.com) | Dependency updates |
| [WhiteSource Bolt](https://www.whitesourcesoftware.com/free-developer-tools/bolt) | Free scanning |

## Checklist

### Daily

- [ ] Check security alerts
- [ ] Review pending PRs with dependency changes

### Weekly

- [ ] `npm audit` / `socket scan` all projects
- [ ] Review GitHub audit log
- [ ] Check token expiration

### Monthly

- [ ] Rotate credentials (if you have policy)
- [ ] Review dependency tree
- [ ] Update security tools
- [ ] Review and cleanup npm access

### After Each Security Incident

- [ ] Full credential rotation
- [ ] Audit all projects
- [ ] Update prevention measures
- [ ] Document lessons learned

## Quick Wins

### Right Now (5 minutes)

```bash
# 1. Disable auto-merge
# In Renovate/Dependabot config

# 2. Enable 2FA
npm profile enable-2fa auth-and-writes

# 3. Set ignore-scripts
npm config set ignore-scripts true
```

### This Week

1. Set up Socket.dev or Snyk
2. Review all npm tokens
3. Update Renovate config
4. Set up branch protection

### This Month

1. Implement full CI/CD hardening
2. Set up monitoring and alerting
3. Document incident response process
4. Team training
