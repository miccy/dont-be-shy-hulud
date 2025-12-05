---
title: Credential Rotation
description: How to rotate all potentially compromised credentials
sidebar:
  order: 2
  badge:
    text: Critical
    variant: danger
lastUpdated: 2025-12-05
---

# Credential Rotation

> Rotate ALL credentials that may have been exposed to Shai-Hulud 2.0

## ⚠️ Critical Warning

Shai-Hulud 2.0 harvests credentials from:
- `~/.npmrc` (npm tokens)
- `~/.netrc` (GitHub tokens)
- Environment variables (AWS, GCP, Azure keys)
- GitHub Actions secrets
- SSH keys

**Assume ALL credentials are compromised if you found IOC files.**

## npm Tokens

```bash
# 1. List all tokens
npm token list

# 2. Revoke ALL tokens
npm token revoke <token-id>
# Repeat for each token

# 3. Create new token with restrictions
npm token create --read-only --cidr=<your-ip>/32

# 4. Enable 2FA
npm profile enable-2fa auth-and-writes
```

## GitHub Tokens

### Personal Access Tokens

1. Go to https://github.com/settings/tokens
2. **Revoke ALL existing tokens**
3. Create new fine-grained tokens with:
   - Minimal repository access
   - Short expiration (30 days)
   - IP restrictions if possible

### SSH Keys

```bash
# 1. List SSH keys
ls -la ~/.ssh/

# 2. Generate new key
ssh-keygen -t ed25519 -C "your-email@example.com"

# 3. Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Paste at https://github.com/settings/ssh/new

# 4. Remove old keys from GitHub
# https://github.com/settings/keys
```

## Cloud Provider Credentials

### AWS

```bash
# 1. List access keys
aws iam list-access-keys

# 2. Create new key
aws iam create-access-key

# 3. Delete old key
aws iam delete-access-key --access-key-id <old-key-id>

# 4. Update ~/.aws/credentials
```

### GCP

```bash
# 1. List service account keys
gcloud iam service-accounts keys list --iam-account=<sa-email>

# 2. Create new key
gcloud iam service-accounts keys create new-key.json \
  --iam-account=<sa-email>

# 3. Delete old keys
gcloud iam service-accounts keys delete <key-id> \
  --iam-account=<sa-email>
```

### Azure

```bash
# 1. List service principals
az ad sp list --show-mine

# 2. Reset credentials
az ad sp credential reset --id <app-id>
```

## Environment Variables

```bash
# Check for exposed secrets
env | grep -iE "(token|key|secret|password|auth)"

# Update .env files
# Update CI/CD secrets
# Update deployment configs
```

## Verification Checklist

- [ ] npm tokens rotated
- [ ] GitHub PATs revoked and recreated
- [ ] SSH keys regenerated
- [ ] AWS credentials rotated
- [ ] GCP service account keys rotated
- [ ] Azure credentials reset
- [ ] CI/CD secrets updated
- [ ] .env files updated
- [ ] Team notified of credential changes
