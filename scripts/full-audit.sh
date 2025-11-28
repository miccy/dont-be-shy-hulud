#!/bin/bash
#
# full-audit.sh - Kompletní security audit pro Shai-Hulud 2.0
# https://github.com/miccy/hunting-worms-guide
#
# Použití: ./full-audit.sh [cesta_k_projektům]
#

set -euo pipefail

# Barvy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Konfigurace
SCAN_PATH="${1:-$HOME/Developer}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOC_DIR="$SCRIPT_DIR/../ioc"
REPORT_DIR="$HOME/shai-hulud-audit-$(date +%Y%m%d-%H%M%S)"

# Counters
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           SHAI-HULUD 2.0 FULL SECURITY AUDIT                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo "Skenuju: $SCAN_PATH"
echo "Report: $REPORT_DIR"
echo "Datum: $(date)"
echo ""

# Vytvoř report directory
mkdir -p "$REPORT_DIR"

# Logging
log_critical() {
    echo -e "${RED}[CRITICAL] $1${NC}"
    echo "[CRITICAL] $1" >> "$REPORT_DIR/findings.log"
    CRITICAL=$((CRITICAL + 1))
}

log_high() {
    echo -e "${RED}[HIGH] $1${NC}"
    echo "[HIGH] $1" >> "$REPORT_DIR/findings.log"
    HIGH=$((HIGH + 1))
}

log_medium() {
    echo -e "${YELLOW}[MEDIUM] $1${NC}"
    echo "[MEDIUM] $1" >> "$REPORT_DIR/findings.log"
    MEDIUM=$((MEDIUM + 1))
}

log_low() {
    echo -e "${YELLOW}[LOW] $1${NC}"
    echo "[LOW] $1" >> "$REPORT_DIR/findings.log"
    LOW=$((LOW + 1))
}

log_ok() {
    echo -e "${GREEN}[OK] $1${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# ============================================
# FÁZE 1: Stažení aktuálních IOC
# ============================================
echo -e "\n${CYAN}═══ FÁZE 1: Aktualizace IOC databáze ═══${NC}"

IOC_SOURCES=(
    "https://raw.githubusercontent.com/tenable/shai-hulud-second-coming-affected-packages/main/list.json"
    "https://raw.githubusercontent.com/DataDog/indicators-of-compromise/main/shai-hulud-2.0/affected-packages.json"
)

mkdir -p "$REPORT_DIR/ioc"

for url in "${IOC_SOURCES[@]}"; do
    filename=$(basename "$url")
    log_info "Stahuji IOC: $filename"
    if curl -sL "$url" -o "$REPORT_DIR/ioc/$filename" 2>/dev/null; then
        log_ok "Staženo: $filename"
    else
        log_medium "Nepodařilo se stáhnout: $url"
    fi
done

# Extrahuj package names
if [ -f "$REPORT_DIR/ioc/list.json" ]; then
    jq -r '.[].name // empty' "$REPORT_DIR/ioc/list.json" 2>/dev/null | sort -u > "$REPORT_DIR/ioc/malicious-packages.txt" || true
    log_info "Extrahováno $(wc -l < "$REPORT_DIR/ioc/malicious-packages.txt" | tr -d ' ') známých malicious packages"
fi

# ============================================
# FÁZE 2: Kontrola souborového systému
# ============================================
echo -e "\n${CYAN}═══ FÁZE 2: Kontrola souborového systému ═══${NC}"

# 2.1 Payload soubory
log_info "Hledám payload soubory..."
find "$SCAN_PATH" -maxdepth 15 \
    \( -name "setup_bun.js" -o -name "bun_environment.js" \) \
    -type f 2>/dev/null > "$REPORT_DIR/payload-files.txt" || true

if [ -s "$REPORT_DIR/payload-files.txt" ]; then
    while read -r file; do
        log_critical "Payload nalezen: $file"
        
        # Spočítej hash
        if command -v shasum &>/dev/null; then
            hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
            echo "  SHA256: $hash" >> "$REPORT_DIR/findings.log"
        fi
    done < "$REPORT_DIR/payload-files.txt"
else
    log_ok "Žádné payload soubory nenalezeny"
fi

# 2.2 TruffleHog cache
log_info "Kontrola .truffler-cache..."
if [ -d "$HOME/.truffler-cache" ]; then
    log_critical "~/.truffler-cache existuje!"
    ls -la "$HOME/.truffler-cache" >> "$REPORT_DIR/findings.log" 2>/dev/null
else
    log_ok "~/.truffler-cache neexistuje"
fi

# 2.3 Podezřelé workflow soubory
log_info "Hledám podezřelé GitHub workflows..."
find "$SCAN_PATH" -path "*/.github/workflows/*.yaml" -o -path "*/.github/workflows/*.yml" 2>/dev/null | \
    xargs grep -l "self-hosted" 2>/dev/null > "$REPORT_DIR/suspicious-workflows.txt" || true

if [ -s "$REPORT_DIR/suspicious-workflows.txt" ]; then
    while read -r file; do
        if grep -q "discussion" "$file" 2>/dev/null; then
            log_high "Podezřelý workflow (discussion + self-hosted): $file"
        else
            log_low "Self-hosted workflow (review manuálně): $file"
        fi
    done < "$REPORT_DIR/suspicious-workflows.txt"
else
    log_ok "Žádné podezřelé workflow soubory"
fi

# ============================================
# FÁZE 3: Kontrola závislostí
# ============================================
echo -e "\n${CYAN}═══ FÁZE 3: Kontrola závislostí ═══${NC}"

# 3.1 Hledej package-lock.json a porovnej s IOC
log_info "Skenuju package-lock.json soubory..."

if [ -f "$REPORT_DIR/ioc/malicious-packages.txt" ]; then
    find "$SCAN_PATH" -name "package-lock.json" -not -path "*/node_modules/*" 2>/dev/null | \
    while read -r lockfile; do
        log_info "Kontroluji: $lockfile"
        
        # Extrahuj packages z lockfile
        jq -r '.packages | keys[]' "$lockfile" 2>/dev/null | \
        sed 's|node_modules/||g' | \
        while read -r pkg; do
            pkg_name=$(echo "$pkg" | sed 's|@[^/]*/||' | cut -d'/' -f1)
            if grep -qF "$pkg_name" "$REPORT_DIR/ioc/malicious-packages.txt" 2>/dev/null; then
                log_high "Známý malicious package: $pkg_name v $lockfile"
            fi
        done
    done
else
    log_medium "IOC seznam není dostupný - přeskakuji kontrolu dependencies"
fi

# 3.2 Kontrola preinstall scripts
log_info "Hledám podezřelé preinstall scripts..."
find "$SCAN_PATH" -name "package.json" -path "*/node_modules/*" -exec \
    grep -l '"preinstall"' {} \; 2>/dev/null > "$REPORT_DIR/preinstall-scripts.txt" || true

if [ -s "$REPORT_DIR/preinstall-scripts.txt" ]; then
    while read -r file; do
        if grep -qE 'setup_bun|bun_environment' "$file" 2>/dev/null; then
            log_critical "Malicious preinstall: $file"
        fi
    done < "$REPORT_DIR/preinstall-scripts.txt"
fi

# ============================================
# FÁZE 4: Kontrola procesů a sítě
# ============================================
echo -e "\n${CYAN}═══ FÁZE 4: Kontrola procesů a sítě ═══${NC}"

# 4.1 Běžící procesy
log_info "Kontrola běžících procesů..."
ps aux > "$REPORT_DIR/processes.txt" 2>/dev/null

if grep -qE "(bun_environment|trufflehog|setup_bun)" "$REPORT_DIR/processes.txt" 2>/dev/null; then
    log_critical "Podezřelé procesy běží!"
    grep -E "(bun_environment|trufflehog|setup_bun)" "$REPORT_DIR/processes.txt" >> "$REPORT_DIR/findings.log"
else
    log_ok "Žádné podezřelé procesy"
fi

# 4.2 Network connections
log_info "Kontrola síťových spojení..."
if command -v lsof &>/dev/null; then
    lsof -i -n > "$REPORT_DIR/network.txt" 2>/dev/null || true
fi

# ============================================
# FÁZE 5: Kontrola credentials
# ============================================
echo -e "\n${CYAN}═══ FÁZE 5: Kontrola credentials ═══${NC}"

check_credential_file() {
    local path="$1"
    local name="$2"
    local severity="${3:-MEDIUM}"
    
    if [ -f "$path" ]; then
        log_medium "$name existuje: $path"
        echo "  Potenciálně kompromitovaný - doporučena rotace" >> "$REPORT_DIR/findings.log"
    elif [ -d "$path" ]; then
        log_medium "$name adresář existuje: $path"
    fi
}

check_credential_file "$HOME/.npmrc" "npm config"
check_credential_file "$HOME/.aws/credentials" "AWS credentials"
check_credential_file "$HOME/.azure" "Azure config"
check_credential_file "$HOME/.config/gcloud/application_default_credentials.json" "GCP credentials"
check_credential_file "$HOME/.docker/config.json" "Docker config"
check_credential_file "$HOME/.kube/config" "Kubernetes config"
check_credential_file "$HOME/.ssh/id_rsa" "SSH private key"
check_credential_file "$HOME/.ssh/id_ed25519" "SSH private key (ed25519)"

# ============================================
# FÁZE 6: GitHub kontrola
# ============================================
echo -e "\n${CYAN}═══ FÁZE 6: GitHub kontrola ═══${NC}"

if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    log_info "Kontrola GitHub repos..."
    
    # Hledej Shai-Hulud repos
    gh repo list --limit 500 --json name,description,createdAt 2>/dev/null | \
        jq -r '.[] | select(.description != null) | select(.description | test("hulud|Hulud"; "i")) | 
        "REPO: \(.name) | CREATED: \(.createdAt) | DESC: \(.description)"' > "$REPORT_DIR/hulud-repos.txt" || true
    
    if [ -s "$REPORT_DIR/hulud-repos.txt" ]; then
        while read -r line; do
            log_critical "Shai-Hulud repo nalezen: $line"
        done < "$REPORT_DIR/hulud-repos.txt"
    else
        log_ok "Žádné Shai-Hulud repos"
    fi
    
    # Kontrola nedávných repos
    log_info "Kontrola nedávno vytvořených repos..."
    WEEK_AGO=$(date -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d "7 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
    
    gh repo list --limit 100 --json name,createdAt,description 2>/dev/null | \
        jq -r --arg date "$WEEK_AGO" '.[] | select(.createdAt > $date) | 
        "\(.name) | \(.createdAt)"' > "$REPORT_DIR/recent-repos.txt" || true
    
    if [ -s "$REPORT_DIR/recent-repos.txt" ]; then
        log_info "Nedávno vytvořené repos (review manuálně):"
        cat "$REPORT_DIR/recent-repos.txt"
    fi
else
    log_info "gh CLI není dostupné - přeskakuji GitHub kontrolu"
fi

# ============================================
# FÁZE 7: npm kontrola
# ============================================
echo -e "\n${CYAN}═══ FÁZE 7: npm kontrola ═══${NC}"

if command -v npm &>/dev/null; then
    # npm whoami
    if npm whoami &>/dev/null 2>&1; then
        NPM_USER=$(npm whoami 2>/dev/null)
        log_info "npm user: $NPM_USER"
        
        # Kontrola publikovaných packages
        log_info "Kontrola publikovaných packages..."
        npm access ls-packages 2>/dev/null > "$REPORT_DIR/npm-packages.txt" || true
        
        if [ -s "$REPORT_DIR/npm-packages.txt" ]; then
            log_info "Tvoje packages:"
            cat "$REPORT_DIR/npm-packages.txt"
            log_medium "Doporučení: Zkontroluj nedávné publikace těchto packages"
        fi
    else
        log_info "npm není autentizováno"
    fi
    
    # npm audit
    log_info "Spouštím npm audit v dostupných projektech..."
    find "$SCAN_PATH" -name "package.json" -not -path "*/node_modules/*" -maxdepth 5 2>/dev/null | \
    head -10 | while read -r pkg; do
        dir=$(dirname "$pkg")
        if [ -f "$dir/package-lock.json" ]; then
            log_info "Audit: $dir"
            (cd "$dir" && npm audit --json 2>/dev/null | jq -r '.metadata.vulnerabilities.high // 0' || echo "0") | \
            read -r high_vulns || high_vulns=0
            
            if [ "$high_vulns" != "0" ] && [ -n "$high_vulns" ]; then
                log_high "npm audit: $high_vulns high vulnerabilities v $dir"
            fi
        fi
    done
else
    log_info "npm není nainstalováno"
fi

# ============================================
# SHRNUTÍ
# ============================================
echo ""
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                      SHRNUTÍ AUDITU                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "Critical: ${RED}$CRITICAL${NC}"
echo -e "High:     ${RED}$HIGH${NC}"
echo -e "Medium:   ${YELLOW}$MEDIUM${NC}"
echo -e "Low:      ${YELLOW}$LOW${NC}"
echo ""
echo "Report uložen: $REPORT_DIR"
echo ""

if [ $CRITICAL -gt 0 ] || [ $HIGH -gt 0 ]; then
    echo -e "${RED}⚠️  POZOR: Nalezeny kritické nebo vysoké nálezy!${NC}"
    echo ""
    echo "Okamžité kroky:"
    echo "1. Izoluj systém od sítě"
    echo "2. Prostuduj $REPORT_DIR/findings.log"
    echo "3. Následuj docs/REMEDIATION.md"
    echo "4. Rotuj VŠECHNY credentials"
elif [ $MEDIUM -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Nalezeny střední nálezy - doporučena review${NC}"
else
    echo -e "${GREEN}✅ Žádné významné nálezy${NC}"
    echo "Doporučení: Zkontroluj docs/PREVENTION.md pro hardening"
fi

# Generuj HTML report
echo "
<!DOCTYPE html>
<html>
<head>
    <title>Shai-Hulud 2.0 Audit Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; }
        .critical { color: #dc3545; }
        .high { color: #dc3545; }
        .medium { color: #ffc107; }
        .low { color: #17a2b8; }
        .ok { color: #28a745; }
        pre { background: #f5f5f5; padding: 15px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>🪱 Shai-Hulud 2.0 Audit Report</h1>
    <p>Generated: $(date)</p>
    <p>Scan path: $SCAN_PATH</p>
    
    <h2>Summary</h2>
    <ul>
        <li class='critical'>Critical: $CRITICAL</li>
        <li class='high'>High: $HIGH</li>
        <li class='medium'>Medium: $MEDIUM</li>
        <li class='low'>Low: $LOW</li>
    </ul>
    
    <h2>Findings</h2>
    <pre>$(cat "$REPORT_DIR/findings.log" 2>/dev/null || echo "No findings")</pre>
</body>
</html>
" > "$REPORT_DIR/report.html"

log_info "HTML report: $REPORT_DIR/report.html"
