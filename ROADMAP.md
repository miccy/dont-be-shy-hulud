# 🗺️ Project Roadmap

> **Status:** Active Development
> **Last Updated:** 2025-12-04
> **Maintainer:** [@miccy](https://github.com/miccy)

This roadmap is based on comprehensive security audits from multiple AI models (Claude Opus 4.5, GPT-5.1-Pro, Grok-4.1, Perplexity, Proton-Lumo, Gemini-3-Pro) and community feedback. We're transparent about what's done and what needs work.

**Want to help?** Pick any unchecked item and submit a PR! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📊 Progress Overview

| Category                                        | Progress | Priority |
| ----------------------------------------------- | -------- | -------- |
| [Core Detection](#-core-detection)              | 🟢 85%    | P0       |
| [IOC Database](#-ioc-database)                  | 🟡 60%    | P0       |
| [Documentation](#-documentation)                | 🟡 60%    | P1       |
| [Automation & CI/CD](#-automation--cicd)        | 🟡 50%    | P1       |
| [Tooling](#-tooling)                            | 🔴 20%    | P2       |
| [Community & Ecosystem](#-community--ecosystem) | 🔴 10%    | P2       |

---

## 🎯 Core Detection

### Scripts & Tools

- [x] `detect.sh` - Main detection script
  - [x] IOC file detection (`setup_bun.js`, `bun_environment.js`, `bundle.js`)
  - [x] Malicious workflow detection
  - [x] Lockfile scanning for compromised packages
  - [x] npm cache inspection
  - [x] Verbose mode and CI-friendly exit codes
  - [x] Color-coded output
  - [x] **SIGSTOP mode** - Freeze processes instead of killing (prevents wiper trigger)
  - [ ] Scan mode flags (`--lockfiles-only`, `--filesystem-only`, `--full`)
  - [ ] JSON/SARIF output format
  - [ ] Parallel scanning for large monorepos
  - [ ] Bun lockfile (`bun.lockb`) deep inspection

- [x] `quick-audit.sh` - Fast preliminary check
- [x] `full-audit.sh` - Comprehensive system audit
- [x] `check-github-repos.sh` - Check for exfiltration repos
  - [ ] Batch processing for organizations
  - [ ] Self-hosted runner detection (`SHA1HULUD`)
  - [ ] Workflow injection detection

- [x] **`suspend-malware.sh`** - Safe process suspension (P0 - Critical) ✅ Added in v1.5.0
  ```bash
  # Uses SIGSTOP instead of SIGKILL to prevent wiper activation
  kill -STOP $PID  # Freeze, don't kill!
  ```
  - [x] Auto-detect malicious processes
  - [ ] Create memory dump before suspension
  - [x] Network isolation guidance (in docs)
  - [x] `--dry-run` mode
  - [x] `--resume` mode to unfreeze
  - [x] State file tracking

- [ ] **`gh-scan-exfil.sh`** - GitHub API scanner for exfiltration repos
  - [ ] Search repos by description pattern (`Sha1-Hulud: The Second Coming`)
  - [ ] Detect random 18-char repo names (`[0-9a-z]{18}`)
  - [ ] List self-hosted runners
  - [ ] Audit recent workflow changes

### Detection Capabilities

- [x] Package name matching
- [x] File pattern matching
- [ ] **File hash verification** (SHA256)
  - [ ] `setup_bun.js` known hashes
  - [ ] `bun_environment.js` known hashes
  - [ ] `bundle.js` v1 hashes (7 variants)
- [x] **Network IOC detection** ✅ Added `ioc/network.json` in v1.5.0
  - [x] C2 domain monitoring
  - [x] Exfiltration webhook patterns
  - [x] GitHub API abuse patterns
  - [x] Cloud metadata abuse detection
  - [x] Firewall rule recommendations
  - [x] Suspicious outbound connection alerts (real-time)
- [ ] **Behavioral analysis**
  - [ ] Unexpected Bun installation detection
  - [ ] TruffleHog download detection
  - [ ] Mass npm publish detection

---

## 📦 IOC Database

### Current State: ~9 packages listed
### Target State: 800+ packages with full metadata

### Package Lists

- [x] `ioc/malicious-packages.json` - Basic high-risk packages
  - [ ] Expand to full 800+ package list
  - [ ] Add version ranges (not just specific versions)
  - [ ] Add compromise dates
  - [ ] Add risk scores
  - [ ] Add remediation status (fixed/unpublished/active)

- [ ] **`ioc/packages-v1.json`** - September 2025 wave packages
  - [ ] ~500 packages from CISA alert
  - [ ] `@ctrl/tinycolor`, `@crowdstrike/*`, etc.

- [ ] **`ioc/packages-v2.json`** - November 2025 wave packages
  - [ ] 800+ packages from Datadog/Wiz
  - [ ] `@postman/*`, `@asyncapi/*`, `@zapier/*`, `@ensdomains/*`, `posthog-*`

- [ ] **`ioc/packages-maven.json`** - Maven Central crossover
  - [ ] `org.mvnpm:posthog-node:4.18.1`
  - [ ] Other npm-to-Maven mirrors

### File Hashes

- [ ] **`ioc/hashes.json`** - Known malicious file hashes
  ```json
  {
    "setup_bun.js": {
      "sha256": ["a3894003ad1d293ba96d77881ccd2071446dc3f65f434669b49b3da92421901a"],
      "description": "Bun installer dropper"
    },
    "bun_environment.js": {
      "sha256": ["62ee164b9b306250c1172583f138c9614139264f889fa99614903c12755468d0"],
      "description": "Main payload (10MB obfuscated)"
    }
  }
  ```

### Network IOCs

- [ ] **`ioc/network.json`** - C2 and exfiltration indicators
  ```json
  {
    "c2_domains": [
      "shaihulud-c2.io",
      "shai-hulud.net"
    ],
    "c2_ips": ["185.199.108.153"],
    "exfil_webhooks": [
      "webhook.site/*bb8ca5f6-4175-45d2-b042-fc9ebb8170b7*"
    ],
    "github_patterns": [
      "description:Sha1-Hulud: The Second Coming",
      "description:Shai-Hulud Migration"
    ]
  }
  ```

### Behavioral Patterns

- [x] GitHub repo description patterns
- [x] Workflow file patterns
- [ ] Process behavior signatures
- [ ] File system artifacts (`~/.dev-env/`, `.truffler-cache/`)

### Vendor IOC Integration

- [ ] **`ioc/vendor/`** - Snapshots from security vendors
  - [ ] Datadog IOC feed integration
  - [ ] Wiz IOC list
  - [ ] Tenable package list
  - [ ] SafeDep indicators
  - [ ] Socket.dev alerts

- [ ] **`scripts/update-iocs.sh`** - Auto-update from vendor sources
  - [ ] Fetch latest from GitHub repos
  - [ ] Merge and deduplicate
  - [ ] Generate changelog

---

## 📚 Documentation

### Core Docs

- [x] `README.md` - Project overview
  - [x] Attack flow diagram
  - [x] Quick start commands
  - [x] v1 vs v2 comparison table
  - [x] Update metrics (800+ packages, 1200+ orgs, 25k+ repos)
  - [x] Add regex for repo name pattern `[0-9a-z]{18}`
  - [x] Mermaid diagram for attack flow

- [x] `docs/DETECTION.md` - Detection guide
- [x] `docs/REMEDIATION.md` - Cleanup steps
  - [ ] Add GitHub Token Revocation Plan expansion
  - [ ] Add OAuth Apps audit section
  - [ ] Add "What if wiper activated" recovery guide

- [x] `docs/PREVENTION.md` - Hardening guide
- [x] `docs/GITHUB-HARDENING.md` - GitHub-specific security
- [x] `docs/THREAT-OVERVIEW.md` - Threat intelligence
- [x] `docs/MACOS-AUDIT.md` - macOS-specific guidance

### Stack-Specific Documentation (Missing - High Priority)

- [ ] **`docs/stacks/EXPO-REACT-NATIVE.md`**
  - [ ] Risks from `posthog-react-native` compromise
  - [ ] Metro bundler exposure
  - [ ] Expo CLI attack surface
  - [ ] Recommended: `--ignore-scripts` in mobile CI
  - [ ] Analytics SDK pinning strategy

- [x] **`docs/stacks/BUN.md`** ✅ Added
  - [x] Why Bun is NOT safer (it's the attack vector!)
  - [x] `bunfig.toml` hardening
  - [x] Detecting unauthorized Bun installations
  - [x] `~/.bun` and `~/.dev-env` inspection

- [ ] **`docs/stacks/TYPESCRIPT-ASTRO.md`**
  - [ ] Build pipeline risks
  - [ ] Vite plugin exposure
  - [ ] `@asyncapi/*` impact

- [ ] **`docs/stacks/RUST-GO-TAURI.md`**
  - [ ] Cross-language credential theft
  - [ ] Shared CI/CD risks
  - [ ] `node-gyp`, `wasm-pack` exposure
  - [ ] Tauri build isolation recommendations
  - [ ] Signing key protection

- [ ] **`docs/stacks/MONOREPO.md`**
  - [ ] Turborepo/Nx workspace risks
  - [ ] Shared token exposure
  - [ ] Per-package scanning strategies

### Translations

- [x] Czech (`cs/`) - Full translation
  - [x] README.md
  - [x] docs/* (all files)
  - [ ] ROADMAP.md (this file)

- [ ] Other languages (community contributions welcome)
  - [ ] German (`de/`)
  - [ ] Spanish (`es/`)
  - [ ] Japanese (`ja/`)

---

## ⚙️ Automation & CI/CD

### GitHub Actions Workflows

- [x] `ci.yml` - Basic CI
- [x] `supply-chain-security.yml` - Security scanning
- [x] `release.yml` - Release automation
- [x] `set-language.yml` - Language switching
- [x] `pr-changelog.yml` - PR changelog generation

- [ ] **`ioc-update.yml`** - Automated IOC updates
  - [ ] Daily/weekly cron job
  - [ ] Fetch from vendor sources
  - [ ] Auto-PR with changes
  - [ ] Changelog generation

- [ ] **`community-scan.yml`** - Allow users to trigger scans
  - [ ] Workflow dispatch with repo URL input
  - [ ] Results as PR comment or artifact

### Configuration Templates

- [x] `configs/renovate-secure.json` - Secure Renovate config
- [x] `configs/renovate-hardened.json` - Hardened config
- [x] `configs/renovate-lockdown.json` - Maximum security

- [x] **`configs/renovate-defense.json`** - Anti-worm specific rules ✅ Added

- [x] `configs/dependabot.yml` - Dependabot config
- [x] `configs/socket.yml` - Socket.dev policy
- [x] `configs/.npmrc-secure` - Secure npm config

- [x] **`configs/bunfig-secure.toml`** - Bun security config ✅ Added
  - [x] Disable postinstall by default
  - [x] Integrity verification

- [x] **`configs/pnpm-workspace-secure.yaml`** - pnpm security ✅ Added
  - [x] Lifecycle script restrictions

### Output Formats

- [x] Plain text with colors
- [ ] **JSON output** (`--format json`)
- [ ] **SARIF output** (`--format sarif`)
  - [ ] GitHub Security tab integration
  - [ ] CodeQL compatibility
- [ ] **Markdown report** (`--format md`)
- [ ] **HTML report** (`--format html`)

---

## 🔧 Tooling

### CLI Improvements

- [x] **npx support** - `npx hulud scan .`
  - [x] `bin/cli.js` entry point
  - [x] `package.json` bin field
  - [x] Cross-platform compatibility

- [ ] **Interactive mode** - Guided remediation
  - [ ] Step-by-step wizard
  - [ ] Confirmation prompts for destructive actions

- [ ] **Whitelist/Ignore** functionality
  - [ ] `--ignore <package>` flag
  - [ ] `.shyhulud-ignore` file support
  - [ ] False positive reporting

### Containerization

- [ ] **Dockerfile** - Isolated scanning environment
  ```dockerfile
  FROM node:lts-alpine
  WORKDIR /scan
  COPY . /tool
  ENTRYPOINT ["dont-be-shy-hulud", "scan", "/target"]
  ```
  - [ ] Multi-arch support (amd64, arm64)
  - [ ] Minimal attack surface
  - [ ] Volume mounting for target directories

- [ ] **Docker Compose** - Full scanning stack
  - [ ] Scanner service
  - [ ] Results database
  - [ ] Web dashboard (future)

### IDE Integration

- [x] VS Code tasks (`tasks.json`)
- [x] VS Code workspace settings
- [ ] **VS Code extension** (future)
  - [ ] Real-time scanning
  - [ ] Inline warnings
  - [ ] Quick fixes

### Monitoring & Alerting

- [ ] **Webhook integration**
  - [ ] Slack notifications
  - [ ] Discord notifications
  - [ ] Microsoft Teams
  - [ ] Generic webhook endpoint

- [ ] **GitHub App** (future)
  - [ ] Automatic PR scanning
  - [ ] Org-wide monitoring
  - [ ] Scheduled audits

---

## 🌐 Community & Ecosystem

### Project Infrastructure

- [x] MIT License
- [x] Code of Conduct
- [x] Contributing guidelines
- [x] Security policy
- [x] Issue templates
- [x] PR template
- [ ] **GitHub Discussions** - Enable and set up categories
- [ ] **GitHub Sponsors** - Funding tiers
- [ ] **Open Collective** - Alternative funding

### Content & Outreach

- [ ] **Article Series** (5-part plan)
  - [ ] Part 1: Overview & Timeline
  - [ ] Part 2: Technical Deep-Dive
  - [ ] Part 3: Hands-on Remediation
  - [ ] Part 4: Prevention & Hardening
  - [ ] Part 5: Tools & Automation

- [ ] **Blog posts**
  - [ ] dev.to
  - [ ] Hashnode
  - [ ] Medium

- [ ] **Social media**
  - [ ] Twitter/X announcement
  - [ ] LinkedIn post
  - [ ] Reddit (r/javascript, r/node, r/netsec)
  - [ ] Hacker News

### Integrations

- [ ] **Socket.dev** - Official integration guide
- [ ] **Snyk** - Policy templates
- [ ] **Dependabot** - Alert correlation
- [ ] **GitHub Advisory Database** - CVE submissions (if applicable)

### Recognition

- [x] Credits section in README
- [ ] Contributors page
- [ ] Security researchers acknowledgment
- [ ] Vendor attribution (Datadog, Wiz, SafeDep, etc.)

---

## 🚨 Critical Security Notes

### Dead Man's Switch Warning

> ⚠️ **CRITICAL**: The Shai-Hulud 2.0 malware contains a destructive "dead man's switch". If exfiltration or propagation fails, it attempts to **wipe the entire `$HOME` directory**.

**Safe Handling Procedures:**

1. **DO NOT** kill malicious processes with `SIGKILL` or `SIGTERM`
2. **DO** use `SIGSTOP` to freeze processes first
3. **DO** create snapshots/backups before any action
4. **DO NOT** disconnect network until process is frozen
5. **DO** have recovery plan ready

### Testing Recommendations

For contributors testing detection capabilities:

| Method                    | Safety Level | Notes                    |
| ------------------------- | ------------ | ------------------------ |
| VM (UTM/Parallels/VMware) | ✅ Safest     | Full isolation           |
| Docker container          | ✅ Safe       | Good for script testing  |
| Separate user account     | ⚠️ Partial    | `$HOME` still at risk    |
| Production machine        | ❌ Dangerous  | Never test on production |

**Always:**
- Have Time Machine / backup ready
- Test in isolated environment first
- Review scripts before running

---

## 📅 Release Milestones

### v1.5.0 (Released)
- [x] SIGSTOP suspend script
- [x] Expanded IOC database (100+ packages)
- [x] Network IOCs
- [x] File hash verification
- [ ] Stack-specific docs (at least 2)

### v1.2.0
- [ ] Full IOC database (500+ packages)
- [ ] JSON/SARIF output
- [ ] GitHub API scanner
- [ ] Automated IOC updates

### v1.3.0
- [ ] npx support
- [ ] Docker image
- [ ] Webhook notifications
- [ ] Interactive mode

### v2.0.0 (Future)
- [ ] GitHub App
- [ ] Web dashboard
- [ ] VS Code extension
- [ ] Enterprise features

---

## 🤝 How to Contribute

1. **Pick an unchecked item** from this roadmap
2. **Open an issue** to discuss approach (optional but recommended)
3. **Fork and implement**
4. **Submit PR** with reference to roadmap item
5. **Get reviewed and merged**

### Good First Issues

Look for items marked with low effort:
- Documentation improvements
- Translation help
- IOC list expansion (manual research)
- Config template creation

### High Impact Contributions

- SIGSTOP suspend script
- GitHub API scanner
- SARIF output format
- Stack-specific documentation

---

## 📖 References & Sources

### Security Vendor Reports
- [Wiz - Shai-Hulud 2.0 Analysis](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)
- [Datadog - NPM Worm Technical Analysis](https://securitylabs.datadoghq.com/articles/shai-hulud-2-0-npm-worm/)
- [Check Point - The Second Coming](https://blog.checkpoint.com/research/shai-hulud-2-0-inside-the-second-coming/)
- [Unit 42 - Supply Chain Attack](https://unit42.paloaltonetworks.com/npm-supply-chain-attack/)
- [SafeDep - Technical Analysis](https://safedep.io/shai-hulud-second-coming-supply-chain-attack/)

### Official Advisories
- [CISA - Widespread Supply Chain Compromise](https://www.cisa.gov/news-events/alerts/2025/09/23/widespread-supply-chain-compromise-impacting-npm-ecosystem)
- [npm Security Advisory](https://github.blog/security/)

### Community Resources
- [Cobenian/shai-hulud-detect](https://github.com/Cobenian/shai-hulud-detect)
- [GrzechuG/compromised-npm-shai-hulud](https://github.com/GrzechuG/compromised-npm-shai-hulud)

---

<p align="center">
  <i>This roadmap is a living document. Last updated: 2025-12-02</i>
</p>
