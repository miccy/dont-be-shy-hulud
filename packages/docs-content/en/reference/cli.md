---
title: CLI Reference
description: Command-line interface reference for hulud
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# CLI Reference

> Complete reference for the `hulud` command-line tool

## Installation

```bash
# Run without installing
npx hulud <command>

# Or install globally
npm install -g dont-be-shy-hulud
```

## Commands

### `scan`

Scan a directory for Shai-Hulud 2.0 indicators.

```bash
hulud scan [path] [options]
```

**Arguments:**
- `path` — Directory to scan (default: current directory)

**Options:**
- `--deep` — Deep scan including node_modules
- `--json` — Output results as JSON
- `--quiet` — Suppress progress output

**Examples:**
```bash
# Scan current directory
hulud scan

# Scan specific path
hulud scan ~/Developer/my-project

# Deep scan with JSON output
hulud scan --deep --json > results.json
```

### `audit`

Run a comprehensive security audit.

```bash
hulud audit [options]
```

**Options:**
- `--full` — Full audit including network checks
- `--quick` — Quick audit (files only)

**Examples:**
```bash
# Quick audit
hulud audit --quick

# Full audit
hulud audit --full
```

### `harden`

Apply security hardening to npm configuration.

```bash
hulud harden [options]
```

**Options:**
- `--dry-run` — Show changes without applying
- `--force` — Overwrite existing configuration

**Examples:**
```bash
# Preview changes
hulud harden --dry-run

# Apply hardening
hulud harden
```

### `check`

Check a specific package for known compromises.

```bash
hulud check <package> [version]
```

**Examples:**
```bash
# Check package
hulud check posthog-js

# Check specific version
hulud check posthog-js 1.57.2
```

## Exit Codes

| Code | Meaning           |
| ---- | ----------------- |
| 0    | No issues found   |
| 1    | IOCs detected     |
| 2    | Error during scan |

## Environment Variables

| Variable         | Description             |
| ---------------- | ----------------------- |
| `HULUD_NO_COLOR` | Disable colored output  |
| `HULUD_VERBOSE`  | Enable verbose logging  |
| `HULUD_IOC_URL`  | Custom IOC database URL |

## Configuration

Create `.huludrc.json` in your project:

```json
{
  "scan": {
    "exclude": ["node_modules", ".git"],
    "deep": false
  },
  "audit": {
    "level": "moderate"
  }
}
```
