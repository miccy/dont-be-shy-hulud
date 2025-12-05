---
title: Remediation Guide
description: Step-by-step guide to recover from Shai-Hulud 2.0 infection
sidebar:
  order: 1
  badge:
    text: Critical
    variant: danger
lastUpdated: 2025-12-05
---

# 🔧 Remediation Guide

> Kroky k nápravě po kompromitaci Shai-Hulud 2.0

## ⚠️ Důležité upozornění

Pokud jsi našel IOC na svém systému, **předpokládej plnou kompromitaci**. Malware mohl:
- Ukrást všechny credentials na disku
- Exfiltrovat environment variables
- Získat přístup ke cloud službám
- Publikovat malicious verze tvých npm packages
- Nainstalovat persistent backdoor

## Fáze 1: Okamžitá izolace (0-15 minut)

### 1.1 Zastav síťovou aktivitu

```bash
# macOS - dočasně vypni síť
networksetup -setairportpower en0 off  # WiFi
# nebo odpoj ethernet kabel

# Pokud potřebuješ síť pro rotaci credentials,
# alespoň zablokuj outbound na GitHub/npm
sudo pfctl -e
echo "block out proto tcp from any to api.github.com" | sudo pfctl -f -
echo "block out proto tcp from any to registry.npmjs.org" | sudo pfctl -f -
```

### 1.2 Zastav podezřelé procesy

```bash
# Najdi a zabij malicious procesy
pkill -f "bun_environment"
pkill -f "setup_bun"
pkill -f "trufflehog"

# Ověř
ps aux | grep -E "bun|node|trufflehog" | grep -v grep
```

### 1.3 Dokumentuj stav

```bash
# Ulož aktuální stav
mkdir -p ~/incident-$(date +%Y%m%d)
cd ~/incident-$(date +%Y%m%d)

# Procesy
ps aux > processes.txt

# Network connections
lsof -i -n > network.txt

# Environment
env > environment.txt

# Filesystem changes (posledních 24h)
find ~ -mtime -1 -type f > recent_files.txt
```

## Fáze 2: Rotace credentials (15-60 minut)

### 2.1 npm Token

```bash
# Revokuj všechny tokeny
npm token list
npm token revoke <token-id>

# Nebo revokuj všechny najednou
npm token list --json | jq -r '.[].key' | xargs -I {} npm token revoke {}

# Vygeneruj nový token
npm login

# Ověř
npm whoami
```

### 2.2 GitHub PAT / SSH Keys

```bash
# 1. Jdi na https://github.com/settings/tokens
# 2. Revokuj VŠECHNY tokeny
# 3. Vygeneruj nové fine-grained tokeny

# SSH keys
# 1. Jdi na https://github.com/settings/keys
# 2. Odstraň všechny klíče
# 3. Vygeneruj nové
ssh-keygen -t ed25519 -C "your_email@example.com"
# 4. Přidej nový klíč na GitHub

# Revokuj OAuth apps
# https://github.com/settings/applications

# Zkontroluj sessions
# https://github.com/settings/sessions
```

### 2.3 AWS Credentials

```bash
# Deaktivuj staré access keys
aws iam list-access-keys --user-name YOUR_USER
aws iam update-access-key --access-key-id AKIAXXXXXXXX --status Inactive

# Vygeneruj nové
aws iam create-access-key --user-name YOUR_USER

# Aktualizuj lokální config
aws configure

# Pokud máš IAM role, rotuj assume role credentials
# Zkontroluj CloudTrail pro podezřelou aktivitu
aws cloudtrail lookup-events \
  --start-time $(date -v-7d +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date +%Y-%m-%dT%H:%M:%SZ)
```

### 2.4 GCP Credentials

```bash
# Revokuj všechna autorizace
gcloud auth revoke --all

# Nová autentizace
gcloud auth login
gcloud auth application-default login

# Rotuj service account keys
gcloud iam service-accounts keys list --iam-account=SA@PROJECT.iam.gserviceaccount.com
gcloud iam service-accounts keys delete KEY_ID --iam-account=SA@PROJECT.iam.gserviceaccount.com
gcloud iam service-accounts keys create new-key.json --iam-account=SA@PROJECT.iam.gserviceaccount.com
```

### 2.5 Azure Credentials

```bash
# Logout
az logout

# Nový login
az login

# Rotuj service principal credentials
az ad sp credential reset --name YOUR_SP_NAME
```

### 2.6 Další credentials

```bash
# Docker Hub
docker logout
docker login

# Slack
# Regeneruj tokens na https://api.slack.com/apps

# Datadog
# Rotuj API keys na https://app.datadoghq.com/organization-settings/api-keys

# Ostatní služby - projdi všechny
```

## Fáze 3: Čištění systému (30-60 minut)

### 3.1 Odstranění malware

```bash
# Smaž malicious soubory
find ~ -name "setup_bun.js" -delete 2>/dev/null
find ~ -name "bun_environment.js" -delete 2>/dev/null
rm -rf ~/.truffler-cache

# Smaž podezřelé workflows
find ~/Developer -path "*/.github/workflows/discussion.yaml" -delete 2>/dev/null
```

### 3.2 Vyčištění npm/bun

```bash
# npm
rm -rf ~/.npm
npm cache clean --force

# bun
rm -rf ~/.bun/install/cache
bun pm cache rm

# node_modules ve všech projektech
find ~/Developer -type d -name "node_modules" -prune -exec rm -rf {} \; 2>/dev/null
```

### 3.3 Vyčištění git credentials

```bash
# macOS Keychain
security delete-internet-password -s "github.com"
security delete-generic-password -s "npm"

# Git credential cache
git credential reject <<EOF
protocol=https
host=github.com
EOF

git credential reject <<EOF
protocol=https
host=registry.npmjs.org
EOF
```

### 3.4 Kontrola persistence

```bash
# Launch Agents
ls -la ~/Library/LaunchAgents/
# Odstraň podezřelé plist soubory

# Login Items
osascript -e 'tell application "System Events" to get the name of every login item'

# Cron jobs
crontab -l

# Shell profiles
cat ~/.zshrc | grep -v "^#" | grep -v "^$"
cat ~/.bashrc | grep -v "^#" | grep -v "^$"
```

## Fáze 4: Reinstalace závislostí (1-2 hodiny)

### 4.1 Pro každý projekt

```bash
cd /path/to/project

# Smaž staré
rm -rf node_modules
rm -f package-lock.json  # nebo bun.lockb

# Reinstaluj s ignore-scripts
npm install --ignore-scripts
# nebo
bun install --ignore-scripts

# Ověř
npm ls
```

### 4.2 Audit závislostí

```bash
# npm audit
npm audit

# Socket.dev scan
socket scan create .

# Snyk
snyk test
```

### 4.3 Socket CLI - automatická oprava

```bash
# Automaticky oprav CVE kde je to možné
socket fix ./

# Optimalizuj dependencies pomocí Socket Registry
socket optimize ./

# Socket Registry = hardened verze populárních packages
# Přidá "resolutions" do package.json
```

**Příklad výstupu `socket optimize`:**
```json
{
  "resolutions": {
    "yocto-spinner": "npm:@socketregistry/yocto-spinner@^1"
  }
}
```

### 4.4 Hromadná oprava více repos

```bash
#!/bin/bash
# fix-all-repos.sh

REPOS=("repo1" "repo2" "repo3")
BASE_PATH="$HOME/Developer"

for repo in "${REPOS[@]}"; do
  echo "=== Fixing $repo ==="
  cd "$BASE_PATH/$repo" || continue
  
  socket fix ./
  socket optimize ./
  
  if git diff --quiet; then
    echo "No changes in $repo"
  else
    git add -A
    git commit -m "chore(deps): socket security fixes"
    echo "Committed changes in $repo"
  fi
done
```

### 4.3 Pinování verzí

```bash
# Přidej resolutions/overrides pro známé safe verze
# package.json
{
  "overrides": {
    "@asyncapi/specs": "6.7.0",
    "posthog-node": "4.17.0"
  }
}
```

## Fáze 5: GitHub Cleanup

### 5.1 Kontrola repos

```bash
# Najdi exfiltration repos
gh repo list --limit 1000 --json name,description | \
  jq -r '.[] | select(.description | test("hulud"; "i")) | .name'

# Smaž je
gh repo delete REPO_NAME --yes
```

### 5.2 Kontrola workflows

```bash
# Pro každý repo
gh repo list --json name --jq '.[].name' | while read repo; do
  echo "Checking $repo..."
  gh api "/repos/YOUR_USERNAME/$repo/contents/.github/workflows" 2>/dev/null | \
    jq -r '.[].name' | grep -i discussion
done
```

### 5.3 Revokace sessions

1. Jdi na https://github.com/settings/sessions
2. Revokuj všechny neznámé sessions
3. Zkontroluj https://github.com/settings/security-log

## Fáze 6: Verifikace publikovaných packages

### 6.1 Kontrola npm publications

```bash
# Seznam tvých packages
npm access ls-packages

# Pro každý package zkontroluj verze
npm view YOUR_PACKAGE versions --json

# Zkontroluj nedávné publikace
npm view YOUR_PACKAGE time --json | jq 'to_entries | sort_by(.value) | reverse | .[0:5]'
```

### 6.2 Unpublish malicious versions

```bash
# Pokud najdeš malicious verzi
npm unpublish YOUR_PACKAGE@VERSION

# Nebo deprecate
npm deprecate YOUR_PACKAGE@VERSION "Security issue - do not use"
```

### 6.3 Publikace patch verze

```bash
# Bump verzi
npm version patch

# Publikuj čistou verzi
npm publish
```

## Fáze 7: Notifikace

### 7.1 Interní tým

Informuj:
- Security team
- DevOps/Platform team
- Všechny vývojáře v týmu

### 7.2 Uživatelé tvých packages

```markdown
# Security Advisory

We discovered that versions X.Y.Z of [package] were compromised as part of the Shai-Hulud 2.0 npm supply chain attack.

## Affected Versions
- X.Y.Z

## Recommended Action
- Upgrade to version X.Y.Z+1 immediately
- Rotate any credentials that may have been exposed
- Review your systems for IOCs

## Timeline
- [date]: Malicious version published
- [date]: Discovered and removed
- [date]: Clean version published

## Contact
[your contact info]
```

### 7.3 npm Security Team

```bash
# Report na npm
# https://www.npmjs.com/support

# Nebo email
# security@npmjs.com
```

## Post-Incident Actions

### Monitoring

- Nastav alerting na npm publish events
- Monitoruj GitHub activity
- Sleduj neobvyklé API calls

### Prevention

Viz [Prevention Guide](PREVENTION.md)

### Lessons Learned

Zdokumentuj:
- Jak k incidentu došlo
- Co fungovalo při detekci
- Co by šlo zlepšit
- Akční položky do budoucna
