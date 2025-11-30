#!/bin/bash
VERSION="1.3.3"

if [[ "${1:-}" == "--version" ]]; then
    echo "$VERSION"
    exit 0
fi
#
# check-github-repos.sh - Check GitHub account for compromise
# https://github.com/miccy/dont-be-shy-hulud
#
# Requires: gh CLI (https://cli.github.com)
#
# Usage: ./check-github-repos.sh [username]
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check gh CLI
if ! command -v gh &>/dev/null; then
    echo -e "${RED}Error: gh CLI is not installed${NC}"
    echo "Install: brew install gh"
    exit 1
fi

# Check auth
if ! gh auth status &>/dev/null 2>&1; then
    echo -e "${RED}Error: gh CLI is not authenticated${NC}"
    echo "Run: gh auth login"
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
# 1. Check for Shai-Hulud repos
# ============================================
echo -e "\n${BLUE}[1/6] Searching for Shai-Hulud repos...${NC}"

gh repo list "$USERNAME" --limit 1000 --json name,description,createdAt,visibility 2>/dev/null | \
    jq -r '.[] | select(.description != null) |
    select(.description | test("hulud|Hulud|migration"; "i")) |
    "\(.name)|\(.description)|\(.createdAt)|\(.visibility)"' > "$REPORT_DIR/hulud-repos.txt" || true

if [ -s "$REPORT_DIR/hulud-repos.txt" ]; then
    echo -e "${RED}🚨 FOUND Shai-Hulud repos:${NC}"
    while IFS='|' read -r name desc created visibility; do
        echo -e "  ${RED}• $name${NC}"
        echo "    Description: $desc"
        echo "    Created: $created"
        echo "    Visibility: $visibility"
        FOUND_ISSUES=$((FOUND_ISSUES + 1))
    done < "$REPORT_DIR/hulud-repos.txt"
else
    echo -e "${GREEN}✅ No Shai-Hulud repos found${NC}"
fi

# ============================================
# 2. Check recently created repos
# ============================================
echo -e "\n${BLUE}[2/6] Checking recently created repos (7 days)...${NC}"

# Calculate date 7 days ago
if [[ "$OSTYPE" == "darwin"* ]]; then
    WEEK_AGO=$(date -v-7d +%Y-%m-%dT%H:%M:%SZ)
else
    WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%dT%H:%M:%SZ)
fi

gh repo list "$USERNAME" --limit 100 --json name,createdAt,description,visibility 2>/dev/null | \
    jq -r --arg date "$WEEK_AGO" '.[] | select(.createdAt > $date) |
    "\(.name)|\(.createdAt)|\(.visibility)|\(.description // "no description")"' > "$REPORT_DIR/recent-repos.txt" || true

if [ -s "$REPORT_DIR/recent-repos.txt" ]; then
    echo -e "${YELLOW}⚠️  Recently created repos (requires review):${NC}"
    while IFS='|' read -r name created visibility desc; do
        echo "  • $name (created: $created, $visibility)"
        echo "    $desc"
    done < "$REPORT_DIR/recent-repos.txt"
else
    echo -e "${GREEN}✅ No new repos in the last 7 days${NC}"
fi

# ============================================
# 3. Check public repos with sensitive names
# ============================================
echo -e "\n${BLUE}[3/6] Checking potentially sensitive public repos...${NC}"

SENSITIVE_PATTERNS="secret|credential|token|password|private|key|config|env|backup"

gh repo list "$USERNAME" --limit 500 --json name,visibility 2>/dev/null | \
    jq -r '.[] | select(.visibility == "PUBLIC") | .name' | \
    grep -iE "$SENSITIVE_PATTERNS" > "$REPORT_DIR/sensitive-public-repos.txt" || true

if [ -s "$REPORT_DIR/sensitive-public-repos.txt" ]; then
    echo -e "${YELLOW}⚠️  Public repos with potentially sensitive names:${NC}"
    while read -r name; do
        echo "  • $name"
    done < "$REPORT_DIR/sensitive-public-repos.txt"
else
    echo -e "${GREEN}✅ No suspicious public repos${NC}"
fi

# ============================================
# 4. Check workflow files
# ============================================
echo -e "\n${BLUE}[4/6] Checking GitHub Actions workflows...${NC}"

echo "Checking repos with workflows..."
gh repo list "$USERNAME" --limit 100 --json name 2>/dev/null | \
    jq -r '.[].name' | while read -r repo; do

    # Check for existence of discussion.yaml
    WORKFLOWS=$(gh api "/repos/$USERNAME/$repo/contents/.github/workflows" 2>/dev/null | \
        jq -r '.[].name' 2>/dev/null || echo "")

    if echo "$WORKFLOWS" | grep -qi "discussion"; then
        echo -e "${RED}🚨 Suspicious workflow in $repo: discussion workflow${NC}"
        FOUND_ISSUES=$((FOUND_ISSUES + 1))
    fi
done

# ============================================
# 5. Check Personal Access Tokens
# ============================================
echo -e "\n${BLUE}[5/6] Token Information...${NC}"

echo "To check tokens:"
echo "  → https://github.com/settings/tokens"
echo "  → https://github.com/settings/tokens?type=beta (fine-grained)"
echo ""
echo "To check OAuth apps:"
echo "  → https://github.com/settings/applications"
echo ""
echo "To check sessions:"
echo "  → https://github.com/settings/sessions"

# ============================================
# 6. Check audit log (if org exists)
# ============================================
echo -e "\n${BLUE}[6/6] Audit log...${NC}"

# Try to get orgs
ORGS=$(gh api /user/orgs --jq '.[].login' 2>/dev/null || echo "")

if [ -n "$ORGS" ]; then
    echo "Your organizations:"
    echo "$ORGS" | while read -r org; do
        echo "  • $org"
        echo "    Audit log: https://github.com/organizations/$org/settings/audit-log"
    done
else
    echo "No organizations found."
fi

# ============================================
# Summary
# ============================================
echo ""
echo "========================="
if [ $FOUND_ISSUES -gt 0 ]; then
    echo -e "${RED}🚨 FOUND $FOUND_ISSUES CRITICAL ISSUES!${NC}"
    echo ""
    echo "Immediate actions:"
    echo "1. Delete found Shai-Hulud repos: gh repo delete REPO --yes"
    echo "2. Revoke all PATs"
    echo "3. Revoke OAuth apps"
    echo "4. Check audit log"
else
    echo -e "${GREEN}✅ No critical issues found${NC}"
fi

echo ""
echo "Report saved: $REPORT_DIR"
echo ""
echo "Recommended actions:"
echo "• Revoke and regenerate all GitHub PATs"
echo "• Check OAuth applications"
echo "• Enable 2FA if not enabled"
echo "• Use fine-grained tokens instead of classic"
