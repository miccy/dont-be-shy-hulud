# 🪱 Don't Be Shy, Hulud

![Don't Be Shy, Hulud Banner](assets/banner.png)

> **Incident Response & Protection Guide for npm Supply Chain Attacks**
> Defense guide for detection & remediation against npm supply-chain worms | Shai-Hulud 2.0 (November 2025) and future threats

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/miccy/dont-be-shy-hulud?include_prereleases&label=Release)](https://github.com/miccy/dont-be-shy-hulud/releases)
[![GitHub Stars](https://img.shields.io/github/stars/miccy/dont-be-shy-hulud?style=social)](https://github.com/miccy/dont-be-shy-hulud)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
![CodeRabbit PR Reviews](https://img.shields.io/coderabbit/prs/github/miccy/dont-be-shy-hulud?utm_source=oss&utm_medium=github&utm_campaign=miccy%2Fdont-be-shy-hulud&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)

## ⚠️ CRITICAL: Dead Man's Switch Warning

> **🔴 Shai-Hulud 2.0 contains a destructive fallback mechanism!**

If the malware cannot exfiltrate data or propagate (no GitHub/npm token, blocked network), it will **OVERWRITE AND DELETE ALL WRITABLE FILES IN YOUR HOME DIRECTORY**.

### ❌ DO NOT:
- Forcefully disconnect from the internet without backup
- Block all network traffic immediately
- Kill suspicious processes without proper isolation

### ✅ INSTEAD:
1. **Backup first** — If possible, copy critical data before any action
2. **Selective network isolation** — Block outbound except GitHub API
3. **Evidence collection** — Preserve logs before cleanup
4. **Follow remediation carefully** — See [docs/REMEDIATION.md](docs/REMEDIATION.md)

> This is not theoretical — the wiper code has been [confirmed by multiple security researchers](https://securitylabs.datadoghq.com/articles/shai-hulud-2.0-npm-worm/).

---

## 🚨 URGENT: npm Token Deadline — December 9, 2025

npm is revoking **ALL legacy (classic) tokens** on December 9, 2025 as a direct response to Shai-Hulud attacks.

### Check Your Tokens Now:
```bash
npm token list
```

### Migration Options:

**Option 1: Trusted Publishing (Recommended)**
```yaml
# .github/workflows/publish.yml
- uses: actions/setup-node@v4
  with:
    registry-url: 'https://registry.npmjs.org'
- run: npm publish --provenance --access public
  env:
    NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Option 2: Granular Tokens**
- Max lifetime: 90 days (default 7 days)
- Scope to specific packages only
- Enable IP allowlist if possible

📚 [npm Token Migration Guide](https://docs.npmjs.com/about-access-tokens)

---

## ⚡ Quick Start

If you suspect you're compromised, run this immediately:

```bash
# Clone this repo
git clone https://github.com/miccy/dont-be-shy-hulud.git
cd dont-be-shy-hulud

# Run the detector
chmod +x scripts/detect.sh
./scripts/detect.sh /path/to/your/project
```

## 📖 Table of Contents

- [What is Shai-Hulud 2.0?](#what-is-shai-hulud-20)
- [Am I Affected?](#am-i-affected)
- [Roadmap](#roadmap)
- [Immediate Actions](#immediate-actions)
- [Detection Scripts](#detection-scripts)
- [Remediation Guide](#remediation-guide)
- [Hardening Your Environment](#hardening-your-environment)
- [Tool Configuration](#tool-configuration)
- [Resources](#resources)

## What is Shai-Hulud 2.0?

Shai-Hulud 2.0 (aka "The Second Coming") is a **self-propagating npm worm** discovered on November 24, 2025. It represents a significant evolution in supply chain attacks.

### Attack Timeline

| Date | Event | Source |
|------|-------|--------|
| Aug 27, 2025 | S1ngularity/Nx GitHub token theft (precursor) | Unit42 |
| Sep 15, 2025 | Shai-Hulud v1 discovered (postinstall-based) | Aikido |
| Sep 23, 2025 | CISA Advisory issued | CISA |
| Nov 5, 2025 | npm disables new classic token creation | GitHub |
| Nov 21-23, 2025 | Shai-Hulud 2.0 packages uploaded | Multiple |
| Nov 24, 2025 03:16 UTC | First detection (go-template, AsyncAPI) | Wiz |
| Nov 24, 2025 04:11 UTC | PostHog packages compromised | PostHog |
| Nov 24, 2025 05:09 UTC | Postman packages compromised | Postman |
| Nov 24, 2025 | Peak: **1,000 new repos every 30 minutes** | Datadog |
| Nov 25, 2025 | **800+ packages**, 25,000+ repos, **1,200+ orgs**, **20M+ weekly downloads** | Wiz, Check Point |
| Nov 25, 2025 | Secondary phase detected ("Continued Coming") | Wiz |
| Nov 26, 2025 | GitHub reduces public malicious repos to ~300 | GitHub |
| Dec 02, 2025 | Community detection tools matured (don't-be-shy-hulud v1.5.0 released) | Community |
| **Dec 9, 2025** | **npm legacy token revocation deadline** | npm |

### Key Differences from v1

| Feature | v1 (September) | v2 (November) |
|---------|----------------|---------------|
| Execution Phase | `postinstall` | `preinstall` |
| Exfiltration | Webhook endpoint | GitHub repos |
| Runtime | Node.js | Bun |
| Fallback | None | Dead-man switch (wipe data) |
| Persistence | None | GitHub Actions backdoor |
| Propagation | ~500 packages | **800+ packages** (20M+ downloads) |

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    SHAI-HULUD 2.0 ATTACK FLOW                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. INITIAL INFECTION                                           │
│     └── Compromised npm package with preinstall script          │
│         └── Drops: setup_bun.js + bun_environment.js            │
│                                                                 │
│  2. PAYLOAD EXECUTION                                           │
│     └── Installs Bun runtime (evades Node.js monitoring)        │
│         └── Runs 10MB+ obfuscated payload                       │
│                                                                 │
│  3. CREDENTIAL HARVESTING                                       │
│     ├── ~/.npmrc (npm tokens)                                   │
│     ├── ~/.aws/, ~/.azure/, ~/.config/gcloud/                   │
│     ├── Environment variables                                   │
│     ├── GitHub Actions secrets                                  │
│     └── TruffleHog scan for secrets in codebase                 │
│                                                                 │
│  4. EXFILTRATION                                                │
│     └── Creates public GitHub repo with stolen data             │
│         └── Description: "Sha1-Hulud: The Second Coming"        │
│                                                                 │
│  5. PROPAGATION                                                 │
│     ├── Uses stolen npm token to publish infected versions      │
│     ├── Up to 100 packages per victim                           │
│     └── Cross-victim: uses other victims' tokens                │
│                                                                 │
│  6. PERSISTENCE                                                 │
│     └── GitHub Actions workflow backdoor                        │
│         └── Triggered via repository discussions                │
│                                                                 │
│  7. FALLBACK (if blocked)                                       │
│     └── Dead-man switch: wipes user data                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Am I Affected?

### Quick Check

```bash
# Check for IOC files
find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Check for malicious workflows
find . -path "*/.github/workflows/*" -name "*.yml" -exec grep -l "SHA1HULUD\|self-hosted" {} \;

# Check npm cache
npm cache ls 2>/dev/null | grep -E "(setup_bun|bun_environment)"
```

### High-Risk Packages

If you use any of these packages, **immediately audit your lockfile**:

| Package | Risk | Notes |
|---------|------|-------|
| `@postman/tunnel-agent` | 🔴 Critical | 27% of environments |
| `posthog-node` | 🔴 Critical | 25% of environments |
| `posthog-js` | 🔴 Critical | 15% of environments |
| `@asyncapi/specs` | 🔴 Critical | 20% of environments |
| `@asyncapi/openapi-schema-parser` | 🔴 Critical | 17% of environments |
| `@zapier/*` | 🔴 Critical | Multiple packages |
| `@ensdomains/*` | 🔴 Critical | Multiple packages |
| `@postman/postman-mcp-cli` | 🟠 High | MCP tooling |
| `zapier-sdk` | 🟠 High | |
| `angulartics2` | 🟠 High | |
| `koa2-swagger-ui` | 🟠 High | |
| `tinycolor2` | 🟠 High | v4.1.2 specifically (note: tinycolor2, not tinycolor) |
| `ngx-bootstrap` | 🟠 High | Angular bootstrap components |
| `@zapier/zapier-sdk` | 🔴 Critical | v0.15.5-0.15.7 |

For full IOC database with detailed indicators, see [IOC Lists](#ioc-lists) below and [ioc/malicious-packages.json](ioc/malicious-packages.json).

## Immediate Actions

### 🔴 If Compromised

```bash
# 1. STOP - Don't run npm install on any project
# 2. Disconnect from network if possible

# 3. Check for exfiltration repos on your GitHub
# Search: https://github.com/search?q=Sha1-Hulud+user%3AYOUR_USERNAME

# 4. Revoke ALL tokens immediately
npm token revoke $(npm token ls --json | jq -r '.[].key')

# 5. Rotate credentials
# See: docs/REMEDIATION.md
```

### 🟠 Preventive (Not Yet Confirmed Compromised)

```bash
# 1. Freeze npm updates
# Add to .npmrc:
echo "ignore-scripts=true" >> ~/.npmrc

# 2. Clear caches
rm -rf node_modules
npm cache clean --force
# or for bun:
rm -rf node_modules bun.lockb
bun pm cache rm

# 3. Pin dependencies to known clean versions
# Use dates before Nov 21, 2025
```

## Detection Scripts

### Full System Scan

```bash
./scripts/detect.sh ~
```

### Project-Only Scan

```bash
./scripts/detect.sh /path/to/project
```

### CI/CD Integration

```yaml
# .github/workflows/security-scan.yml
name: Shai-Hulud Detection
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Shai-Hulud Detector
        run: |
          curl -sSL https://raw.githubusercontent.com/miccy/dont-be-shy-hulud/main/scripts/detect.sh | bash -s -- .
```

## Remediation Guide

See [docs/REMEDIATION.md](docs/REMEDIATION.md) for detailed steps.

### Quick Remediation

```bash
# 1. Identify affected packages
./scripts/detect.sh . --output affected.txt

# 2. Roll back to clean versions
npm install package-name@version-before-nov-21

# 3. Regenerate lockfile
rm package-lock.json
npm install --ignore-scripts

# 4. Verify
npm audit
./scripts/detect.sh .
```

## Hardening Your Environment

### npm/bun Configuration

```bash
# ~/.npmrc - Recommended settings
ignore-scripts=true
audit=true
fund=false
```

### ⚠️ Critical: Bun Users Must Read This

**Bun has a known bug**: The `.npmrc` setting `ignore-scripts=true` does **NOT** work reliably!

Bun prioritizes its internal `trustedDependencies` allowlist over `.npmrc` settings. This means lifecycle scripts may still execute even with `ignore-scripts=true` in your config.

#### ❌ This is NOT reliable in Bun:
```ini
# ~/.npmrc or .npmrc
ignore-scripts=true
```

#### ✅ ALWAYS use CLI flag:
```bash
bun install --ignore-scripts
```

#### In CI/CD:
```yaml
- name: Install dependencies (Bun)
  run: bun install --ignore-scripts  # REQUIRED flag
```

> **Why This Matters:** Shai-Hulud 2.0 specifically installs Bun runtime as an **evasion technique** because most security tools only monitor Node.js processes.

### Renovate Configuration

See [configs/renovate-secure.json](configs/renovate-secure.json) for a hardened Renovate config that:
- Disables automerge for npm packages
- Increases stabilityDays to 7
- Requires security review labels
- Blocks preinstall/postinstall changes

**👉 For a shared preset you can use across all repos, see [miccy/renovate-config](https://github.com/miccy/renovate-config)**:

```json
{ "extends": ["github>miccy/renovate-config"] }
```

This shared preset includes:
- 7-day `stabilityDays` and `minimumReleaseAge`
- `npm:unpublishSafe` protection
- Warnings on Shai-Hulud affected packages
- No automerge for production dependencies

### GitHub Settings

See [docs/GITHUB-HARDENING.md](docs/GITHUB-HARDENING.md) for:
- Branch protection rules
- Actions security settings
- Secret scanning configuration
- Code scanning setup

## Tool Configuration

### Socket.dev

See [configs/socket.yml](configs/socket.yml) for recommended configuration.

### Dependabot

See [configs/dependabot.yml](configs/dependabot.yml) for secure settings.

### GitHub Actions

See [docs/GITHUB-HARDENING.md](docs/GITHUB-HARDENING.md) for lockdown guide.

## IOC Lists

### Official Sources

| Source | URL |
|--------|-----|
| Datadog | [github.com/DataDog/indicators-of-compromise](https://github.com/DataDog/indicators-of-compromise/tree/main/shai-hulud-2.0) |
| Wiz Research | [wiz-sec-public/wiz-research-iocs](https://github.com/wiz-sec-public/wiz-research-iocs) |
| Tenable | [tenable/shai-hulud-second-coming-affected-packages](https://github.com/tenable/shai-hulud-second-coming-affected-packages) |
| SafeDep | [safedep/shai-hulud-migration-response](https://github.com/safedep/shai-hulud-migration-response) |
| Cobenian | [Cobenian/shai-hulud-detect](https://github.com/Cobenian/shai-hulud-detect) |

### File IOCs

| File | Purpose | Hash (SHA-256) |
|------|---------|----------------|
| `setup_bun.js` | Loader/dropper | Various |
| `bun_environment.js` | Main payload (~10MB) | Various |
| `actionsSecrets.json` | Exfil data (double base64) | N/A |
| `.github/workflows/formatter_*.yml` | Backdoor workflow | N/A |

### Behavioral IOCs

- GitHub repos with description: `Sha1-Hulud: The Second Coming`
- GitHub Actions runners named `SHA1HULUD`
- Files: `cloud.json`, `contents.json`, `environment.json`, `truffleSecrets.json`
- `.truffler-cache` directory
- Bun installation in unexpected locations

## Resources

### Official Advisories

- [CISA Alert](https://www.cisa.gov/news-events/alerts/2025/09/23/widespread-supply-chain-compromise-impacting-npm-ecosystem)
- [npm Security Advisory](https://github.com/npm/cli/security/advisories)

### Vendor Reports

- [HackerOne Blog](https://www.hackerone.com/blog/shai-hulud-2-npm-worm-supply-chain-attack)
- [Socket.dev Analysis](https://socket.dev/blog/shai-hulud-strikes-again-v2)
- [Datadog Security Labs](https://securitylabs.datadoghq.com/articles/shai-hulud-2.0-npm-worm/)
- [Wiz Research](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)
- [GitLab Security](https://about.gitlab.com/blog/gitlab-discovers-widespread-npm-supply-chain-attack/)
- [Palo Alto Unit 42](https://unit42.paloaltonetworks.com/npm-supply-chain-attack/)
- [GitGuardian](https://blog.gitguardian.com/shai-hulud-2/)

### Detection Tools

- [gensecaihq/Shai-Hulud-2.0-Detector](https://github.com/gensecaihq/Shai-Hulud-2.0-Detector)
- [Cobenian/shai-hulud-detect](https://github.com/Cobenian/shai-hulud-detect)
- [SafeDep GitHub App](https://github.com/apps/safedep)

## 💬 Community

Have questions, found new IOCs, or want to share your experience?

- **[GitHub Discussions](https://github.com/miccy/dont-be-shy-hulud/discussions)** — Ask questions, share findings, get help
- **[Report Security Issue](https://github.com/miccy/dont-be-shy-hulud/security/advisories/new)** — For sensitive security reports
- **[Open an Issue](https://github.com/miccy/dont-be-shy-hulud/issues)** — Bug reports and feature requests

## Roadmap

This project is under active development. See our detailed **[ROADMAP.md](ROADMAP.md)** for:

- ✅ Completed features
- 🚧 Work in progress
- 📋 Planned improvements
- 🤝 Contribution opportunities

Want to help? Pick any unchecked item from the roadmap and submit a PR!

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

### Priority Areas (see [ROADMAP.md](ROADMAP.md) for details)

- [x] SIGSTOP suspend script (critical for safe malware handling)
- [x] Expanded IOC database (800+ packages)
- [ ] Stack-specific documentation (Expo, Bun, Tauri)
- [x] Network IOCs and file hashes
- [ ] SARIF output format

## 🛠️ Repository Maintenance

### Language Selection

This repository comes with bilingual documentation (English/Czech). To keep only one language:

```bash
# Keep only English (removes cs/ folder)
./scripts/set-language.sh en

# Keep only Czech (promotes cs/ files to root)
./scripts/set-language.sh cs
```

You can also do this via **GitHub Actions**: Go to `Actions` -> `Set Repository Language` -> `Run workflow`.

### VS Code Integration

This project includes VS Code tasks. Press `Cmd+Shift+P` -> `Tasks: Run Task` to easily run:
- `🛡️ Quick Audit`
- `🔍 Full Audit`
- `🧹 Set Language`

## License

MIT License - See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

This guide compiles research from multiple security teams:
- Aikido Security (initial detection)
- Socket.dev, Datadog, Wiz, GitLab, Palo Alto Networks Unit 42
- GitGuardian, SafeDep, Tenable
- The broader security community

**Stay safe. Rotate your secrets. Pin your dependencies.** 🛡️

---

<div align="center">
  <p>🛠 Built by <a href="https://github.com/miccy">@miccy</a> out of hatred for Worms 🤬</p>
</div>
