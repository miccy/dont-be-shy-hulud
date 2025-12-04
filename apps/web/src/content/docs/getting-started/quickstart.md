---
title: Quick Start
description: Get started with Shai-Hulud detection in under 5 minutes
---

# Quick Start

Scan your system for Shai-Hulud 2.0 indicators in under 5 minutes.

## Option 1: NPX (Recommended)

```bash
npx hulud scan .
```

## Option 2: Direct Script

```bash
curl -sSL https://raw.githubusercontent.com/miccy/dont-be-shy-hulud/main/scripts/detect.sh | bash
```

## Option 3: Clone & Run

```bash
git clone https://github.com/miccy/dont-be-shy-hulud.git
cd dont-be-shy-hulud
./scripts/detect.sh
```

## What the Scan Checks

1. **IOC Files** — `setup_bun.js`, `bun_environment.js`, `.truffler-cache/`
2. **Compromised Packages** — 800+ known malicious packages
3. **Network IOCs** — Suspicious domains and IPs
4. **GitHub Workflows** — Backdoored `discussion.yaml` files
5. **Bun Installation** — Unauthorized Bun runtime

## Understanding Results

| Status         | Meaning                                |
| -------------- | -------------------------------------- |
| ✅ `[OK]`       | Check passed, no issues found          |
| ⚠️ `[WARN]`     | Potential issue, investigate           |
| 🔴 `[CRITICAL]` | Confirmed IOC, take action immediately |

## Next Steps

- **Clean scan?** → [Hardening Guide](/hardening/npm/)
- **Issues found?** → [Immediate Actions](/remediation/immediate/)
- **Want details?** → [Detection Overview](/detection/overview/)
