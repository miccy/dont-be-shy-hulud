# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2025-11-30

### Added
- Release workflow documentation and script for this repository
- CodeRabbit PR Reviews badge to READMEs

### Changed
- Updated CodeRabbit PR Reviews badge to READMEs

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

[Unreleased]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.3.1...HEAD
[1.3.1]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/miccy/dont-be-shy-hulud/compare/v1.2.0...v1.3.0
[1.0.0]: https://github.com/miccy/dont-be-shy-hulud/releases/tag/v1.0.0
