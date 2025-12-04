# 🥟 Bun Security Guide

> **Why Bun is NOT safer — it's the attack vector!**

Shai-Hulud 2.0 specifically installs Bun runtime as an **evasion technique** because most security tools only monitor Node.js processes.

## ⚠️ Critical Warning

```
┌─────────────────────────────────────────────────────────────────┐
│  🚨 BUN IS USED BY SHAI-HULUD 2.0 TO EVADE DETECTION 🚨        │
│                                                                 │
│  The malware installs Bun to run its payload because:           │
│  • Most EDR/security tools don't monitor Bun processes          │
│  • Bun's .npmrc ignore-scripts=true is UNRELIABLE               │
│  • Bun has internal trustedDependencies that override configs   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔍 Detection

### Check for Unauthorized Bun Installations

```bash
# Check common Bun installation locations
ls -la ~/.bun 2>/dev/null
ls -la ~/.dev-env 2>/dev/null
ls -la /usr/local/bin/bun 2>/dev/null

# Check if Bun was installed recently (suspicious if you didn't install it)
stat ~/.bun/bin/bun 2>/dev/null | grep -E "(Birth|Change)"

# Check for Bun processes
ps aux | grep -i bun | grep -v grep

# Check for IOC files in Bun cache
find ~/.bun -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
```

### Check for Malicious Bun Activity

```bash
# Look for .truffler-cache (malware artifact)
ls -la ~/.truffler-cache 2>/dev/null

# Check for suspicious environment files
ls -la ~/.dev-env 2>/dev/null

# Check Bun's global cache for IOCs
find ~/.bun/install/cache -name "*.js" -exec grep -l "Sha1-Hulud\|Second Coming" {} \; 2>/dev/null
```

## 🛡️ Hardening

### The `.npmrc` Bug

**Bun has a known bug**: The `.npmrc` setting `ignore-scripts=true` does **NOT** work reliably!

Bun prioritizes its internal `trustedDependencies` allowlist over `.npmrc` settings.

```bash
# ❌ This is NOT reliable in Bun:
echo "ignore-scripts=true" >> .npmrc

# ✅ ALWAYS use CLI flag:
bun install --ignore-scripts
```

### Secure `bunfig.toml`

Create `bunfig.toml` in your project root:

```toml
[install]
# Disable lifecycle scripts (WARNING: may not be fully respected!)
ignoreScripts = true

# Use exact versions
exact = true

# Verify package integrity
verify = true

# Disable optional dependencies
optional = false

# Freeze lockfile
frozenLockfile = true

[install.lockfile]
# Save lockfile in binary format
saveBinaryLockfile = true
```

> **Note**: Even with this config, ALWAYS use `bun install --ignore-scripts`!

### CI/CD Configuration

```yaml
# GitHub Actions example
- name: Install dependencies (Bun)
  run: |
    # REQUIRED: Always use --ignore-scripts flag
    bun install --ignore-scripts --frozen-lockfile

    # Verify no IOC files were installed
    if find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
      echo "🚨 IOC files detected!"
      exit 1
    fi
```

## 🔒 Recommended Practices

### 1. Audit Bun Installation Source

```bash
# Check how Bun was installed
which bun
bun --version

# Verify Bun binary hash (get expected hash from bun.sh)
shasum -a 256 $(which bun)
```

### 2. Monitor Bun Processes

```bash
# Add to your monitoring/alerting
# Alert if Bun runs outside expected contexts

# Example: Log all Bun executions
alias bun='echo "[$(date)] bun $@" >> ~/.bun-audit.log && command bun "$@"'
```

### 3. Lock Down `trustedDependencies`

Bun has an internal allowlist. Check and audit it:

```bash
# View Bun's trusted dependencies (if exposed)
cat ~/.bun/install/trusted-dependencies.json 2>/dev/null
```

### 4. Use Bun Lockfile Inspection

```bash
# Check bun.lockb for suspicious packages
# Note: bun.lockb is binary, use bun to inspect
bun pm ls --all | grep -E "(posthog|@postman|@asyncapi|@zapier|@ensdomains)"
```

## 🚨 If You Suspect Compromise

### Immediate Actions

1. **DO NOT** kill Bun processes with `SIGKILL` (triggers wiper!)
2. **Freeze** the process first:
   ```bash
   # Find Bun PID
   pgrep -f bun

   # Freeze it (SIGSTOP)
   kill -STOP <PID>
   ```

3. **Backup** before any cleanup:
   ```bash
   # Create snapshot of home directory
   tar -czf ~/backup-$(date +%Y%m%d).tar.gz ~/ --exclude=backup-*.tar.gz
   ```

4. **Check for exfiltration**:
   ```bash
   # Search your GitHub for suspicious repos
   gh repo list --json name,description | jq '.[] | select(.description | contains("Hulud"))'
   ```

### Cleanup

```bash
# Remove Bun completely (after backup!)
rm -rf ~/.bun
rm -rf ~/.dev-env
rm -rf ~/.truffler-cache

# Remove from PATH
# Edit ~/.zshrc or ~/.bashrc and remove Bun paths

# Reinstall Bun from official source if needed
curl -fsSL https://bun.sh/install | bash
```

## 📚 Related Documentation

- [Main Detection Guide](../DETECTION.md)
- [Remediation Guide](../REMEDIATION.md)
- [bunfig-secure.toml template](../../configs/bunfig-secure.toml)
- [Threat Overview](../THREAT-OVERVIEW.md)

## 🔗 External Resources

- [Bun Official Documentation](https://bun.sh/docs)
- [Datadog Shai-Hulud Analysis](https://securitylabs.datadoghq.com/articles/shai-hulud-2.0-npm-worm/)
- [Wiz Research](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)

---

> ⚠️ **Remember**: Bun's speed comes with security trade-offs. In the context of Shai-Hulud 2.0, Bun is part of the attack chain, not a defense.
