# macOS Security Audit Guide

> Comprehensive audit for macOS developer machines after supply chain attacks

## Quick Audit Script

Save and run:

```bash
#!/bin/bash
# macos-audit.sh

echo "🔍 macOS Developer Security Audit"
echo "=================================="
echo ""

# 1. Check for IOC files
echo "1. Checking for Shai-Hulud IOC files..."
find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
find ~ -name ".truffler-cache" -type d 2>/dev/null

# 2. Check running processes
echo ""
echo "2. Suspicious processes..."
ps aux | grep -E "(bun|truffler|hulud)" | grep -v grep

# 3. Check npm config
echo ""
echo "3. npm configuration..."
cat ~/.npmrc 2>/dev/null

# 4. Check for credentials
echo ""
echo "4. Credential files (exposure check)..."
ls -la ~/.npmrc ~/.aws/credentials ~/.azure 2>/dev/null

# 5. Check recent file modifications
echo ""
echo "5. Recently modified JS files in home..."
find ~ -name "*.js" -mtime -7 -type f 2>/dev/null | head -20

# 6. Check GitHub workflow files
echo ""
echo "6. Suspicious GitHub workflows..."
find ~ -path "*/.github/workflows/*" -name "*.yml" -exec grep -l "SHA1HULUD\|self-hosted\|discussion:" {} \; 2>/dev/null

echo ""
echo "Audit complete."
```

---

## Detailed Audit Steps

### 1. System Integrity

```bash
# Check SIP status
csrutil status

# Check for unauthorized kernel extensions
kextstat | grep -v com.apple

# Check for launch agents/daemons
ls -la ~/Library/LaunchAgents/
ls -la /Library/LaunchAgents/
ls -la /Library/LaunchDaemons/
```

### 2. Process Monitoring

```bash
# Real-time process monitoring
sudo fs_usage -w

# Check open network connections
lsof -i -P | grep -E "(node|bun|npm)"

# Check for unusual outbound connections
netstat -an | grep ESTABLISHED
```

### 3. npm/Node Audit

```bash
# Check npm config
npm config list

# Check for global packages
npm list -g --depth=0
bun pm ls -g

# Check npm cache integrity
npm cache verify

# List npm tokens (if any stored)
cat ~/.npmrc | grep -E "^//.*:_authToken"

# Check npm cache location
npm config get cache
ls -la $(npm config get cache)
```

### 4. Bun Audit

```bash
# Bun version
bun --version

# Bun install location
which bun

# Bun global packages
bun pm ls -g

# Check bun cache
ls -la ~/.bun/install/cache/

# Unexpected bun installations
find ~ -name "bun" -type f -executable 2>/dev/null
```

### 5. Git/GitHub Audit

```bash
# Check git config
git config --global --list

# Check for credential helpers
git config --global credential.helper

# Check SSH keys
ls -la ~/.ssh/

# Check known_hosts for unexpected entries
cat ~/.ssh/known_hosts

# Check git hooks in repos
find ~ -path "*/.git/hooks/*" -type f -executable 2>/dev/null
```

### 6. Credential Files

```bash
# AWS credentials
cat ~/.aws/credentials 2>/dev/null
cat ~/.aws/config 2>/dev/null

# Azure credentials
ls -la ~/.azure/ 2>/dev/null

# GCP credentials
ls -la ~/.config/gcloud/ 2>/dev/null
cat ~/.config/gcloud/application_default_credentials.json 2>/dev/null

# Docker credentials
cat ~/.docker/config.json 2>/dev/null
```

### 7. Browser/Keychain

```bash
# Check for suspicious keychain entries (manual)
# Open: Keychain Access.app
# Search for: npm, github, aws, azure, gcloud

# Check for browser extensions (manual)
# Review in each browser's extension settings
```

### 8. Network Configuration

```bash
# Check DNS configuration
scutil --dns

# Check hosts file
cat /etc/hosts

# Check for proxy settings
networksetup -getwebproxy "Wi-Fi"
networksetup -getsecurewebproxy "Wi-Fi"

# Check firewall status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

---

## Intego-Specific Checks

Based on your Intego installation:

### VirusBarrier (10.9.101)

```
# Run full system scan:
# Open VirusBarrier → Scan → Full Scan

# Check quarantine:
# VirusBarrier → Quarantine

# Update definitions:
# VirusBarrier → Update
```

### NetBarrier (10.9.38)

```
# Check firewall rules:
# NetBarrier → Rules

# Recommended rules:
# - Block all incoming by default
# - Allow specific apps outbound
# - Monitor node/bun/npm network activity
```

### Limitations

⚠️ **Intego may not detect Shai-Hulud because:**

1. It's JavaScript-based, not a traditional binary
2. Uses heavy obfuscation (3x base64)
3. Operates within npm ecosystem
4. Installs Bun runtime to evade Node.js monitoring

**Better protection:**
- Socket.dev (you have Team plan ✅)
- npm audit
- Manual inspection of install scripts

---

## Automated Monitoring

### Create LaunchAgent for monitoring

```xml
<!-- ~/Library/LaunchAgents/com.user.npm-monitor.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.npm-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | while read f; do osascript -e 'display notification "Shai-Hulud IOC found!" with title "Security Alert"'; done</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.user.npm-monitor.plist
```

---

## Your System Analysis

Based on your reports:

### ✅ Good Signs

- macOS 26.1 (Tahoe) - latest
- Homebrew up to date
- npm doctor shows OK
- No npm global packages (using bun)
- Rust toolchain clean
- Docker running normally

### ⚠️ Check These

1. **1873 bun global packages** - that's a lot, audit for compromised ones:
   ```bash
   bun pm ls -g | grep -E "(posthog|zapier|asyncapi|postman|ensdomains)"
   ```

2. **Broken PATH entry**:
   ```
   /Users/miccy/Library/Android/sdk/platform-tools/Users/miccy/Library/Android/sdk/tools/bin
   ```
   Fix in your `.zshrc`

3. **Non-existent PATH directories**:
   - `/opt/pmk/env/global/bin`
   
   Clean these up

### 🔍 Recommended Checks

```bash
# Check your bun global packages against IOC list
bun pm ls -g | grep -iE "(posthog|zapier|asyncapi|postman|ensdomains|angulartics|koa2-swagger)"

# Check credentials
ls -la ~/.npmrc ~/.aws/credentials

# Check for IOC files
find ~/Developer -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
```

---

## Recovery Steps (if compromised)

1. **Backup important data** (exclude node_modules)
2. **Rotate ALL credentials** (see remediation.md)
3. **Clean install recommended** for severe cases
4. **Reinstall developer tools** from official sources
5. **Regenerate SSH/GPG keys**
6. **Enable 2FA everywhere**

---

## Prevention

### .npmrc (Global)

```bash
echo "ignore-scripts=true" >> ~/.npmrc
echo "audit=true" >> ~/.npmrc
```

### Git hooks

```bash
# In each repo, add pre-commit check
cat << 'EOF' > .git/hooks/pre-commit
#!/bin/bash
# Check for IOC files before commit
if find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
    echo "❌ IOC files detected! Aborting commit."
    exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

---

## Tools

| Tool | Purpose | Link |
|------|---------|------|
| Socket.dev | npm security scanning | https://socket.dev |
| Snyk | Dependency scanning | https://snyk.io |
| npm-audit | Built-in npm audit | `npm audit` |
| osquery | System monitoring | https://osquery.io |
| BlockBlock | Persistence monitoring | https://objective-see.org/products/blockblock.html |
| LuLu | Firewall | https://objective-see.org/products/lulu.html |
