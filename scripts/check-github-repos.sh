#!/bin/bash
#
# check-github-repos.sh - Kontrola GitHub účtu na kompromitaci
# https://github.com/miccy/dont-be-shy-hulud
#
# Vyžaduje: gh CLI (https://cli.github.com)
#
# Použití: ./check-github-repos.sh [username]
#

set -euo pipefail

# Barvy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check gh CLI
if ! command -v gh &>/dev/null; then
    echo -e "${RED}Error: gh CLI není nainstalováno${NC}"
    echo "Instalace: brew install gh"
    exit 1
fi

# Check auth
if ! gh auth status &>/dev/null 2>&1; then
    echo -e "${RED}Error: gh CLI není autentizováno${NC}"
    echo "Spusť: gh auth login"
    exit 1
fi

USERNAME="${1:-$(gh api user --jq '.login')}"
REPORT_DIR="$HOME/github-audit-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}🔍 GitHub Security Check${NC}"
echo "========================="
echo "User: $USERNAME"
echo "Report: $REPORT_DIR"
echo ""

mkdir -p "$REPORT_DIR"

FOUND_ISSUES=0

# ============================================
# 1. Kontrola Shai-Hulud repos
# ============================================
echo -e "\n${BLUE}[1/6] Hledám Shai-Hulud repos...${NC}"

gh repo list "$USERNAME" --limit 1000 --json name,description,createdAt,visibility 2>/dev/null | \
    jq -r '.[] | select(.description != null) | 
    select(.description | test("hulud|Hulud|migration"; "i")) | 
    "\(.name)|\(.description)|\(.createdAt)|\(.visibility)"' > "$REPORT_DIR/hulud-repos.txt" || true

if [ -s "$REPORT_DIR/hulud-repos.txt" ]; then
    echo -e "${RED}🚨 NALEZENY Shai-Hulud repos:${NC}"
    while IFS='|' read -r name desc created visibility; do
        echo -e "  ${RED}• $name${NC}"
        echo "    Description: $desc"
        echo "    Created: $created"
        echo "    Visibility: $visibility"
        FOUND_ISSUES=$((FOUND_ISSUES + 1))
    done < "$REPORT_DIR/hulud-repos.txt"
else
    echo -e "${GREEN}✅ Žádné Shai-Hulud repos nenalezeny${NC}"
fi

# ============================================
# 2. Kontrola nedávno vytvořených repos
# ============================================
echo -e "\n${BLUE}[2/6] Kontrola nedávno vytvořených repos (7 dní)...${NC}"

# Výpočet data před 7 dny
if [[ "$OSTYPE" == "darwin"* ]]; then
    WEEK_AGO=$(date -v-7d +%Y-%m-%dT%H:%M:%SZ)
else
    WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%dT%H:%M:%SZ)
fi

gh repo list "$USERNAME" --limit 100 --json name,createdAt,description,visibility 2>/dev/null | \
    jq -r --arg date "$WEEK_AGO" '.[] | select(.createdAt > $date) | 
    "\(.name)|\(.createdAt)|\(.visibility)|\(.description // "no description")"' > "$REPORT_DIR/recent-repos.txt" || true

if [ -s "$REPORT_DIR/recent-repos.txt" ]; then
    echo -e "${YELLOW}⚠️  Nedávno vytvořené repos (vyžaduje review):${NC}"
    while IFS='|' read -r name created visibility desc; do
        echo "  • $name (created: $created, $visibility)"
        echo "    $desc"
    done < "$REPORT_DIR/recent-repos.txt"
else
    echo -e "${GREEN}✅ Žádné nové repos za posledních 7 dní${NC}"
fi

# ============================================
# 3. Kontrola public repos s citlivými názvy
# ============================================
echo -e "\n${BLUE}[3/6] Kontrola potenciálně citlivých public repos...${NC}"

SENSITIVE_PATTERNS="secret|credential|token|password|private|key|config|env|backup"

gh repo list "$USERNAME" --limit 500 --json name,visibility 2>/dev/null | \
    jq -r '.[] | select(.visibility == "PUBLIC") | .name' | \
    grep -iE "$SENSITIVE_PATTERNS" > "$REPORT_DIR/sensitive-public-repos.txt" || true

if [ -s "$REPORT_DIR/sensitive-public-repos.txt" ]; then
    echo -e "${YELLOW}⚠️  Public repos s potenciálně citlivými názvy:${NC}"
    while read -r name; do
        echo "  • $name"
    done < "$REPORT_DIR/sensitive-public-repos.txt"
else
    echo -e "${GREEN}✅ Žádné podezřelé public repos${NC}"
fi

# ============================================
# 4. Kontrola workflow souborů
# ============================================
echo -e "\n${BLUE}[4/6] Kontrola GitHub Actions workflows...${NC}"

echo "Kontroluji repos s workflows..."
gh repo list "$USERNAME" --limit 100 --json name 2>/dev/null | \
    jq -r '.[].name' | while read -r repo; do
    
    # Zkontroluj existence discussion.yaml
    WORKFLOWS=$(gh api "/repos/$USERNAME/$repo/contents/.github/workflows" 2>/dev/null | \
        jq -r '.[].name' 2>/dev/null || echo "")
    
    if echo "$WORKFLOWS" | grep -qi "discussion"; then
        echo -e "${RED}🚨 Podezřelý workflow v $repo: discussion workflow${NC}"
        FOUND_ISSUES=$((FOUND_ISSUES + 1))
    fi
done

# ============================================
# 5. Kontrola Personal Access Tokens
# ============================================
echo -e "\n${BLUE}[5/6] Informace o tokenech...${NC}"

echo "Pro kontrolu tokenů:"
echo "  → https://github.com/settings/tokens"
echo "  → https://github.com/settings/tokens?type=beta (fine-grained)"
echo ""
echo "Pro kontrolu OAuth apps:"
echo "  → https://github.com/settings/applications"
echo ""
echo "Pro kontrolu sessions:"
echo "  → https://github.com/settings/sessions"

# ============================================
# 6. Kontrola audit logu (pokud máš org)
# ============================================
echo -e "\n${BLUE}[6/6] Audit log...${NC}"

# Zkus získat orgy
ORGS=$(gh api /user/orgs --jq '.[].login' 2>/dev/null || echo "")

if [ -n "$ORGS" ]; then
    echo "Tvoje organizace:"
    echo "$ORGS" | while read -r org; do
        echo "  • $org"
        echo "    Audit log: https://github.com/organizations/$org/settings/audit-log"
    done
else
    echo "Žádné organizace nenalezeny."
fi

# ============================================
# Shrnutí
# ============================================
echo ""
echo "========================="
if [ $FOUND_ISSUES -gt 0 ]; then
    echo -e "${RED}🚨 NALEZENO $FOUND_ISSUES KRITICKÝCH PROBLÉMŮ!${NC}"
    echo ""
    echo "Okamžité kroky:"
    echo "1. Smaž nalezené Shai-Hulud repos: gh repo delete REPO --yes"
    echo "2. Revokuj všechny PATs"
    echo "3. Revokuj OAuth apps"
    echo "4. Zkontroluj audit log"
else
    echo -e "${GREEN}✅ Žádné kritické problémy nenalezeny${NC}"
fi

echo ""
echo "Report uložen: $REPORT_DIR"
echo ""
echo "Doporučené akce:"
echo "• Revokuj a přegeneruj všechny GitHub PATs"
echo "• Zkontroluj OAuth aplikace"
echo "• Nastav 2FA pokud nemáš"
echo "• Použij fine-grained tokens místo classic"
