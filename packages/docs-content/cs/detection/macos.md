# macOS Security Audit Guide (Bezpečnostní audit)

> Komplexní audit macOS vývojářského stroje po supply chain útocích

## Rychlý audit skript

Uloz a spusť:

```bash
#!/bin/bash
# macos-audit.sh

echo "🔍 macOS Developer Security Audit"
echo "=================================="
echo ""

# 1. Kontrola IOC souborů
echo "1. Kontrola Shai-Hulud IOC souborů..."
find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
find ~ -name ".truffler-cache" -type d 2>/dev/null

# 2. Kontrola běžících procesů
echo ""
echo "2. Podezřelé procesy..."
ps aux | grep -E "(bun|truffler|hulud)" | grep -v grep

# 3. Kontrola npm konfigurace
echo ""
echo "3. npm konfigurace..."
cat ~/.npmrc 2>/dev/null

# 4. Kontrola credentials
echo ""
echo "4. Credential soubory (kontrola exposure)..."
ls -la ~/.npmrc ~/.aws/credentials ~/.azure 2>/dev/null

# 5. Kontrola nedávných změn souborů
echo ""
echo "5. Nedávno upravené JS soubory v home..."
find ~ -name "*.js" -mtime -7 -type f 2>/dev/null | head -20

# 6. Kontrola GitHub workflow souborů
echo ""
echo "6. Podezřelé GitHub workflows..."
find ~ -path "*/.github/workflows/*" -name "*.yml" -exec grep -l "SHA1HULUD\|self-hosted\|discussion:" {} \; 2>/dev/null

echo ""
echo "Audit dokončen."
```

---

## Detailní audit kroky

### 1. Integrita systému

```bash
# Kontrola SIP statusu
csrutil status

# Kontrola neoprávněných kernel extensions
kextstat | grep -v com.apple

# Kontrola launch agents/daemons
ls -la ~/Library/LaunchAgents/
ls -la /Library/LaunchAgents/
ls -la /Library/LaunchDaemons/
```

### 2. Monitoring procesů

```bash
# Real-time monitoring procesů
sudo fs_usage -w

# Kontrola otevřených síťových spojení
lsof -i -P | grep -E "(node|bun|npm)"

# Kontrola neobvyklých outbound spojení
netstat -an | grep ESTABLISHED
```

### 3. npm/Node audit

```bash
# Kontrola npm konfigurace
npm config list

# Kontrola globálních packages
npm list -g --depth=0
bun pm ls -g

# Kontrola integrity npm cache
npm cache verify

# Seznam npm tokenů (pokud uložené)
cat ~/.npmrc | grep -E "^//.*:_authToken"

# Kontrola umístění npm cache
npm config get cache
ls -la $(npm config get cache)
```

### 4. Bun audit

```bash
# Bun verze
bun --version

# Umístění Bun instalace
which bun

# Bun globální packages
bun pm ls -g

# Kontrola bun cache
ls -la ~/.bun/install/cache/

# Neočekávané bun instalace
find ~ -name "bun" -type f -executable 2>/dev/null
```

### 5. Git/GitHub audit

```bash
# Kontrola git konfigurace
git config --global --list

# Kontrola credential helpers
git config --global credential.helper

# Kontrola SSH klíčů
ls -la ~/.ssh/

# Kontrola known_hosts na neočekávané záznamy
cat ~/.ssh/known_hosts

# Kontrola git hooks v repos
find ~ -path "*/.git/hooks/*" -type f -executable 2>/dev/null
```

### 6. Credential soubory

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
# Kontrola podezřelých keychain záznamů (manuálně)
# Otevři: Keychain Access.app
# Hledej: npm, github, aws, azure, gcloud

# Kontrola browser extensions (manuálně)
# Zkontroluj v nastavení extensions každého browseru
```

### 8. Síťová konfigurace

```bash
# Kontrola DNS konfigurace
scutil --dns

# Kontrola hosts souboru
cat /etc/hosts

# Kontrola proxy nastavení
networksetup -getwebproxy "Wi-Fi"
networksetup -getsecurewebproxy "Wi-Fi"

# Kontrola firewall statusu
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

---

## Intego-specifické kontroly

Na základě tvé Intego instalace:

### VirusBarrier (10.9.101)

```
# Spusť úplný systémový scan:
# Otevři VirusBarrier → Scan → Full Scan

# Zkontroluj karanténu:
# VirusBarrier → Quarantine

# Aktualizuj definice:
# VirusBarrier → Update
```

### NetBarrier (10.9.38)

```
# Zkontroluj firewall pravidla:
# NetBarrier → Rules

# Doporučená pravidla:
# - Blokuj všechny incoming ve výchozím stavu
# - Povol specifické apps outbound
# - Monitoruj node/bun/npm síťovou aktivitu
```

### Omezení

⚠️ **Intego nemusí detekovat Shai-Hulud protože:**

1. Je založen na JavaScriptu, ne tradiční binárce
2. Používá silnou obfuskaci (3x base64)
3. Operuje v rámci npm ekosystému
4. Instaluje Bun runtime k vyhnutí se Node.js monitoringu

**Lepší ochrana:**
- Socket.dev (máš Team plan ✅)
- npm audit
- Manuální inspekce install scriptů

---

## Automatizovaný monitoring

### Vytvoř LaunchAgent pro monitoring

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

Načti ho:
```bash
launchctl load ~/Library/LaunchAgents/com.user.npm-monitor.plist
```

---

## Analýza tvého systému

Na základě tvých reportů:

### ✅ Dobré známky

- macOS 26.1 (Tahoe) - nejnovější
- Homebrew aktuální
- npm doctor zobrazuje OK
- Žádné npm globální packages (používáš bun)
- Rust toolchain čistý
- Docker běží normálně

### ⚠️ Zkontroluj tyto

1. **1873 bun globálních packages** - to je hodně, zkontroluj kompromitované:
   ```bash
   bun pm ls -g | grep -E "(posthog|zapier|asyncapi|postman|ensdomains)"
   ```

2. **Rozbitý PATH záznam**:
   ```
   /Users/miccy/Library/Android/sdk/platform-tools/Users/miccy/Library/Android/sdk/tools/bin
   ```
   Oprav v tvém `.zshrc`

3. **Neexistující PATH adresáře**:
   - `/opt/pmk/env/global/bin`
   
   Vyčisti je

### 🔍 Doporučené kontroly

```bash
# Zkontroluj tvé bun globální packages proti IOC listu
bun pm ls -g | grep -iE "(posthog|zapier|asyncapi|postman|ensdomains|angulartics|koa2-swagger)"

# Zkontroluj credentials
ls -la ~/.npmrc ~/.aws/credentials

# Zkontroluj IOC soubory
find ~/Developer -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
```

---

## Kroky k obnově (pokud kompromitován)

1. **Zálohuj důležitá data** (vyjma node_modules)
2. **Rotuj VŠECHNY credentials** (viz remediation.md)
3. **Čistá instalace doporučena** pro závažné případy
4. **Přeinstaluj developer tools** z oficiálních zdrojů
5. **Vygeneruj nové SSH/GPG klíče**
6. **Povol 2FA všude**

---

## Prevence

### .npmrc (Globální)

```bash
echo "ignore-scripts=true" >> ~/.npmrc
echo "audit=true" >> ~/.npmrc
```

### Git hooks

```bash
# V každém repu přidej pre-commit kontrolu
cat << 'EOF' > .git/hooks/pre-commit
#!/bin/bash
# Zkontroluj IOC soubory před commitem
if find . -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
    echo "❌ IOC soubory detekovány! Ruším commit."
    exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

---

## Nástroje

| Nástroj | Účel | Odkaz |
|---------|------|-------|
| Socket.dev | npm security scanning | https://socket.dev |
| Snyk | Dependency scanning | https://snyk.io |
| npm-audit | Vestavěný npm audit | `npm audit` |
| osquery | System monitoring | https://osquery.io |
| BlockBlock | Persistence monitoring | https://objective-see.org/products/blockblock.html |
| LuLu | Firewall | https://objective-see.org/products/lulu.html |
