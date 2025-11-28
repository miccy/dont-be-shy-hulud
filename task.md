# Implementation Plan: Unifying Repository Documentation

## 1. Documentation Unification & Translation
- [ ] Verify consistency between `docs/en` and `docs/cs`.
    - [x] `CASE-STUDY-SOCKET-ANALYSIS.md`
    - [x] `COMMON-ISSUES.md`
    - [x] `DETECTION.md`
    - [x] `GITHUB-HARDENING.md`
    - [x] `MACOS-AUDIT.md`
    - [x] `PREVENTION.md`
    - [x] `REMEDIATION.md`
    - [x] `THREAT-OVERVIEW.md`
- [ ] Verify consistency of root files.
    - [ ] `README.md` vs `README-cs.md`
    - [ ] `CONTRIBUTING.md` vs `CONTRIBUTING-cs.md`
    - [x] `AGENTS.md` vs `AGENTS-cs.md`
    - [x] `SECURITY.md` (Create CS version if missing)
    - [ ] `CHANGELOG.md` (Ensure bilingual or standard format)

## 2. Code Standardization (English-Only)
- [x] Translate scripts in `scripts/` to English.
    - [x] `detect.sh` (Already English)
    - [x] `check-github-repos.sh`
    - [x] `quick-audit.sh`
    - [x] `full-audit.sh`
    - [x] `harden-npm.sh`
- [x] Review configuration files in `configs/` for non-English comments.

## 3. AI Agent Capabilities
- [x] Verify `.agents` directory structure.
- [x] Implement missing skills mentioned in `.agents/README.md`.
    - [x] `skills/shai-hulud-detector.json`
    - [x] `skills/shai-hulud-remediation.json`

## 4. Public Release Preparation
- [x] Verify `LICENSE` file.
- [x] Check for hardcoded credentials or sensitive info.
- [x] Ensure all links are working and relative paths are correct.
