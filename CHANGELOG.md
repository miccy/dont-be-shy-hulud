# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2025-12-02

### Added
- **ROADMAP.md** - Comprehensive project roadmap with nested checkboxes based on multi-model AI security audits (Claude Opus 4.5, GPT-5.1-Pro, Grok-4.1, Perplexity, Proton-Lumo, Gemini-3-Pro)
- **cs/ROADMAP.md** - Czech translation of the roadmap
- Roadmap section in README.md (EN) with link to ROADMAP.md
- Roadmapa section in cs/README.md (CZ) with link to ROADMAP.md
- Multi-model security audit documentation in AGENTS.md
- Critical security context section in AGENTS.md (Dead Man's Switch warning, attack characteristics)
- Research findings reference in AGENTS.md (`.agents/research/` directory)
- **scripts/suspend-malware.sh** - Safe process suspension using SIGSTOP (prevents wiper trigger)
  - Auto-detection of malicious processes by known signatures
  - `--dry-run` mode for safe testing
  - `--resume` mode to unfreeze processes after backup
  - State file tracking of suspended PIDs
  - Interactive and auto modes
- **ioc/network.json** - Network Indicators of Compromise
  - C2 domain monitoring (suspected domains)
  - Exfiltration webhook patterns (webhook.site, pipedream, requestbin)
  - GitHub API abuse patterns and endpoints
  - Cloud metadata service abuse detection (169.254.169.254)
  - Firewall rule recommendations for CI/CD
  - SIEM/IDS detection queries
- **`.github/workflows/socket-security.yml`** - Socket.dev GitHub Actions integration
- **`socket.yml`** - Root-level Socket.dev configuration for GitHub App

### Changed
- Updated attack metrics: 796 → 800+ packages, added 1,200+ organizations impacted
- Updated Contributing/Priority Areas section in both READMEs to reference ROADMAP.md
- Updated repository structure in AGENTS.md to reflect current layout
- Updated task priorities in AGENTS.md to include roadmap items
- Updated project status in `AGENTS.md`, `README.md`, `cs/README.md`, and `ROADMAP.md` to 2025-12-02
- Updated Roadmap progress (Core Detection 85%, IOC Database 60%)
- Marked v1.5.0 as released in Roadmap
- Updated ROADMAP progress: Core Detection 70%→75%, IOC Database 30%→45%
- **ioc/malicious-packages.json** - Updated statistics with credential exfiltration counts (775+ GitHub, 373+ AWS, 300+ GCP, 115+ Azure)

### Fixed
- False positives in `scripts/detect.sh` where documentation files triggered cloud metadata abuse detection
- False positives in `scripts/detect.sh` where documentation files triggered secondary phase indicator detection
- Downgraded "Bun detected" warning to INFO in `scripts/detect.sh` to prevent CI failure
- Fixed `socket-security.yml` CI failure by skipping scan when `SOCKET_SECURITY_API_KEY` is missing
- Fixed ShellCheck warning in `scripts/suspend-malware.sh` (unused `VERBOSE` variable)
- Fixed false positive where `CHANGELOG.md` triggered detection by explicitly excluding it in `scripts/detect.sh`

## [1.4.1] - 2025-12-01

### Fixed
- Removed `lockfile-lint` step from release workflow as it is incompatible with pnpm lockfiles

## [1.4.0] - 2025-11-30

### Changed
- Updated `packageManager` to `pnpm@10.24.0`

### Fixed
- Added `pnpm-lock.yaml` to ensure consistent dependency installation in CI
- Improved `scripts/release.sh` to insert comparison links at the top of the list
- Fixed `scripts/release.sh` to include `package.json` in the release commit
- Fixed `scripts/release.sh` to correctly rename `[Unreleased]` section and append comparison links

## [1.3.4] - 2025-11-30

### Added
- Community section to README.md (EN) with links to Discussions, Issues, Security advisories
- Komunita section to cs/README.md (CZ)
- Shared Renovate preset reference (`github>miccy/renovate-config`) in both READMEs
- Updated `scripts/sync-version.sh` to automatically synchronize version in `package.json`
- Updated `scripts/release.sh` to automatically append version comparison links to `CHANGELOG.md`
- **New badge**: GitHub Release version badge (dynamic)

### Changed
- License badge: Yellow → Green, now links to LICENSE file
- PRs Welcome badge: Now links to CONTRIBUTING.md instead of external site
- Removed static Security Advisories badge (redundant with Community section)
- Improved `scripts/release.sh` editor fallback to avoid unexpected terminal editors

### Fixed
- Removed duplicate `drafts: false` line in `.coderabbit.yaml`
- Removed duplicate `[1.0.0]` link in CHANGELOG.md
- Added missing `[1.3.2]` and `[1.3.3]` links in CHANGELOG.md
- Removed duplicate comments (`# Config`, `# Parse arguments`, trap comment) in `scripts/detect.sh`
- Corrected `.coderabbit.yaml` nesting for `tools` and `auto_title_instructions`

## [1.3.3] - 2025-11-30

### Added
- Community sections to English and Czech READMEs
- Shared Renovate configuration preset documentation in READMEs
- Automated release notes extraction from `CHANGELOG.md` in `release.yml`
- Enhanced CodeRabbit configuration with linters (ShellCheck, Markdownlint, etc.) and Conventional Commits enforcement
- Enabled CodeRabbit `request_changes_workflow` for automatic approval upon issue resolution

### Changed
- Updated `scripts/release.sh` to support releases from `*-dev` branches (e.g., `claude-dev`, `gemini-dev`)
- Enhanced `scripts/detect.sh` output handling for CI environments (pre-creates files, ensures artifact upload)
- Updated release script instructions to reflect the automated release process
- Updated `docs/RELEASE_WORKFLOW.md` and `cs/docs/RELEASE_WORKFLOW.md` to reflect `*-dev` branch support

### Fixed
- Cleaned up `.coderabbit.yaml` configuration
- Corrected nesting of `tools` and `auto_title_instructions` in `.coderabbit.yaml`

## [1.3.2] - 2025-11-30

### Added
- pnpm support steps to `release.yml` workflow
- `recommended_action` field to IOC timeline
- `--github-check` flag to `scripts/detect.sh` (opt-in)
- Fallback `results.txt` generation in `scripts/detect.sh` to ensure artifact upload
- Standardized project structure with `package.json` and `pnpm-lock.yaml` for tooling support
- Automated detection script documentation in `docs/DETECTION.md` and `cs/docs/DETECTION.md`

### Changed
- Standardized `affected_versions` in `ioc/malicious-packages.json`
- Improved editor detection in `scripts/release.sh` (nano, vim, vi)
- Refined `scripts/detect.sh` to exclude documentation and IOC files from self-detection (False Positives)
- Improved `release.yml` version extraction with error handling
- Fixed `detect.sh` argument parsing to support space-separated flags (e.g., `--output results.txt`)

### Fixed
- Markdown linting issues in READMEs and documentation
- Unbound variable in `scripts/check-github-repos.sh`
- Duplicate step in `release.yml`
- False positives in `scripts/detect.sh` where `CHANGELOG.md` itself was flagged for containing IOC patterns
- Fixed CI workflow `supply-chain-security.yml` to use local `detect.sh` script instead of downloading from `main` branch, ensuring latest fixes are tested in documentation
- CodeRabbit configuration errors in `.coderabbit.yaml`

## [1.3.1] - 2025-11-30

### Added
- Release workflow documentation and script for this repository
- CodeRabbit PR Reviews badge to READMEs
- Automated changelog injection into Pull Request descriptions
- New GitHub Action `pr-changelog.yml`
- Enabled CodeRabbit auto-approval for clean PRs
- Portable hash detection in `scripts/detect.sh` (macOS support)
- `--skip-hash` flag to `scripts/detect.sh`

### Changed
- Updated all repository URLs from `hunting-worms-guide` to `dont-be-shy-hulud`
- Updated `softprops/action-gh-release` to v2.4.2

### Fixed
- Syntax error in `release.yml` workflow (nested mapping issue)
- Typo in `release.yml` (`head_commit_message` -> `head_commit.message`)
- Unbound variable error in `scripts/quick-audit.sh` (set -u compatibility)
- Unbound variable error in `scripts/full-audit.sh` (set -u compatibility)
- False positive Bun detection in `scripts/detect.sh` (ignoring `node_modules`)
- `find` command compatibility issues on macOS in `scripts/detect.sh`

## [1.3.0] - 2025-11-30

### Added
- **CRITICAL**: Dead Man's Switch warning section in README (EN/CS)
- **URGENT**: npm Token Migration Deadline section (December 9, 2025)
- Hash-based IOC detection in detect.sh (3 known SHA256 hashes)
- Secondary phase detection ("Continued Coming" patterns)
- Cloud metadata service abuse detection (169.254.169.254)
- Bun-specific security checks in detect.sh
- Automated GitHub CLI check for suspicious repos
- Network IOCs to malicious-packages.json
- Hardened GitHub Actions workflow (supply-chain-security.yml)
- Bun `.npmrc` bug documentation

### Changed
- **Timeline**: Corrected to 796 packages (not 700+), added UTC timestamps
- **IOC Database**: Extended with hash values, network indicators, secondary phase patterns
- **detect.sh**: Now has 12 detection sections (was 8)
- **Packages list**: Added ngx-bootstrap, tinycolor2 (corrected from tinycolor), @zapier/zapier-sdk versions
- Updated Czech README.md with all critical warnings

### Fixed
- Corrected package name: tinycolor2 (not tinycolor)
- Added missing @zapier/zapier-sdk version info (0.15.5-0.15.7)

---

## [1.2.0] - 2025-11-28

### Added
- Complete English translations for all documentation
- Complete Czech translations for all documentation
- Bilingual support (EN/CS) for all markdown documentation
- AGENTS.md and AGENTS-cs.md for AI assistant integration
- .agents/ directory with Claude MCP skills
- CHANGELOG.md for version tracking
- CONTRIBUTING-cs.md (Czech contribution guidelines)

### Changed
- Updated all repository URLs from `hunting-worms-guide` to `dont-be-shy-hulud`
- Standardized scripts to English-only comments (with i18n support planned)

### Fixed
- Fixed broken internal documentation links
- Corrected references to documentation paths
## [1.1.0] - 2025-11-28

### Added
- **CI/CD**: Added GitHub Actions workflow (`ci.yml`) for ShellCheck linting and smoke tests.
- **Automation**: Added `scripts/set-language.sh` to easily switch between English/Czech or keep both.
- **VS Code**: Added `.vscode/tasks.json` for easy script execution and `.vscode/extensions.json` recommendations.
- **Security**: Updated `THREAT-OVERVIEW.md` and `DETECTION.md` with new Shai-Hulud v2 findings (Privilege Escalation, Secondary Token Mining).
- **Scripts**: Added System Integrity Check to `full-audit.sh`.

### Changed
- **Restructuring**: Moved all Czech documentation to `cs/` directory for better organization.
- **Documentation**: Updated `README.md` and `cs/README.md` to reflect the new structure.
- **Robustness**: Improved `full-audit.sh` error handling for permission denied errors.


## [1.0.0] - 2025-11-28

### Added
- Initial repository merge
- Detection scripts for Shai-Hulud 2.0
- Security hardening guides
- IOC database
- Configuration templates (Renovate, Socket.dev, npm)

[1.5.0]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.3.4...v1.4.0
[1.3.4]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/miccy/dont-be-shy-hulud/releases/tag/v1.0.0
