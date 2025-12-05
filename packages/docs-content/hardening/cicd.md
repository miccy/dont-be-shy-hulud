---
title: CI/CD Pipeline Security
description: Secure your CI/CD pipelines against supply chain attacks
sidebar:
  order: 4
lastUpdated: 2025-12-05
---

# CI/CD Pipeline Security

> Protect your build and deployment pipelines from supply chain attacks

## Key Principles

1. **Least Privilege** — CI jobs should have minimal permissions
2. **Pinned Dependencies** — Use exact versions and lockfiles
3. **Isolated Environments** — Separate build from deploy
4. **Audit Trails** — Log all actions for forensics

## GitHub Actions Security

See [GitHub Actions Hardening](/hardening/github-actions) for detailed configuration.

## General CI/CD Recommendations

### Dependency Installation

```yaml
# ✅ Good: Use lockfile, ignore scripts
- run: npm ci --ignore-scripts

# ❌ Bad: Allows arbitrary code execution
- run: npm install
```

### Environment Variables

```yaml
# ✅ Good: Use GitHub Secrets
env:
  NPM_TOKEN: ${{ secrets.NPM_TOKEN }}

# ❌ Bad: Hardcoded tokens
env:
  NPM_TOKEN: "npm_abc123..."
```

### Action Pinning

```yaml
# ✅ Good: Pin to SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11

# ⚠️ Acceptable: Pin to version
- uses: actions/checkout@v4

# ❌ Bad: Floating tag
- uses: actions/checkout@main
```

## Pipeline Isolation

```
┌─────────────────────────────────────────────────────────────┐
│  BUILD ENVIRONMENT (Low Trust)                               │
│  • Install dependencies                                      │
│  • Run tests                                                 │
│  • Build artifacts                                           │
│  • NO access to production secrets                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  DEPLOY ENVIRONMENT (High Trust)                             │
│  • Verify artifact signatures                                │
│  • Deploy to production                                      │
│  • Access to production secrets                              │
│  • Requires approval                                         │
└─────────────────────────────────────────────────────────────┘
```

## Monitoring

- Enable GitHub Advanced Security
- Use Socket.dev or Snyk in CI
- Set up alerts for failed security checks
- Review dependency updates before merging
