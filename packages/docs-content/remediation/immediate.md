---
title: Immediate Response
description: First steps when you discover a Shai-Hulud 2.0 infection
sidebar:
  order: 0
  badge:
    text: URGENT
    variant: danger
lastUpdated: 2025-12-05
---

# Immediate Response

> **⏱️ Time-critical actions when you discover an infection**

## 🚨 STOP — Do NOT:

- ❌ Run `npm install` or `bun install`
- ❌ Kill processes with `kill -9` (triggers dead man's switch!)
- ❌ Disconnect from network immediately
- ❌ Delete files before collecting evidence

## Step 1: Freeze Malicious Processes (30 seconds)

```bash
# Find suspicious processes
ps aux | grep -E "(bun_environment|trufflehog|setup_bun)" | grep -v grep

# FREEZE them (NOT kill!)
# Use SIGSTOP to pause without triggering dead man's switch
kill -STOP <PID>

# Verify they're stopped
ps aux | grep <PID>  # Should show 'T' state
```

## Step 2: Collect Evidence (2 minutes)

```bash
# Create evidence directory
mkdir -p ~/evidence/shai-hulud-$(date +%Y%m%d-%H%M)
cd ~/evidence/shai-hulud-$(date +%Y%m%d-%H%M)

# Save process list
ps aux > processes.txt

# Save network connections
netstat -an > netstat.txt
lsof -i > network-connections.txt

# Copy IOC files (don't delete yet!)
cp ~/.truffler-cache/* . 2>/dev/null
find ~ -name "setup_bun.js" -exec cp {} . \; 2>/dev/null
find ~ -name "bun_environment.js" -exec cp {} . \; 2>/dev/null
find ~ -name "actionsSecrets.json" -exec cp {} . \; 2>/dev/null

# Save environment
env > environment.txt
```

## Step 3: Assess Scope (1 minute)

```bash
# Check what credentials may be exposed
cat ~/.npmrc 2>/dev/null
cat ~/.netrc 2>/dev/null
ls -la ~/.aws/credentials 2>/dev/null
ls -la ~/.config/gcloud/ 2>/dev/null

# Check for exfiltration repos
gh repo list --json name,description 2>/dev/null | \
  grep -i "hulud"
```

## Step 4: Notify Team

**Immediately notify:**
- Security team
- DevOps/Platform team
- Affected project maintainers

**Include:**
- Timestamp of discovery
- List of affected machines
- Evidence collected
- Credentials that may be compromised

## Step 5: Begin Remediation

After evidence collection:

1. [Credential Rotation](/remediation/credentials) — Rotate ALL credentials
2. [System Cleanup](/remediation/cleanup) — Remove malware artifacts
3. [Full Remediation Guide](/remediation/guide) — Complete recovery

## Emergency Contacts

- **npm Security**: security@npmjs.com
- **GitHub Security**: security@github.com
- **CISA**: https://www.cisa.gov/report

## Timeline Reference

| Time   | Action             |
| ------ | ------------------ |
| 0:00   | Discovery          |
| 0:30   | Freeze processes   |
| 2:30   | Evidence collected |
| 3:30   | Scope assessed     |
| 5:00   | Team notified      |
| 10:00+ | Begin remediation  |
