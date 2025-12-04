---
title: Detection Overview
description: How to detect Shai-Hulud 2.0 indicators of compromise
---

# Detection Overview

Understanding what to look for when scanning for Shai-Hulud 2.0.

## Detection Methods

1. **File-based IOCs** — Known malicious filenames and patterns
2. **Package-based IOCs** — Compromised npm packages
3. **Network IOCs** — Malicious domains and IPs
4. **Behavioral IOCs** — Suspicious process and file activity

## Quick Reference

| IOC Type    | Examples                                         |
| ----------- | ------------------------------------------------ |
| Files       | `setup_bun.js`, `bun_environment.js`             |
| Directories | `.truffler-cache/`, `node_modules/.cache/hulud/` |
| Packages    | `@pnpm/core`, `analytics-sdk` (800+ total)       |
| Domains     | `shaihulud-c2.io`, `shai-hulud.net`              |

See detailed guides:
- [IOC Files](/detection/ioc-files/)
- [Network IOCs](/detection/network/)
- [Behavioral Signs](/detection/behavioral/)
