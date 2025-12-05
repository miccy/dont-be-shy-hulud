# GitHub Hardening Guide (Průvodce zabezpečením)

> Bezpečnostní konfigurace pro GitHub Enterprise, Organizace, Repozitáře a Osobní účty

## Přehled

Tento průvodce pokrývá bezpečnostní nastavení pro ochranu proti supply chain útokům jako Shai-Hulud 2.0.

---

## 🏢 GitHub Enterprise Nastavení

*Pokud máte GitHub Enterprise*

### Policies → Actions

```
✅ Allow enterprise, and select non-enterprise, actions and reusable workflows
   └── Allow actions created by GitHub: ✅
   └── Allow actions by Marketplace verified creators: ⚠️ (zvažte zakázání)
   └── Allow specified actions and reusable workflows:
       └── actions/*, github/*, your-org/*

✅ Require approval for workflows from outside collaborators
   └── Require approval for: All outside collaborators

✅ Require approval for workflows from fork pull requests
   └── Require approval for: All fork pull requests
```

### Policies → Code Security

```
✅ Dependency graph: Povolen pro všechny repozitáře
✅ Dependabot alerts: Povolen pro všechny repozitáře
✅ Dependabot security updates: Povolen pro všechny repozitáře
✅ Secret scanning: Povolen pro všechny repozitáře
✅ Secret scanning push protection: Povolen pro všechny repozitáře
✅ Code scanning default setup: Povolen pro všechny repozitáře
```

---

## 🏛️ Organizační nastavení

### Settings → Actions → General

```
Actions permissions:
├── ✅ Allow enterprise, and select non-enterprise, actions
│   └── Allow actions created by GitHub: ✅
│   └── Allow Marketplace verified creators: ❌ (bezpečnější)
│   └── Allow specified actions:
│       └── actions/checkout@v4, actions/setup-node@v4, atd.

Fork pull request workflows:
├── 🔒 Require approval for all outside collaborators

Workflow permissions:
├── 📖 Read repository contents and packages permissions
├── ❌ Allow GitHub Actions to create and approve PRs (ZAKÁZAT!)
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
   └── Validity checks (pokud dostupné)

Security managers:
└── Přidej security tým
```

### Settings → Member Privileges

```
Base permissions: Read (minimum)

Repository creation:
├── ❌ Members can create public repositories
├── ✅ Members can create private repositories (nebo zakázat)
└── ❌ Members can create internal repositories

Repository forking:
└── ⚠️ Zvaž omezení

Pages creation:
└── ❌ Members can create Pages sites (pokud není potřeba)

Admin repository permissions:
├── ❌ Allow members to change visibility
├── ❌ Allow members to delete/transfer repositories
└── ❌ Allow forking of private/internal repositories
```

### Settings → Secrets and Variables

```
Actions secrets:
├── Používej environment-scoped secrets kde možné
├── Nastav minimální potřebný přístup
└── Rotuj secrets pravidelně

Dependabot secrets:
└── Odděl od Actions secrets
```

---

## 📁 Nastavení repozit RE

### Settings → General

```
Features:
├── ❌ Wikis (zakázat pokud nepoužíváte)
├── ❌ Issues (zakázat pokud používáte externí tracker)
├── ❌ Discussions (zakázat - používáno jako backdoor vektor!)
└── ⚠️ Projects (povolit pokud potřeba)
```

### Settings → Branches → Branch Protection Rules

Pro `main` / `master`:

```
✅ Require a pull request before merging
   ├── Required approvals: 1-2
   ├── ✅ Dismiss stale approvals on new commits
   ├── ✅ Require review from code owners
   ├── ✅ Restrict who can dismiss reviews
   └── ❌ Allow specified actors to bypass (buď velmi selektivní)

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
├── NPM_TOKEN: Použij fine-grained, read-only pokud možné
├── GITHUB_TOKEN: Použij default, minimalizuj permissions
└── Cloud creds: Použij OIDC místo long-lived tokenů

Environments:
├── production:
│   ├── Required reviewers: ✅
│   ├── Wait timer: 5 minut
│   └── Deployment branches: pouze main
└── staging:
    └── Deployment branches: main, develop
```

### Doporučené Workflow Permissions

Vytvoř `.github/workflows/permissions.yml`:

```yaml
# Minimální permissions pro workflows
# Odkazuj na tento v tvých workflows

# Příklad zabezpečeného workflow:
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

## 👤 Nastavení osobního účtu

### Settings → Password and Authentication

```
✅ Two-factor authentication: Povoleno
   └── Preferováno: Hardware security key (YubiKey)
   └── Backup: TOTP app (NE SMS)

✅ Passkeys: Přidej pokud podporováno

Sessions:
└── Zkontroluj a revokuj neznámé sessions
```

### Settings → Developer Settings → Personal Access Tokens

```
Tokens (classic):
└── ❌ SMAŽ VŠECHNY - migruj na fine-grained

Fine-grained tokens:
├── Expiration: max 90 dní
├── Repository access: Pouze vybrané repozitáře
└── Permissions: Minimální potřebné
    ├── Contents: Read (nebo Read/Write pro specifické potřeby)
    ├── Metadata: Read
    └── Ostatní: Pouze pokud potřeba
```

### Settings → Applications

```
Authorized OAuth Apps:
└── Zkontroluj a revokuj nepoužívané apps

Installed GitHub Apps:
└── Zkontroluj permissions každé app
```

### Settings → SSH and GPG Keys

```
SSH keys:
├── Odstraň staré/nepoužívané klíče
├── Používej Ed25519 klíče
└── Pojmenuj klíče podle zařízení/účelu

GPG keys:
├── Nastav pro commit signing
└── Přidej do: git config --global user.signingkey YOUR_KEY
```

### Settings → Security Log

```
Zkontroluj pravidelně:
├── oauth_authorization
├── personal_access_token.create
├── public_key.create
└── repo.create (neočekávané repos)
```

---

## 🔒 CODEOWNERS

Vytvoř `.github/CODEOWNERS`:

```
# Bezpečnostně citlivé soubory vyžadují review od security týmu

# Package management
package.json @your-org/security
package-lock.json @your-org/security
bun.lockb @your-org/security
yarn.lock @your-org/security
pnpm-lock.yaml @your-org/security

# Workflows
.github/workflows/ @your-org/security

# CI konfigurace
.github/ @your-org/security

# Security konfigurace
.npmrc @your-org/security
.socket.yml @your-org/security
renovate.json @your-org/security
```

---

## 🛡️ Security Policies

Vytvoř `SECURITY.md`:

```markdown
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Hlášení zranitelnosti

1. **NEVYTVÁŘEJ** veřejný issue
2. Email: security@your-domain.com
3. Nebo použij GitHub Security Advisories

Odpovíme do 48 hodin.

## Bezpečnostní opatření

- Dependency scanning s Socket.dev
- Secret scanning povolen
- Podpisované commity vyžadovány
- Branch protection vynuceno
```

---

## 📋 Checklist

### Nastavení organizace

- [ ] Povol 2FA požadavek
- [ ] Konfiguruj Actions permissions
- [ ] Povol všechny Code Security funkce
- [ ] Nastav base permissions na Read
- [ ] Omezte vytváření repozitářů
- [ ] Přidej security tým jako security managers

### Nastavení repozitáře

- [ ] Povol branch protection na main
- [ ] Vyžaduj signed commits
- [ ] Vyžaduj PR reviews
- [ ] Povol všechny security funkce
- [ ] Zakaž Discussions (pokud nepotřeba)
- [ ] Nastav CODEOWNERS
- [ ] Vytvoř SECURITY.md
- [ ] Konfiguruj minimální Actions permissions

### Osobní účet

- [ ] Povol 2FA (hardware key preferováno)
- [ ] Smaž classic PATs
- [ ] Používej fine-grained tokeny s minimálním scope
- [ ] Zkontroluj authorized apps
- [ ] Nastav commit signing
- [ ] Zkontroluj security log

---

## Integrace nástrojů

### Socket.dev

```yaml
# Nainstaluj GitHub App
# https://github.com/apps/socket-security

# Blokuje rizikové dependencies v PRs
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

## Reference

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [OpenSSF Scorecard](https://securityscorecards.dev/)
- [SLSA Framework](https://slsa.dev/)
