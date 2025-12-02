#!/bin/bash
VERSION="1.5.0"

if [[ "$1" == "--version" ]]; then
    echo "$VERSION"
    exit 0
fi
#
# harden-npm.sh - Hardening npm and bun configuration
# https://github.com/miccy/dont-be-shy-hulud
#
# Usage: ./harden-npm.sh [--apply]
#

set -euo pipefail

# Colors
# RED='\033[0;31m' # Unused
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APPLY_MODE=false

if [ "${1:-}" = "--apply" ]; then
    APPLY_MODE=true
fi

echo -e "${BLUE}🛡️  npm/bun Hardening Script${NC}"
echo "============================="
echo ""

if [ "$APPLY_MODE" = true ]; then
    echo -e "${GREEN}Mode: APPLY (making changes)${NC}"
else
    echo -e "${YELLOW}Mode: DRY-RUN (only showing what would change)${NC}"
    echo "To apply changes run: $0 --apply"
fi
echo ""

# Functions
apply_setting() {
    local cmd="$1"
    local desc="$2"

    echo -e "${BLUE}→ $desc${NC}"
    if [ "$APPLY_MODE" = true ]; then
        eval "$cmd"
        echo -e "${GREEN}  ✓ Applied${NC}"
    else
        echo "  Command: $cmd"
    fi
}

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup
        backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
        if [ "$APPLY_MODE" = true ]; then
            cp "$file" "$backup"
            echo -e "${GREEN}  Backup: $backup${NC}"
        else
            echo "  Backup would be: $backup"
        fi
    fi
}

# ============================================
# 1. npm configuration
# ============================================
echo -e "\n${YELLOW}[1/5] npm configuration${NC}"

# Backup existing .npmrc
if [ -f "$HOME/.npmrc" ]; then
    echo "Existing ~/.npmrc:"
    cat "$HOME/.npmrc"
    backup_file "$HOME/.npmrc"
fi

# ignore-scripts
echo ""
apply_setting "npm config set ignore-scripts true" "Disable lifecycle scripts (ignore-scripts=true)"

# audit-level
apply_setting "npm config set audit-level high" "Set audit-level to high"

# save-exact
apply_setting "npm config set save-exact true" "Save exact versions (save-exact=true)"

# prefer-offline
apply_setting "npm config set prefer-offline true" "Prefer offline installation"

# ============================================
# 2. Project .npmrc template
# ============================================
echo -e "\n${YELLOW}[2/5] Project .npmrc template${NC}"

NPMRC_TEMPLATE='# Shai-Hulud hardened .npmrc
# https://github.com/miccy/dont-be-shy-hulud

# Disable lifecycle scripts
ignore-scripts=true

# Require exact versions
save-exact=true

# Audit settings
audit=true
audit-level=high

# Security
strict-ssl=true

# Prefer offline
prefer-offline=true

# Lockfile
package-lock=true
'

echo "Template for .npmrc in projects:"
echo "---"
echo "$NPMRC_TEMPLATE"
echo "---"

if [ "$APPLY_MODE" = true ]; then
    echo "$NPMRC_TEMPLATE" > "$HOME/.npmrc-hardened-template"
    echo -e "${GREEN}Template saved: ~/.npmrc-hardened-template${NC}"
fi

# ============================================
# 3. bun configuration
# ============================================
echo -e "\n${YELLOW}[3/5] bun configuration${NC}"

if command -v bun &>/dev/null; then
    echo "bun version: $(bun --version)"

    # bunfig.toml template
    read -r -d '' BUNFIG_TEMPLATE << 'EOF'
# Shai-Hulud hardened bunfig.toml
# https://github.com/miccy/dont-be-shy-hulud

[install]
# Disable lifecycle scripts
lifecycle_scripts = false

# Exact versions
exact = true

# Frozen lockfile in CI
frozen_lockfile = true

[install.scopes]
# Example: private registry for @company scope
# "@company" = { url = "https://npm.company.com", token = "$COMPANY_NPM_TOKEN" }
EOF

    echo "Template for bunfig.toml:"
    echo "---"
    echo "$BUNFIG_TEMPLATE"
    echo "---"

    if [ "$APPLY_MODE" = true ]; then
        echo "$BUNFIG_TEMPLATE" > "$HOME/.bunfig-hardened-template.toml"
        echo -e "${GREEN}Template saved: ~/.bunfig-hardened-template.toml${NC}"
    fi
else
    echo "bun is not installed - skipping"
fi

# ============================================
# 4. Git hooks for audit
# ============================================
echo -e "\n${YELLOW}[4/5] Git pre-commit hook template${NC}"

PRECOMMIT_HOOK='#!/bin/bash
# Pre-commit hook for security audit
# Install: cp this file to .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# Check package.json changes
if git diff --cached --name-only | grep -q "package.json\|package-lock.json\|bun.lockb"; then
    echo "📦 Detected changes in dependencies..."

    # npm audit
    if [ -f "package-lock.json" ]; then
        echo "Running npm audit..."
        if ! npm audit --audit-level=high; then
            echo "❌ npm audit failed! Fix vulnerabilities before committing."
            exit 1
        fi
    fi

    # Socket.dev scan (if installed)
    if command -v socket &>/dev/null; then
        echo "Running Socket.dev scan..."
        if ! socket scan .; then
            echo "⚠️  Socket.dev found issues - review before committing"
        fi
    fi
fi

exit 0
'

echo "Template for .git/hooks/pre-commit:"
echo "---"
echo "$PRECOMMIT_HOOK"
echo "---"

if [ "$APPLY_MODE" = true ]; then
    echo "$PRECOMMIT_HOOK" > "$HOME/.git-precommit-audit-template"
    chmod +x "$HOME/.git-precommit-audit-template"
    echo -e "${GREEN}Template saved: ~/.git-precommit-audit-template${NC}"
fi

# ============================================
# 5. CI/CD environment variables
# ============================================
echo -e "\n${YELLOW}[5/5] CI/CD environment variables${NC}"

echo "Recommended env vars for CI/CD:"
echo ""
echo "# npm"
echo "export NPM_CONFIG_IGNORE_SCRIPTS=true"
echo "export NPM_CONFIG_AUDIT_LEVEL=high"
echo ""
echo "# bun"
echo "export BUN_CONFIG_NO_SCRIPTS=1"
echo ""
echo "# Node.js"
echo "export NODE_OPTIONS=\"--disallow-code-generation-from-strings\""
echo ""

# ============================================
# Summary
# ============================================
echo ""
echo "============================="
if [ "$APPLY_MODE" = true ]; then
    echo -e "${GREEN}✅ Hardening completed!${NC}"
    echo ""
    echo "Changes made:"
    echo "- npm config updated"
    echo "- Templates saved in ~/"
    echo ""
    echo "Next steps:"
    echo "1. Copy ~/.npmrc-hardened-template to your projects as .npmrc"
    echo "2. Copy ~/.bunfig-hardened-template.toml to projects as bunfig.toml"
    echo "3. Set up git hooks using ~/.git-precommit-audit-template"
else
    echo -e "${YELLOW}Dry-run completed.${NC}"
    echo "To apply changes run: $0 --apply"
fi

echo ""
echo "Current npm config:"
npm config list 2>/dev/null || true
