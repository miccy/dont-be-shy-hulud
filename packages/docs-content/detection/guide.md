---
title: Detection Guide
description: How to detect if you've been compromised by Shai-Hulud 2.0
sidebar:
  order: 1
  badge:
    text: Essential
    variant: tip
lastUpdated: 2025-12-05
---

# 🔍 Detection Guide

> How to detect if you've been compromised by Shai-Hulud 2.0

## Quick Check (5 minutes)

Run these commands for a quick check:

```bash
#!/bin/bash

echo "🔍 Quick Shai-Hulud 2.0 Check"
echo "=============================="

# 1. Check for payload files
echo -e "\n[1/6] Checking for payload files..."
find ~/Developer ~/Projects ~/repos ~/ -maxdepth 5 \
  \( -name "setup_bun.js" -o -name "bun_environment.js" \) \
  -type f 2>/dev/null

# 2. Check for .truffler-cache
echo -e "\n[2/6] Checking for .truffler-cache..."
if [ -d "$HOME/.truffler-cache" ]; then
  echo "⚠️  FOUND: ~/.truffler-cache exists!"
  ls -la "$HOME/.truffler-cache"
else
  echo "✅ OK: ~/.truffler-cache not found"
fi

# 3. Check for discussion.yaml
echo -e "\n[3/6] Checking for discussion.yaml workflows..."
find ~/Developer ~/Projects ~/repos -path "*/.github/workflows/discussion.yaml" 2>/dev/null

# 4. Check running processes
echo -e "\n[4/6] Checking for suspicious processes..."
ps aux | grep -E "(bun_environment|trufflehog|hulud)" | grep -v grep

# 5. Check GitHub repos (if you have gh CLI)
echo -e "\n[5/6] Checking GitHub repos..."
if command -v gh &>/dev/null; then
  gh repo list --json name,description 2>/dev/null | \
    grep -i "hulud" || echo "✅ OK: No Shai-Hulud repos found"
else
  echo "⏭️  SKIP: gh CLI not installed"
fi

# 6. Check npm tokens in .npmrc
echo -e "\n[6/6] Checking npm tokens..."
if [ -f "$HOME/.npmrc" ]; then
  if grep -q "_authToken" "$HOME/.npmrc"; then
    echo "⚠️  npm token found - verify validity and rotate if needed"
  fi
else
  echo "✅ OK: No global .npmrc"
fi

echo -e "\n=============================="
echo "Quick check complete."
```

## Automated Detection Script

We provide a robust detection script `scripts/detect.sh` that automates many of these checks.

```bash
# Basic scan
./scripts/detect.sh .

# Scan with GitHub API check (requires gh CLI authentication)
./scripts/detect.sh . --github-check

# Output results to file (useful for CI)
./scripts/detect.sh . --output results.txt
```

**Note:** The script includes hardening against false positives (e.g., excluding documentation files) and supports both local and CI environments.

## Detailed Audit

### 1. Check node_modules

```bash
# Find all node_modules with suspicious files
find ~/Developer -type d -name "node_modules" -exec \
  sh -c 'find "{}" -maxdepth 3 -name "setup_bun.js" -o -name "bun_environment.js"' \; 2>/dev/null

# Check for preinstall scripts in package.json
find ~/Developer -name "package.json" -path "*/node_modules/*" -exec \
  grep -l '"preinstall".*setup_bun\|"preinstall".*bun_environment' {} \; 2>/dev/null
```

### 2. Check npm cache

```bash
# npm cache location
npm config get cache

# Search in cache
find "$(npm config get cache)" -name "*.tgz" -exec \
  tar -tzf {} 2>/dev/null | grep -l "setup_bun.js\|bun_environment.js" \;

# Simpler - just clean the cache
npm cache clean --force
```

### 3. Check bun cache

```bash
# Bun cache location
echo "$HOME/.bun/install/cache"

# Clean it
rm -rf "$HOME/.bun/install/cache"
bun pm cache rm
```

### 4. Check GitHub Activity

```bash
# All your repos
gh repo list --limit 1000 --json name,description,pushedAt | \
  jq -r '.[] | select(.description | test("hulud|Hulud"; "i")) | .name'

# Recently created repos (last 7 days)
gh repo list --limit 100 --json name,createdAt,description | \
  jq -r --arg date "$(date -v-7d +%Y-%m-%dT%H:%M:%SZ)" \
  '.[] | select(.createdAt > $date) | "\(.name): \(.description)"'

# Check recent pushes
gh api /user/repos --paginate --jq '.[].full_name' | while read repo; do
  gh api "/repos/$repo/events" --jq \
    '.[] | select(.type == "PushEvent") | "\(.repo.name): \(.created_at)"' 2>/dev/null
done | head -50
```

### 5. Check GitHub Actions

```bash
# Find all workflow files
find ~/Developer -path "*/.github/workflows/*.yml" -o -path "*/.github/workflows/*.yaml" 2>/dev/null | \
  xargs grep -l "self-hosted\|discussion:" 2>/dev/null

# Check specific repo
ls -la ~/Developer/my-project/.github/workflows/
cat ~/Developer/my-project/.github/workflows/*.yml | grep -E "self-hosted|discussion"
```

### 6. Check System Integrity (Linux/CI)

Check for privilege escalation artifacts:

```bash
# Check for malicious sudoers file
if [ -f "/etc/sudoers.d/runner" ]; then
  echo "🚨 CRITICAL: /etc/sudoers.d/runner found! (Privilege Escalation)"
  cat /etc/sudoers.d/runner
fi

# Check for DNS hijacking
if [ -f "/tmp/resolved.conf" ]; then
  echo "⚠️  SUSPICIOUS: /tmp/resolved.conf found (DNS Hijacking)"
fi
```

### 7. Check credentials exposure

#### npm token

```bash
# Check .npmrc
cat ~/.npmrc 2>/dev/null

# Verify token validity
npm whoami

# Check published packages
npm access ls-packages
```

#### GitHub token

```bash
# Check gh CLI
gh auth status

# Check git credentials
git config --global credential.helper

# Check stored credentials (macOS)
security find-internet-password -s "github.com" 2>/dev/null
```

#### AWS credentials

```bash
# Check AWS config
cat ~/.aws/credentials 2>/dev/null

# Verify identity
aws sts get-caller-identity

# Check recent activity (if you have CloudTrail)
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin
```

#### GCP credentials

```bash
# Check GCP
cat ~/.config/gcloud/application_default_credentials.json 2>/dev/null

# Active accounts
gcloud auth list

# Verify
gcloud auth print-access-token
```

#### Azure credentials

```bash
# Check Azure
ls -la ~/.azure/

# Verify
az account show
az account list
```

### 7. Check system logs (macOS)

```bash
# Console logs
log show --predicate 'process == "node" OR process == "bun"' --last 24h

# Search for suspicious activity
log show --predicate 'eventMessage CONTAINS "hulud" OR eventMessage CONTAINS "trufflehog"' --last 7d

# Network connections
lsof -i -n | grep -E "node|bun"
```

### 8. Check network activity

```bash
# Active connections
netstat -an | grep ESTABLISHED | grep -E ":443|:80"

# DNS queries (requires packet capture)
sudo tcpdump -i en0 -n port 53 2>/dev/null | head -100

# Little Snitch / LuLu logs (if you have them)
cat ~/Library/Logs/Little\ Snitch/*.log 2>/dev/null | grep -i "github\|npm"
```

## Automated Tools

### Socket.dev CLI

```bash
# Installation
npm install -g @socketsecurity/cli

# Scan project
socket scan ./my-project

# Scan before install
socket npm install
```

### Snyk

```bash
# Installation
npm install -g snyk

# Authentication
snyk auth

# Scan
snyk test
```

### npm audit

```bash
# Basic audit
npm audit

# JSON output for parsing
npm audit --json

# Only high/critical
npm audit --audit-level=high
```

### Datadog SCFW

```bash
# Installation
pip install scfw

# Configuration
scfw configure

# Scan
scfw scan ./my-project
```

## IOC Matching

### Check against known packages

```bash
#!/bin/bash
# Download current IOC list
curl -sL "https://raw.githubusercontent.com/tenable/shai-hulud-second-coming-affected-packages/main/list.json" \
  -o /tmp/shai-hulud-ioc.json

# Extract package names
jq -r '.[].name' /tmp/shai-hulud-ioc.json > /tmp/malicious-packages.txt

# Check all package-lock.json files
find ~/Developer -name "package-lock.json" -exec \
  sh -c 'echo "Checking: $1"; jq -r ".packages | keys[]" "$1" 2>/dev/null | \
    while read pkg; do
      if grep -qF "$(basename "$pkg")" /tmp/malicious-packages.txt; then
        echo "⚠️  MATCH: $pkg in $1"
      fi
    done' _ {} \;
```

### Check file hashes

```bash
#!/bin/bash
# Known hash of setup_bun.js
KNOWN_HASH="d60ec97eea19fffb4809bc35b91033b52490ca11"

# Find and check
find ~/Developer -name "setup_bun.js" -exec \
  sh -c 'hash=$(shasum -a 1 "$1" | cut -d" " -f1); \
    if [ "$hash" = "$2" ]; then \
      echo "🚨 MALICIOUS: $1"; \
    else \
      echo "⚠️  SUSPICIOUS: $1 (different hash)"; \
    fi' _ {} "$KNOWN_HASH" \;
```

## What to Do If You Find Something

1. **DON'T PANIC** – but act quickly
2. **Isolate the machine** from the network (if possible)
3. **Document** what you found (screenshots, logs)
4. **Follow** the [Remediation Guide](REMEDIATION.md)
5. **Rotate** ALL credentials
6. **Inform** your team/organization

## False Positives

Some things may look suspicious but aren't:

- The `bun` binary is a legitimate JS runtime
- `.github/workflows/` with `self-hosted` can be legitimate
- `trufflehog` can be a legitimate security tool

The key is looking for a **combination** of indicators:
- setup_bun.js + bun_environment.js together
- discussion.yaml with `runs-on: self-hosted`
- Repos with description containing "Hulud"
