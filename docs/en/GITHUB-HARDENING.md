# GitHub Hardening Guide

> Security configuration for GitHub Enterprise, Organizations, Repositories, and Personal Accounts

## Overview

This guide covers security settings to protect against supply chain attacks like Shai-Hulud 2.0.

---

## 🏢 GitHub Enterprise Settings

*If you have GitHub Enterprise*

### Policies → Actions

```
✅ Allow enterprise, and select non-enterprise, actions and reusable workflows
   └── Allow actions created by GitHub: ✅
   └── Allow actions by Marketplace verified creators: ⚠️ (consider disabling)
   └── Allow specified actions and reusable workflows:
       └── actions/*, github/*, your-org/*

✅ Require approval for workflows from outside collaborators
   └── Require approval for: All outside collaborators

✅ Require approval for workflows from fork pull requests
   └── Require approval for: All fork pull requests
```

### Policies → Code Security

```
✅ Dependency graph: Enabled for all repositories
✅ Dependabot alerts: Enabled for all repositories
✅ Dependabot security updates: Enabled for all repositories
✅ Secret scanning: Enabled for all repositories
✅ Secret scanning push protection: Enabled for all repositories
✅ Code scanning default setup: Enabled for all repositories
```

---

## 🏛️ Organization Settings

### Settings → Actions → General

```
Actions permissions:
├── ✅ Allow enterprise, and select non-enterprise, actions
│   └── Allow actions created by GitHub: ✅
│   └── Allow Marketplace verified creators: ❌ (more secure)
│   └── Allow specified actions:
│       └── actions/checkout@v4, actions/setup-node@v4, etc.

Fork pull request workflows:
├── 🔒 Require approval for all outside collaborators

Workflow permissions:
├── 📖 Read repository contents and packages permissions
├── ❌ Allow GitHub Actions to create and approve PRs (DISABLE!)
```

### Settings → Code Security

```
✅ Automatically enable for new repositories:
   ├── Dependency graph
   ├── Dependabot alerts
   ├── Dependabot security updates
   ├── Grouped security updates
   ├── Secret scanning
   ├── Push protection
   └── Validity checks (if available)

Security managers:
└── Add your security team
```

### Settings → Member Privileges

```
Base permissions: Read (minimum)

Repository creation:
├── ❌ Members can create public repositories
├── ✅ Members can create private repositories (or disable)
└── ❌ Members can create internal repositories

Repository forking:
└── ⚠️ Consider restricting

Pages creation:
└── ❌ Members can create Pages sites (unless needed)

Admin repository permissions:
├── ❌ Allow members to change visibility
├── ❌ Allow members to delete/transfer repositories
└── ❌ Allow forking of private/internal repositories
```

### Settings → Secrets and Variables

```
Actions secrets:
├── Use environment-scoped secrets when possible
├── Set minimum required access
└── Rotate secrets regularly

Dependabot secrets:
└── Separate from Actions secrets
```

---

## 📁 Repository Settings

### Settings → General

```
Features:
├── ❌ Wikis (disable if not used)
├── ❌ Issues (disable if using external tracker)
├── ❌ Discussions (disable - used as backdoor vector!)
└── ⚠️ Projects (enable if needed)
```

### Settings → Branches → Branch Protection Rules

For `main` / `master`:

```
✅ Require a pull request before merging
   ├── Required approvals: 1-2
   ├── ✅ Dismiss stale approvals on new commits
   ├── ✅ Require review from code owners
   ├── ✅ Restrict who can dismiss reviews
   └── ❌ Allow specified actors to bypass (be very selective)

✅ Require status checks to pass before merging
   ├── ✅ Require branches to be up to date
   └── Add checks: lint, test, security-scan, socket/socket

✅ Require conversation resolution before merging

✅ Require signed commits

✅ Require linear history

❌ Allow force pushes

❌ Allow deletions

✅ Do not allow bypassing the above settings

✅ Restrict who can push to matching branches
   └── Only: deploy bots, release managers
```

### Settings → Code Security and Analysis

```
✅ Dependency graph
✅ Dependabot alerts
✅ Dependabot security updates
✅ Grouped security updates
✅ Secret scanning
✅ Push protection

Code scanning:
└── ✅ Set up → Default (CodeQL)
```

### Settings → Actions → General

```
Actions permissions:
├── ✅ Allow owner, and select non-owner, actions
│   └── Patterns:
│       └── actions/*
│       └── github/*
│       └── your-org/*

Workflow permissions:
├── 📖 Read repository contents and packages
└── ❌ Allow GitHub Actions to create PRs

Fork pull request workflows from outside collaborators:
└── 🔒 Require approval for all outside collaborators
```

### Settings → Secrets and Variables → Actions

```
Repository secrets:
├── NPM_TOKEN: Use fine-grained, read-only if possible
├── GITHUB_TOKEN: Use default, minimize permissions
└── Cloud creds: Use OIDC instead of long-lived tokens

Environments:
├── production:
│   ├── Required reviewers: ✅
│   ├── Wait timer: 5 minutes
│   └── Deployment branches: main only
└── staging:
    └── Deployment branches: main, develop
```

### Recommended Workflow Permissions

Create `.github/workflows/permissions.yml`:

```yaml
# Minimal permissions for workflows
# Reference this in your workflows

# Example secure workflow:
name: CI
on: [push, pull_request]

permissions:
  contents: read
  
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ...
```

---

## 👤 Personal Account Settings

### Settings → Password and Authentication

```
✅ Two-factor authentication: Enabled
   └── Preferred: Hardware security key (YubiKey)
   └── Backup: TOTP app (NOT SMS)

✅ Passkeys: Add if supported

Sessions:
└── Review and revoke unknown sessions
```

### Settings → Developer Settings → Personal Access Tokens

```
Tokens (classic):
└── ❌ DELETE ALL - migrate to fine-grained

Fine-grained tokens:
├── Expiration: 90 days max
├── Repository access: Only select repositories
└── Permissions: Minimum required
    ├── Contents: Read (or Read/Write for specific needs)
    ├── Metadata: Read
    └── Others: As needed only
```

### Settings → Applications

```
Authorized OAuth Apps:
└── Review and revoke unused apps

Installed GitHub Apps:
└── Review permissions of each app
```

### Settings → SSH and GPG Keys

```
SSH keys:
├── Remove old/unused keys
├── Use Ed25519 keys
└── Name keys by device/purpose

GPG keys:
├── Set up for commit signing
└── Add to: git config --global user.signingkey YOUR_KEY
```

### Settings → Security Log

```
Review regularly for:
├── oauth_authorization
├── personal_access_token.create
├── public_key.create
└── repo.create (unexpected repos)
```

---

## 🔒 CODEOWNERS

Create `.github/CODEOWNERS`:

```
# Security-sensitive files require security team review

# Package management
package.json @your-org/security
package-lock.json @your-org/security
bun.lockb @your-org/security
yarn.lock @your-org/security
pnpm-lock.yaml @your-org/security

# Workflows
.github/workflows/ @your-org/security

# CI configuration
.github/ @your-org/security

# Security configuration
.npmrc @your-org/security
.socket.yml @your-org/security
renovate.json @your-org/security
```

---

## 🛡️ Security Policies

Create `SECURITY.md`:

```markdown
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

1. **DO NOT** create a public issue
2. Email: security@your-domain.com
3. Or use GitHub Security Advisories

We will respond within 48 hours.

## Security Measures

- Dependency scanning with Socket.dev
- Secret scanning enabled
- Signed commits required
- Branch protection enforced
```

---

## 📋 Checklist

### Organization Setup

- [ ] Enable 2FA requirement
- [ ] Configure Actions permissions
- [ ] Enable all Code Security features
- [ ] Set base permissions to Read
- [ ] Restrict repository creation
- [ ] Add security team as security managers

### Repository Setup

- [ ] Enable branch protection on main
- [ ] Require signed commits
- [ ] Require PR reviews
- [ ] Enable all security features
- [ ] Disable Discussions (if not needed)
- [ ] Set up CODEOWNERS
- [ ] Create SECURITY.md
- [ ] Configure minimal Actions permissions

### Personal Account

- [ ] Enable 2FA (hardware key preferred)
- [ ] Delete classic PATs
- [ ] Use fine-grained tokens with minimal scope
- [ ] Review authorized apps
- [ ] Set up commit signing
- [ ] Review security log

---

## Tools Integration

### Socket.dev

```yaml
# Install GitHub App
# https://github.com/apps/socket-security

# Blocks risky dependencies in PRs
```

### Dependabot

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "your-org/security"
    labels:
      - "dependencies"
      - "security-review"
```

### CodeQL

```yaml
# .github/workflows/codeql.yml
name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript
      - uses: github/codeql-action/analyze@v3
```

---

## References

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [OpenSSF Scorecard](https://securityscorecards.dev/)
- [SLSA Framework](https://slsa.dev/)
