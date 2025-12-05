---
title: System Cleanup
description: Remove malware artifacts and restore system integrity
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# System Cleanup

> Remove all Shai-Hulud 2.0 artifacts from your system

## ⚠️ Before Cleanup

1. **Collect evidence first** — See [Remediation Guide](/remediation/guide)
2. **Freeze processes** — Use SIGSTOP, not SIGKILL (dead man's switch!)
3. **Backup important data** — The malware may wipe $HOME if it can't exfiltrate

## Remove IOC Files

```bash
# Remove payload files
find ~ -name "setup_bun.js" -delete 2>/dev/null
find ~ -name "bun_environment.js" -delete 2>/dev/null

# Remove staging directory
rm -rf ~/.truffler-cache

# Remove exfiltrated data files
find ~ -name "actionsSecrets.json" -delete 2>/dev/null
find ~ -name "cloud.json" -delete 2>/dev/null
find ~ -name "npmrc.json" -delete 2>/dev/null
```

## Remove Malicious Bun Installation

```bash
# Check if Bun was installed by malware
if [ -d ~/.bun ] && [ -f ~/.bun/bin/bun ]; then
  # Check installation date
  stat ~/.bun/bin/bun

  # If suspicious, remove
  rm -rf ~/.bun
  rm -rf ~/.dev-env
fi

# Remove from PATH
# Edit ~/.zshrc or ~/.bashrc and remove Bun paths
```

## Clean npm Cache

```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules in affected projects
find ~/Developer -name "node_modules" -type d -prune -exec rm -rf {} \;

# Reinstall with ignore-scripts
npm ci --ignore-scripts
```

## Remove Malicious GitHub Workflows

```bash
# Find and remove discussion.yaml
find ~/Developer -path "*/.github/workflows/discussion.yaml" -delete
find ~/Developer -path "*/.github/workflows/discussion.yml" -delete

# Check for other suspicious workflows
find ~/Developer -path "*/.github/workflows/*.yaml" -exec grep -l "curl\|wget" {} \;
```

## Clean GitHub Repositories

```bash
# List repos with suspicious description
gh repo list --json name,description | \
  jq '.[] | select(.description | contains("Hulud"))'

# Delete malicious repos (CAREFUL!)
# gh repo delete <repo-name> --yes
```

## Verify Cleanup

```bash
# Run detection again
npx hulud scan ~

# Check for remaining IOCs
find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
find ~ -name ".truffler-cache" -type d 2>/dev/null

# Check processes
ps aux | grep -E "(bun|truffler|hulud)" | grep -v grep
```

## Post-Cleanup Checklist

- [ ] All IOC files removed
- [ ] Malicious Bun installation removed
- [ ] npm cache cleared
- [ ] node_modules reinstalled cleanly
- [ ] Malicious workflows removed
- [ ] GitHub repos cleaned
- [ ] Detection scan passes
- [ ] Credentials rotated (see [Credential Rotation](/remediation/credentials))
