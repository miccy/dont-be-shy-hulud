#!/bin/bash
#
# quick-audit.sh - Rychlý security audit pro Shai-Hulud 2.0
# https://github.com/miccy/dont-be-shy-hulud
#
# Použití: ./quick-audit.sh [cesta_k_projektům]
#

set -euo pipefail

# Barvy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Výchozí cesta
SCAN_PATH="${1:-$HOME/Developer}"
FOUND_ISSUES=0

echo -e "${BLUE}🔍 Shai-Hulud 2.0 Quick Audit${NC}"
echo "================================"
echo "Skenuju: $SCAN_PATH"
echo "Datum: $(date)"
echo ""

# Funkce pro reportování
report_found() {
    echo -e "${RED}🚨 FOUND: $1${NC}"
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
}

report_ok() {
    echo -e "${GREEN}✅ OK: $1${NC}"
}

report_warn() {
    echo -e "${YELLOW}⚠️  WARN: $1${NC}"
}

report_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

# Test 1: Payload soubory
echo -e "\n${BLUE}[1/8] Kontrola payload souborů...${NC}"
PAYLOAD_FILES=$(find "$SCAN_PATH" -maxdepth 10 \
    \( -name "setup_bun.js" -o -name "bun_environment.js" \) \
    -type f 2>/dev/null || true)

if [ -n "$PAYLOAD_FILES" ]; then
    echo "$PAYLOAD_FILES" | while read -r file; do
        report_found "Payload file: $file"
    done
else
    report_ok "Žádné payload soubory nenalezeny"
fi

# Test 2: .truffler-cache
echo -e "\n${BLUE}[2/8] Kontrola .truffler-cache...${NC}"
if [ -d "$HOME/.truffler-cache" ]; then
    report_found "~/.truffler-cache existuje!"
    ls -la "$HOME/.truffler-cache" 2>/dev/null || true
else
    report_ok "~/.truffler-cache neexistuje"
fi

# Test 3: discussion.yaml workflows
echo -e "\n${BLUE}[3/8] Kontrola discussion.yaml workflows...${NC}"
DISCUSSION_FILES=$(find "$SCAN_PATH" -path "*/.github/workflows/discussion.yaml" -type f 2>/dev/null || true)

if [ -n "$DISCUSSION_FILES" ]; then
    echo "$DISCUSSION_FILES" | while read -r file; do
        # Zkontroluj obsah
        if grep -q "self-hosted" "$file" 2>/dev/null; then
            report_found "Suspicious workflow: $file"
        else
            report_warn "Workflow exists (review manually): $file"
        fi
    done
else
    report_ok "Žádné podezřelé discussion.yaml workflows"
fi

# Test 4: Běžící procesy
echo -e "\n${BLUE}[4/8] Kontrola běžících procesů...${NC}"
SUSPICIOUS_PROCS=$(ps aux | grep -E "(bun_environment|trufflehog|setup_bun)" | grep -v grep || true)

if [ -n "$SUSPICIOUS_PROCS" ]; then
    report_found "Podezřelé procesy běží!"
    echo "$SUSPICIOUS_PROCS"
else
    report_ok "Žádné podezřelé procesy"
fi

# Test 5: npm token
echo -e "\n${BLUE}[5/8] Kontrola npm tokenů...${NC}"
if [ -f "$HOME/.npmrc" ]; then
    if grep -q "_authToken" "$HOME/.npmrc" 2>/dev/null; then
        report_warn "npm token nalezen v ~/.npmrc"
        report_info "Doporučení: Ověř platnost a zvař rotaci"
        
        # Zkus ověřit token
        if command -v npm &>/dev/null; then
            if npm whoami &>/dev/null 2>&1; then
                report_info "Token je platný pro: $(npm whoami 2>/dev/null)"
            else
                report_warn "Token může být neplatný nebo expirovaný"
            fi
        fi
    else
        report_ok "Žádný authToken v ~/.npmrc"
    fi
else
    report_ok "~/.npmrc neexistuje"
fi

# Test 6: GitHub CLI check
echo -e "\n${BLUE}[6/8] Kontrola GitHub repos...${NC}"
if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null 2>&1; then
        HULUD_REPOS=$(gh repo list --limit 500 --json name,description 2>/dev/null | \
            jq -r '.[] | select(.description != null) | select(.description | test("hulud|Hulud"; "i")) | .name' || true)
        
        if [ -n "$HULUD_REPOS" ]; then
            echo "$HULUD_REPOS" | while read -r repo; do
                report_found "Shai-Hulud repo: $repo"
            done
        else
            report_ok "Žádné Shai-Hulud repos"
        fi
    else
        report_info "gh CLI není autentizováno - přeskakuji GitHub check"
    fi
else
    report_info "gh CLI není nainstalováno - přeskakuji GitHub check"
fi

# Test 7: Kontrola credentials souborů
echo -e "\n${BLUE}[7/8] Kontrola credentials souborů...${NC}"

check_creds() {
    local path="$1"
    local name="$2"
    if [ -f "$path" ] || [ -d "$path" ]; then
        report_warn "$name existuje: $path"
    fi
}

check_creds "$HOME/.aws/credentials" "AWS credentials"
check_creds "$HOME/.azure" "Azure credentials"
check_creds "$HOME/.config/gcloud/application_default_credentials.json" "GCP credentials"
check_creds "$HOME/.docker/config.json" "Docker config"
check_creds "$HOME/.kube/config" "Kubernetes config"

# Test 8: Preinstall scripts v package.json
echo -e "\n${BLUE}[8/8] Kontrola preinstall scripts...${NC}"
PREINSTALL_PKGS=$(find "$SCAN_PATH" -name "package.json" -path "*/node_modules/*" -exec \
    grep -l '"preinstall".*setup_bun\|"preinstall".*bun_environment' {} \; 2>/dev/null || true)

if [ -n "$PREINSTALL_PKGS" ]; then
    echo "$PREINSTALL_PKGS" | while read -r file; do
        report_found "Malicious preinstall: $file"
    done
else
    report_ok "Žádné podezřelé preinstall scripts"
fi

# Shrnutí
echo ""
echo "================================"
if [ $FOUND_ISSUES -gt 0 ]; then
    echo -e "${RED}🚨 NALEZENO $FOUND_ISSUES PROBLÉMŮ!${NC}"
    echo ""
    echo "Další kroky:"
    echo "1. Spusť ./scripts/full-audit.sh pro detailní analýzu"
    echo "2. Následuj docs/REMEDIATION.md"
    echo "3. Rotuj VŠECHNY credentials"
else
    echo -e "${GREEN}✅ Žádné zjevné IOC nenalezeny${NC}"
    echo ""
    echo "Doporučení:"
    echo "- Spusť ./scripts/full-audit.sh pro hlubší kontrolu"
    echo "- Zkontroluj docs/PREVENTION.md pro hardening"
fi
echo ""
echo "Report vygenerován: $(date)"
