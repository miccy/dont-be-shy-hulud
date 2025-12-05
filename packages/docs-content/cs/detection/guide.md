# 🔍 Detection Guide

> Jak zjistit, zda jste kompromitovaní Shai-Hulud 2.0

## Quick Check (5 minut)

Spusť tyto příkazy pro rychlou kontrolu:

```bash
#!/bin/bash

echo "🔍 Quick Shai-Hulud 2.0 Check"
echo "=============================="

# 1. Kontrola payload souborů
echo -e "\n[1/6] Kontrola payload souborů..."
find ~/Developer ~/Projects ~/repos ~/ -maxdepth 5 \
  \( -name "setup_bun.js" -o -name "bun_environment.js" \) \
  -type f 2>/dev/null

# 2. Kontrola .truffler-cache
echo -e "\n[2/6] Kontrola .truffler-cache..."
if [ -d "$HOME/.truffler-cache" ]; then
  echo "⚠️  FOUND: ~/.truffler-cache exists!"
  ls -la "$HOME/.truffler-cache"
else
  echo "✅ OK: ~/.truffler-cache not found"
fi

# 3. Kontrola discussion.yaml
echo -e "\n[3/6] Kontrola discussion.yaml workflows..."
find ~/Developer ~/Projects ~/repos -path "*/.github/workflows/discussion.yaml" 2>/dev/null

# 4. Kontrola běžících procesů
echo -e "\n[4/6] Kontrola podezřelých procesů..."
ps aux | grep -E "(bun_environment|trufflehog|hulud)" | grep -v grep

# 5. Kontrola GitHub repos (pokud máš gh CLI)
echo -e "\n[5/6] Kontrola GitHub repos..."
if command -v gh &>/dev/null; then
  gh repo list --json name,description 2>/dev/null | \
    grep -i "hulud" || echo "✅ OK: No Shai-Hulud repos found"
else
  echo "⏭️  SKIP: gh CLI not installed"
fi

# 6. Kontrola npm tokens v .npmrc
echo -e "\n[6/6] Kontrola npm tokenů..."
if [ -f "$HOME/.npmrc" ]; then
  if grep -q "_authToken" "$HOME/.npmrc"; then
    echo "⚠️  npm token nalezen - ověř jeho platnost a rotuj pokud potřeba"
  fi
else
  echo "✅ OK: No global .npmrc"
fi

echo -e "\n=============================="
echo "Quick check dokončen."
```

## Automatizovaný detekční skript

Poskytujeme robustní detekční skript `scripts/detect.sh`, který automatizuje mnoho z těchto kontrol.

```bash
# Základní sken
./scripts/detect.sh .

# Sken s kontrolou GitHub API (vyžaduje gh CLI autentizaci)
./scripts/detect.sh . --github-check

# Výstup výsledků do souboru (užitečné pro CI)
./scripts/detect.sh . --output results.txt
```

**Poznámka:** Skript obsahuje ochranu proti falešným poplachům (např. vyloučení dokumentačních souborů) a podporuje lokální i CI prostředí.

## Detailní audit

### 1. Kontrola node_modules

```bash
# Najdi všechny node_modules s podezřelými soubory
find ~/Developer -type d -name "node_modules" -exec \
  sh -c 'find "{}" -maxdepth 3 -name "setup_bun.js" -o -name "bun_environment.js"' \; 2>/dev/null

# Kontrola preinstall scriptů v package.json
find ~/Developer -name "package.json" -path "*/node_modules/*" -exec \
  grep -l '"preinstall".*setup_bun\|"preinstall".*bun_environment' {} \; 2>/dev/null
```

### 2. Kontrola npm cache

```bash
# Lokace npm cache
npm config get cache

# Hledání v cache
find "$(npm config get cache)" -name "*.tgz" -exec \
  tar -tzf {} 2>/dev/null | grep -l "setup_bun.js\|bun_environment.js" \;

# Jednodušší - vyčisti cache rovnou
npm cache clean --force
```

### 3. Kontrola bun cache

```bash
# Bun cache lokace
echo "$HOME/.bun/install/cache"

# Vyčištění
rm -rf "$HOME/.bun/install/cache"
bun pm cache rm
```

### 4. Kontrola GitHub Activity

```bash
# Všechny tvoje repos
gh repo list --limit 1000 --json name,description,pushedAt | \
  jq -r '.[] | select(.description | test("hulud|Hulud"; "i")) | .name'

# Nedávno vytvořené repos (posledních 7 dní)
gh repo list --limit 100 --json name,createdAt,description | \
  jq -r --arg date "$(date -v-7d +%Y-%m-%dT%H:%M:%SZ)" \
  '.[] | select(.createdAt > $date) | "\(.name): \(.description)"'

# Kontrola nedávných pushů
gh api /user/repos --paginate --jq '.[].full_name' | while read repo; do
  gh api "/repos/$repo/events" --jq \
    '.[] | select(.type == "PushEvent") | "\(.repo.name): \(.created_at)"' 2>/dev/null
done | head -50
```

### 5. Kontrola GitHub Actions

```bash
# Najdi všechny workflow soubory
find ~/Developer -path "*/.github/workflows/*.yml" -o -path "*/.github/workflows/*.yaml" 2>/dev/null | \
  xargs grep -l "self-hosted\|discussion:" 2>/dev/null

# Kontrola konkrétního repa
ls -la ~/Developer/my-project/.github/workflows/
cat ~/Developer/my-project/.github/workflows/*.yml | grep -E "self-hosted|discussion"
```

### 6. Kontrola systémové integrity (Linux/CI)

Kontrola artefaktů privilege escalation:

```bash
# Kontrola škodlivého sudoers souboru
if [ -f "/etc/sudoers.d/runner" ]; then
  echo "🚨 CRITICAL: /etc/sudoers.d/runner nalezen! (Privilege Escalation)"
  cat /etc/sudoers.d/runner
fi

# Kontrola DNS hijacking
if [ -f "/tmp/resolved.conf" ]; then
  echo "⚠️  SUSPICIOUS: /tmp/resolved.conf nalezen (DNS Hijacking)"
fi
```

### 7. Kontrola credentials exposure

#### npm token

```bash
# Kontrola .npmrc
cat ~/.npmrc 2>/dev/null

# Ověření platnosti tokenu
npm whoami

# Kontrola publikovaných packages
npm access ls-packages
```

#### GitHub token

```bash
# Kontrola gh CLI
gh auth status

# Kontrola git credentials
git config --global credential.helper

# Kontrola stored credentials (macOS)
security find-internet-password -s "github.com" 2>/dev/null
```

#### AWS credentials

```bash
# Kontrola AWS config
cat ~/.aws/credentials 2>/dev/null

# Ověření identity
aws sts get-caller-identity

# Kontrola posledních aktivit (pokud máš CloudTrail)
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin
```

#### GCP credentials

```bash
# Kontrola GCP
cat ~/.config/gcloud/application_default_credentials.json 2>/dev/null

# Aktivní účty
gcloud auth list

# Ověření
gcloud auth print-access-token
```

#### Azure credentials

```bash
# Kontrola Azure
ls -la ~/.azure/

# Ověření
az account show
az account list
```

### 7. Kontrola systémových logů (macOS)

```bash
# Konzolové logy
log show --predicate 'process == "node" OR process == "bun"' --last 24h

# Hledání podezřelých aktivit
log show --predicate 'eventMessage CONTAINS "hulud" OR eventMessage CONTAINS "trufflehog"' --last 7d

# Network connections
lsof -i -n | grep -E "node|bun"
```

### 8. Kontrola síťové aktivity

```bash
# Aktivní connections
netstat -an | grep ESTABLISHED | grep -E ":443|:80"

# DNS queries (vyžaduje packet capture)
sudo tcpdump -i en0 -n port 53 2>/dev/null | head -100

# Little Snitch / LuLu logs (pokud máš)
cat ~/Library/Logs/Little\ Snitch/*.log 2>/dev/null | grep -i "github\|npm"
```

## Automatizované nástroje

### Socket.dev CLI

```bash
# Instalace
npm install -g @socketsecurity/cli

# Scan projektu
socket scan ./my-project

# Scan před instalací
socket npm install
```

### Snyk

```bash
# Instalace
npm install -g snyk

# Autentizace
snyk auth

# Scan
snyk test
```

### npm audit

```bash
# Základní audit
npm audit

# JSON výstup pro parsing
npm audit --json

# Pouze high/critical
npm audit --audit-level=high
```

### Datadog SCFW

```bash
# Instalace
pip install scfw

# Konfigurace
scfw configure

# Scan
scfw scan ./my-project
```

## IOC Matching

### Kontrola proti známým packages

```bash
#!/bin/bash
# Stáhni aktuální IOC list
curl -sL "https://raw.githubusercontent.com/tenable/shai-hulud-second-coming-affected-packages/main/list.json" \
  -o /tmp/shai-hulud-ioc.json

# Extrahuj package names
jq -r '.[].name' /tmp/shai-hulud-ioc.json > /tmp/malicious-packages.txt

# Projdi všechny package-lock.json
find ~/Developer -name "package-lock.json" -exec \
  sh -c 'echo "Checking: $1"; jq -r ".packages | keys[]" "$1" 2>/dev/null | \
    while read pkg; do
      if grep -qF "$(basename "$pkg")" /tmp/malicious-packages.txt; then
        echo "⚠️  MATCH: $pkg in $1"
      fi
    done' _ {} \;
```

### Kontrola hash souborů

```bash
#!/bin/bash
# Známý hash setup_bun.js
KNOWN_HASH="d60ec97eea19fffb4809bc35b91033b52490ca11"

# Najdi a zkontroluj
find ~/Developer -name "setup_bun.js" -exec \
  sh -c 'hash=$(shasum -a 1 "$1" | cut -d" " -f1); \
    if [ "$hash" = "$2" ]; then \
      echo "🚨 MALICIOUS: $1"; \
    else \
      echo "⚠️  SUSPICIOUS: $1 (different hash)"; \
    fi' _ {} "$KNOWN_HASH" \;
```

## Co dělat při nálezu

1. **NEPANIKAŘI** – ale jednej rychle
2. **Izoluj stroj** od sítě (pokud je to možné)
3. **Dokumentuj** co jsi našel (screenshots, logy)
4. **Následuj** [Remediation Guide](REMEDIATION.md)
5. **Rotuj** VŠECHNY credentials
6. **Informuj** tým/organizaci

## False Positives

Některé věci mohou vypadat podezřele, ale nejsou:

- `bun` binárka je legitimní JS runtime
- `.github/workflows/` s `self-hosted` může být legitimní
- `trufflehog` může být legitimní security tool

Klíčové je hledat **kombinaci** indikátorů:
- setup_bun.js + bun_environment.js spolu
- discussion.yaml s `runs-on: self-hosted`
- Repos s description obsahující "Hulud"
