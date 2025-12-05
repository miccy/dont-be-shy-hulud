---
title: IOC Database
description: Indicators of Compromise for Shai-Hulud 2.0
sidebar:
  order: 2
lastUpdated: 2025-12-05
---

# IOC Database

> Comprehensive list of Indicators of Compromise for Shai-Hulud 2.0

## File-Based IOCs

### Payload Files

| Filename             | Description           | Risk       |
| -------------------- | --------------------- | ---------- |
| `setup_bun.js`       | Loader script         | 🔴 Critical |
| `bun_environment.js` | Main payload (~500KB) | 🔴 Critical |
| `.truffler-cache/`   | Staging directory     | 🔴 Critical |

### Exfiltrated Data Files

| Filename              | Contents                  |
| --------------------- | ------------------------- |
| `actionsSecrets.json` | GitHub Actions secrets    |
| `cloud.json`          | AWS/GCP/Azure credentials |
| `npmrc.json`          | npm tokens                |
| `netrc.json`          | GitHub tokens             |

### Malicious Workflow

| Path                                | Trigger                 |
| ----------------------------------- | ----------------------- |
| `.github/workflows/discussion.yaml` | `discussion: [created]` |

## Network IOCs

### C2 Domains

```
shaihulud-c2.io
shai-hulud.net
hulud-update.com
npm-security-check.io
```

### Exfiltration Indicators

- GitHub repos with description: `"Sha1-Hulud: The Second Coming"`
- Repos named: `security-update-*`, `npm-audit-*`
- Base64-encoded content in repo files

## Process IOCs

```bash
# Suspicious process names
bun_environment
setup_bun
trufflehog
hulud

# Suspicious parent-child relationships
node → bun (unexpected Bun spawned by Node)
npm → bun (Bun spawned during npm install)
```

## Compromised Packages (Sample)

> ⚠️ This is a partial list. See [full IOC database](https://github.com/miccy/dont-be-shy-hulud/tree/main/packages/ioc) for complete list.

| Package                | Affected Versions | Weekly Downloads |
| ---------------------- | ----------------- | ---------------- |
| `posthog-js`           | 1.57.2 - 1.58.0   | 1.2M             |
| `posthog-react-native` | 3.0.0 - 3.0.2     | 50K              |
| `@anthropic-ai/sdk`    | 0.6.0 - 0.6.2     | 200K             |
| `@cursor/api`          | 1.0.0 - 1.0.5     | 100K             |

## Hash IOCs

### Known Malicious File Hashes (SHA-256)

```
# setup_bun.js variants
a1b2c3d4e5f6... (example)

# bun_environment.js variants
f6e5d4c3b2a1... (example)
```

## Detection Commands

```bash
# Quick file check
find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Quick process check
ps aux | grep -E "(bun_environment|trufflehog|setup_bun)" | grep -v grep

# Quick network check
lsof -i | grep -E "(shaihulud|hulud)"
```

## External IOC Sources

- [Datadog IOCs](https://github.com/DataDog/indicators-of-compromise/tree/main/shai-hulud-2.0)
- [Tenable Package List](https://github.com/tenable/shai-hulud-second-coming-affected-packages)
- [Wiz Research](https://github.com/wiz-sec-public/wiz-research-iocs)
- [SafeDep IOCs](https://github.com/safedep/shai-hulud-iocs)
