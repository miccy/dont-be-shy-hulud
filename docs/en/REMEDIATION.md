# Remediation Guide

> Step-by-step guide to recover from Shai-Hulud 2.0 infection

## Severity Assessment

Before starting, assess your exposure:

| Indicator | Severity | Action |
|-----------|----------|--------|
| Found IOC files (setup_bun.js, etc.) | 🔴 Critical | Full incident response |
| Found compromised packages in lockfile | 🟠 High | Credential rotation + cleanup |
| Found suspicious workflows | 🔴 Critical | Immediate removal + audit |
| Only using packages from affected namespaces | 🟡 Medium | Verify versions + monitor |
| No indicators found | 🟢 Low | Preventive hardening |

---

## 🔴 Critical: Full Incident Response

### Step 1: Isolate

```bash
# Disconnect from network if possible
# Do NOT run any npm/bun commands

# Kill any suspicious processes
ps aux | grep -E "(bun|node|npm)" | grep -v grep
# Kill suspicious ones: kill -9 <PID>
```

### Step 2: Evidence Collection

Before cleanup, collect evidence:

```bash
# Create evidence directory
mkdir -p ~/evidence/shai-hulud-$(date +%Y%m%d)
cd ~/evidence/shai-hulud-$(date +%Y%m%d)

# Copy IOC files
find ~/ -name "setup_bun.js" -exec cp {} . \; 2>/dev/null
find ~/ -name "bun_environment.js" -exec cp {} . \; 2>/dev/null
find ~/ -name "actionsSecrets.json" -exec cp {} . \; 2>/dev/null

# Save process list
ps aux > processes.txt

# Save network connections
netstat -an > netstat.txt

# Save environment variables (careful - may contain secrets)
env > env.txt

# Copy suspicious workflows
find ~/ -path "*/.github/workflows/*" -name "formatter_*.yml" -exec cp {} . \; 2>/dev/null

# Screenshot GitHub repos (manual)
echo "Check: https://github.com/YOUR_USERNAME?tab=repositories"
echo "Look for repos with 'Sha1-Hulud' description"
```

### Step 3: Credential Rotation (CRITICAL)

**Do this immediately - assume all credentials are compromised:**

#### npm Tokens

```bash
# List all tokens
npm token ls

# Revoke ALL tokens
npm token ls --json | jq -r '.[].key' | xargs -I {} npm token revoke {}

# Or manually at: https://www.npmjs.com/settings/YOUR_USERNAME/tokens

# Generate new token (after cleanup)
npm token create --read-only  # For CI
npm token create              # For publishing (limit scope!)
```

#### GitHub Personal Access Tokens

1. Go to: https://github.com/settings/tokens
2. Delete ALL classic tokens
3. Review and delete fine-grained tokens
4. Generate new tokens with minimal scopes

#### SSH Keys

```bash
# List GitHub SSH keys
# Go to: https://github.com/settings/keys

# Generate new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Paste at: https://github.com/settings/ssh/new

# Remove old keys from GitHub
```

#### Cloud Credentials

**AWS:**
```bash
# Rotate access keys
aws iam create-access-key --user-name YOUR_USER
aws iam delete-access-key --user-name YOUR_USER --access-key-id OLD_KEY_ID

# Or use AWS Console: IAM → Users → Security credentials
```

**GCP:**
```bash
# Revoke service account keys
gcloud iam service-accounts keys list --iam-account=YOUR_SA
gcloud iam service-accounts keys delete KEY_ID --iam-account=YOUR_SA

# Create new key
gcloud iam service-accounts keys create ~/new-key.json --iam-account=YOUR_SA
```

**Azure:**
```bash
# Rotate app credentials via Azure Portal
# Azure AD → App registrations → Your app → Certificates & secrets
```

### Step 4: Cleanup

```bash
# Remove malicious files
find ~/ -name "setup_bun.js" -delete 2>/dev/null
find ~/ -name "bun_environment.js" -delete 2>/dev/null
find ~/ -name "actionsSecrets.json" -delete 2>/dev/null
find ~/ -name ".truffler-cache" -type d -exec rm -rf {} \; 2>/dev/null

# Remove suspicious workflows
find ~/ -path "*/.github/workflows/formatter_*.yml" -delete 2>/dev/null

# Clear all caches
rm -rf ~/.npm/_cacache
rm -rf ~/.bun/install/cache
npm cache clean --force
bun pm cache rm

# Remove all node_modules
find ~/ -name "node_modules" -type d -prune -exec rm -rf {} \; 2>/dev/null
```

### Step 5: Check GitHub Repos

```bash
# Search for malicious repos on your account
# https://github.com/YOUR_USERNAME?tab=repositories

# Look for:
# - Repos with description "Sha1-Hulud: The Second Coming"
# - Repos with "-migration" suffix you didn't create
# - Repos with random alphanumeric names

# Delete any suspicious repos
```

### Step 6: Reinstall Dependencies

```bash
# For each project:
cd /path/to/project

# Remove old lockfile
rm -rf node_modules package-lock.json bun.lockb yarn.lock pnpm-lock.yaml

# Configure npm to ignore scripts
echo "ignore-scripts=true" >> .npmrc

# Reinstall with scripts disabled
npm install --ignore-scripts
# or
bun install --no-save

# Verify
npm audit
./scripts/detect.sh .
```

---

## 🟠 High: Credential Rotation + Cleanup

If you found compromised packages but no active IOC files:

### Step 1: Identify Affected Versions

```bash
# Check lockfile for exact versions
grep -E "(posthog|zapier|asyncapi|postman|ensdomains)" package-lock.json

# Check version dates - anything after Nov 21, 2025 is suspect
npm view PACKAGE_NAME time
```

### Step 2: Roll Back to Clean Versions

```bash
# Example for posthog-node
npm install posthog-node@2.6.0  # Version before Nov 21, 2025

# Regenerate lockfile
rm package-lock.json
npm install --ignore-scripts
```

### Step 3: Rotate Credentials (as above)

Even if not actively compromised, assume exposure.

---

## 🟡 Medium: Version Verification

### Check Package Versions

```bash
# For each suspicious package:
npm view PACKAGE_NAME versions --json

# Check publish dates:
npm view PACKAGE_NAME time
```

### Safe Versions (pre-Nov 21, 2025)

| Package | Last Known Clean Version |
|---------|-------------------------|
| `posthog-node` | ≤ 4.17.0 |
| `posthog-js` | ≤ 1.180.0 |
| `@asyncapi/specs` | ≤ 6.8.1 |
| `@postman/tunnel-agent` | ≤ 0.6.0 |
| `zapier-platform-core` | ≤ 15.0.0 |

*Note: Verify exact safe versions against official advisories*

---

## 🟢 Low: Preventive Hardening

### Configure npm

```bash
# ~/.npmrc
ignore-scripts=true
audit=true
fund=false
loglevel=notice
```

### Update Renovate Config

See [configs/renovate-secure.json](../configs/renovate-secure.json)

### Enable Socket.dev

See [configs/socket.yml](../configs/socket.yml)

### GitHub Hardening

See [github-hardening.md](github-hardening.md)

---

## Post-Incident

### Monitor

```bash
# Set up monitoring for:
# 1. New repos created on your GitHub account
# 2. npm package publishes under your account
# 3. Unusual CI/CD activity

# Check for new repos weekly:
# https://github.com/YOUR_USERNAME?tab=repositories&sort=updated
```

### Report

If you were compromised:

1. Report to npm security: security@npmjs.com
2. Report to GitHub: https://github.com/security
3. Report to CISA if US-based: https://www.cisa.gov/report
4. Consider notifying downstream users of your packages

### Learn

- Review CI/CD security practices
- Implement least-privilege for tokens
- Set up dependency monitoring
- Consider code signing for packages

---

## Emergency Contacts

| Organization | Contact |
|-------------|---------|
| npm Security | security@npmjs.com |
| GitHub Security | https://github.com/security |
| Socket.dev | support@socket.dev |
| CISA (US) | https://www.cisa.gov/report |

---

## FAQ

**Q: Should I delete my .npmrc?**
A: No, but rotate any tokens stored there and re-authenticate.

**Q: Can the malware persist after cleanup?**
A: The GitHub Actions backdoor can persist. Check all workflows carefully.

**Q: Is my data already leaked?**
A: If IOC files were present, assume yes. Check GitHub for repos with "Sha1-Hulud" description.

**Q: Should I notify my team/company?**
A: Yes, especially if you have shared CI/CD infrastructure or npm org access.
