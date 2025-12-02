# AI Assistants Guide

> Guidelines for AI assistants working with this repository

## Project Overview

**Don't Be Shy, Hulud** is an incident response and protection guide for npm supply chain attacks, specifically targeting the Shai-Hulud 2.0 worm (November 2025) and similar threats.

### Repository Purpose

This repository provides:
- Detection scripts for supply chain malware
- Remediation workflows
- Prevention best practices
- IOC (Indicators of Compromise) databases
- Security configuration templates

### Target Audience

- JavaScript/TypeScript developers
- DevOps engineers
- Security teams
- Organizations using npm/bun ecosystem

### Current Status

**Version**: 1.5.0 (stable)
**Roadmap**: See [ROADMAP.md](ROADMAP.md) for detailed progress tracking

**Key Metrics (as of 2025-12-02):**
- 800+ compromised npm packages
- 25,000+ affected GitHub repositories
- 1,200+ impacted organizations
- 20M+ weekly downloads affected

### Multi-Model Security Audit

This project has been audited by multiple AI models for comprehensive security analysis:
- **Claude Opus 4.5** (Deep Research + Repo Audit + Roadmap Synthesis)
- GPT-5.1-Pro (Deep Research + Repo Audit)
- Grok-4.1 (Deep Research + 2× Repo Audit)
- Perplexity (Deep Research + Repo Audit)
- Proton-Lumo (Deep Research + Repo Audit)
- Gemini-3-Pro (Audit + Deep Research + Review Roadmap)

Audit findings are stored in `.agents/research/` and have been synthesized into the [ROADMAP.md](ROADMAP.md).

## Repository Structure

```
dont-be-shy-hulud/
├── docs/                # English documentation
├── cs/                  # Czech documentation (translations)
│   ├── docs/            # Czech docs
│   └── README.md        # Czech README
├── scripts/             # Detection and audit scripts
├── configs/             # Security configuration templates
├── ioc/                 # Indicators of Compromise databases
├── .agents/             # AI assistant tools and workflows
│   ├── research/        # Multi-model audit findings
│   └── skills/          # MCP skills for AI assistants
├── ROADMAP.md           # Detailed project roadmap with checkboxes
├── CHANGELOG.md         # Version history
└── README.md            # Main documentation
```

## Language Support

This repository is **bilingual (EN/CS)**:
- **Primary**: English (EN)
- **Secondary**: Czech (CS)

### Documentation Files
- All `.md` files in `docs/` have both EN and CS versions
- Root READMEs: `README.md` (EN), `cs/README.md` (CS)
- CONTRIBUTING: `CONTRIBUTING.md` (EN), `CONTRIBUTING-cs.md` (CS)

### Code Files
- Scripts (`.sh`): English comments only
- Configs (`.json`, `.yml`): English comments only
- Future: i18n support for script messages

## Technical Context

### Shai-Hulud 2.0 Attack

This malware is a self-propagating worm that:
1. Executes via `preinstall` lifecycle scripts
2. Harvests credentials (npm, GitHub, AWS, GCP, Azure)
3. Exfiltrates via GitHub repos
4. Self-propagates to victim's npm packages
5. Installs Bun runtime to evade detection

**Key IOC Files:**
- `setup_bun.js` - Loader
- `bun_environment.js` - Main payload (~500KB obfuscated)
- `.truffler-cache` directory
- GitHub repos with description: "Sha1-Hulud: The Second Coming"

### Detection Tools

Primary tools referenced:
- Socket.dev (supply-chain security)
- npm audit (built-in)
- Renovate (dependency updates)
- Snyk (vulnerability scanning)

## AI Assistant Guidelines

### When Helping Users

1. **Security First**: This is security-sensitive work. Be precise and thorough.

2. **Check Language Preference**:
   - If user writes in Czech, respond in Czech
   - If user writes in English, respond in English
   - Both languages should have feature parity

3. **Maintain Bilingual Consistency**:
   - When updating docs, update BOTH languages
   - Technical terms (CVE, IOC, etc.) stay in English in both versions
   - Code examples should be identical

4. **Script Modifications**:
   - Test scripts are safe before suggesting
   - Use shellcheck for validation
   - Consider macOS AND Linux compatibility

5. **Documentation Updates**:
   - Follow existing markdown style
   - Include code examples where applicable
6. **Changelog Updates**:
   - **ALWAYS** update `CHANGELOG.md` when making any changes (code, config, docs).
   - Use the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.
   - Add entries under the current `Unreleased` or active version section.

7. **Bilingual Documentation Rule**:
   - When modifying `README.md` or files in `docs/`, **YOU MUST** update the corresponding file in `cs/` or `cs/docs/`.
   - Keep the content synchronized (translation doesn't have to be word-for-word, but meaning must match).
   - If you change structure in one, change it in the other.

### Task Priorities

When making changes, prioritize in this order:

1. ✅ **Critical security updates** (new IOCs, vulnerability fixes)
2. ✅ **Roadmap P0 items** (SIGSTOP script, IOC expansion, network IOCs)
3. ✅ **Broken functionality** (scripts, links)
4. ✅ **Documentation accuracy** (outdated info)
5. ⚠️ **Roadmap P1 items** (stack-specific docs, automation)
6. ⚠️ **Enhancements** (new features, refactoring)
7. ℹ️ **Style/formatting** (cosmetic changes)

### Forbidden Actions

❌ **NEVER**:
- Auto-run security scripts without user confirmation
- Commit sensitive data (credentials, tokens)
- Modify IOC lists without verification
- Make breaking changes to public APIs (scripts interfaces)
- Remove safety checks from detection scripts

### Common Tasks

#### Adding a New IOC

1. Verify IOC from official source (Datadog, Wiz, Tenable, SafeDep)
2. Add to `ioc/malicious-packages.json`
3. Include: package name, affected versions, risk level, source URL
4. Update documentation if needed
5. Update CHANGELOG.md
6. Commit with message: `feat(ioc): add [package-name] IOC`

#### Implementing Roadmap Items

1. Check [ROADMAP.md](ROADMAP.md) for unchecked items
2. Create feature branch
3. Implement with tests where applicable
4. Update ROADMAP.md checkbox to `[x]`
5. Update CHANGELOG.md
6. Submit PR referencing roadmap item

#### Updating Documentation

1. Check if change affects both EN and CS
2. Update both versions
3. Verify all links still work
4. Commit with scope: `docs(en)` or `docs(cs)` or `docs(all)`

#### Adding Detection Logic

1. Add to appropriate script in `scripts/`
2. Test on macOS
3. Verify with shellcheck
4. Document in appropriate guide (DETECTION.md)
5. Update CHANGELOG.md

## Critical Security Context

### Dead Man's Switch Warning

> ⚠️ **CRITICAL**: Shai-Hulud 2.0 contains a destructive "dead man's switch". If the malware cannot exfiltrate data, it will **WIPE THE ENTIRE $HOME DIRECTORY**.

**Safe handling procedures:**
1. Use `SIGSTOP` (not `SIGKILL`) to freeze malicious processes
2. Create snapshots/backups BEFORE any remediation
3. Do NOT disconnect network until process is frozen
4. See `suspend-malware.sh` script (in development)

### Key Attack Characteristics

- **Execution**: `preinstall` phase (not postinstall)
- **Runtime**: Bun (evades Node.js monitoring)
- **Payload files**: `setup_bun.js`, `bun_environment.js`
- **Exfil method**: Public GitHub repos with description "Sha1-Hulud: The Second Coming"
- **Persistence**: GitHub Actions backdoor via `discussion.yaml`
- **C2 domains**: `shaihulud-c2.io`, `shai-hulud.net`

## Skills and Tools

Located in `.agents/skills/`:

- `shai-hulud-detector.json` - Detection automation
- `shai-hulud-remediation.json` - Remediation workflows

Research findings in `.agents/research/`:

- Multi-model audit reports (GPT, Grok, Perplexity, Lumo, Gemini)
- `Gemini-3-Pro-suspend_process.sh` - SIGSTOP-based process suspension
- `Gemini-3-Pro-renovate_defense.md` - Anti-worm Renovate config

See `.agents/README.md` for usage instructions.

## References

### External Documentation
- [npm Security Best Practices](https://docs.npmjs.com/packages-and-modules/securing-your-code)
- [Socket.dev Documentation](https://socket.dev/docs)
- [CISA Alert](https://www.cisa.gov/news-events/alerts/2025/09/23/widespread-supply-chain-compromise-impacting-npm-ecosystem)

### Vendor IOC Lists
- [Datadog IOCs](https://github.com/DataDog/indicators-of-compromise/tree/main/shai-hulud-2.0)
- [Tenable Package List](https://github.com/tenable/shai-hulud-second-coming-affected-packages)
- [Wiz Research](https://github.com/wiz-sec-public/wiz-research-iocs)

## Version Information

- **Repository**: https://github.com/miccy/dont-be-shy-hulud
- **License**: MIT
- **Maintainer**: @miccy
- **Status**: Active development (public release, seeking contributors)

---

**For AI Assistants**: When in doubt, ask the user. Security work requires collaboration and verification.
