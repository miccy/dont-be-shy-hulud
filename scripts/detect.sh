#!/usr/bin/env bash
#
# Shai-Hulud 2.0 Detection Script
# https://github.com/miccy/hunting-worms-guide
#
# Usage: ./detect.sh [path] [--output file] [--verbose] [--ci]
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Config
SCAN_PATH="${1:-.}"
OUTPUT_FILE=""
VERBOSE=false
CI_MODE=false
FOUND_ISSUES=0

# Parse arguments
for arg in "$@"; do
    case $arg in
        --output=*)
            OUTPUT_FILE="${arg#*=}"
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --ci)
            CI_MODE=true
            ;;
    esac
done

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((FOUND_ISSUES++))
}

log_error() {
    echo -e "${RED}[CRITICAL]${NC} $1"
    ((FOUND_ISSUES++))
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Header
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🪱 SHAI-HULUD 2.0 DETECTION SCRIPT                   ║"
echo "║           https://github.com/miccy/hunting-worms-guide         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Scanning: $SCAN_PATH"
echo "Date: $(date)"
echo ""

# =============================================================================
# 1. Check for IOC files
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Checking for IOC files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Malicious files
IOC_FILES=(
    "setup_bun.js"
    "bun_environment.js"
    "actionsSecrets.json"
    "cloud.json"
    "contents.json"
    "environment.json"
    "truffleSecrets.json"
)

for file in "${IOC_FILES[@]}"; do
    found=$(find "$SCAN_PATH" -name "$file" -type f 2>/dev/null | head -5)
    if [[ -n "$found" ]]; then
        log_error "Found malicious file: $file"
        echo "$found" | while read -r f; do
            echo "         → $f"
        done
    else
        $VERBOSE && log_ok "Not found: $file"
    fi
done

# .truffler-cache directory
if find "$SCAN_PATH" -name ".truffler-cache" -type d 2>/dev/null | grep -q .; then
    log_error "Found .truffler-cache directory (TruffleHog abuse indicator)"
fi

# =============================================================================
# 2. Check for malicious workflows
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking for malicious GitHub workflows..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for formatter_*.yml (backdoor pattern)
formatter_files=$(find "$SCAN_PATH" -path "*/.github/workflows/formatter_*.yml" -type f 2>/dev/null)
if [[ -n "$formatter_files" ]]; then
    log_error "Found suspicious workflow files (formatter_*.yml pattern)"
    echo "$formatter_files" | while read -r f; do
        echo "         → $f"
    done
fi

# Check for SHA1HULUD in workflows
sha1hulud_workflows=$(find "$SCAN_PATH" -path "*/.github/workflows/*.yml" -type f -exec grep -l "SHA1HULUD\|self-hosted" {} \; 2>/dev/null)
if [[ -n "$sha1hulud_workflows" ]]; then
    log_error "Found workflows with SHA1HULUD or suspicious self-hosted runners"
    echo "$sha1hulud_workflows" | while read -r f; do
        echo "         → $f"
    done
fi

# Check for discussion triggers (backdoor)
discussion_triggers=$(find "$SCAN_PATH" -path "*/.github/workflows/*.yml" -type f -exec grep -l "discussion:" {} \; 2>/dev/null)
if [[ -n "$discussion_triggers" ]]; then
    log_warn "Found workflows triggered by discussions (potential backdoor)"
    echo "$discussion_triggers" | while read -r f; do
        echo "         → $f"
    done
fi

# =============================================================================
# 3. Check for compromised packages in lockfiles
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Checking lockfiles for known compromised packages..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# High-priority compromised packages (partial list)
COMPROMISED_PACKAGES=(
    "@postman/tunnel-agent"
    "posthog-node"
    "posthog-js"
    "@asyncapi/specs"
    "@asyncapi/openapi-schema-parser"
    "@asyncapi/avro-schema-parser"
    "@asyncapi/json-schema-parser"
    "@asyncapi/raml-dt-schema-parser"
    "zapier-sdk"
    "zapier-platform-core"
    "zapier-platform-cli"
    "@ensdomains/ensjs"
    "@ensdomains/content-hash"
    "ethereum-ens"
    "@postman/postman-mcp-cli"
    "angulartics2"
    "koa2-swagger-ui"
    "@posthog/agent"
)

check_lockfile() {
    local lockfile="$1"
    local found_packages=""
    
    for pkg in "${COMPROMISED_PACKAGES[@]}"; do
        if grep -q "\"$pkg\"" "$lockfile" 2>/dev/null; then
            found_packages+="$pkg "
        fi
    done
    
    if [[ -n "$found_packages" ]]; then
        log_warn "Found potentially compromised packages in $lockfile:"
        for pkg in $found_packages; do
            echo "         → $pkg"
        done
        echo "         ⚠️  Check if versions are from before Nov 21, 2025"
    else
        log_ok "No known compromised packages in $lockfile"
    fi
}

# Find and check all lockfiles
find "$SCAN_PATH" \( -name "package-lock.json" -o -name "yarn.lock" -o -name "pnpm-lock.yaml" -o -name "bun.lockb" \) -type f 2>/dev/null | while read -r lockfile; do
    if [[ "$lockfile" != *"node_modules"* ]]; then
        check_lockfile "$lockfile"
    fi
done

# =============================================================================
# 4. Check for preinstall scripts in package.json
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Checking for suspicious preinstall/postinstall scripts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

suspicious_scripts=$(find "$SCAN_PATH" -name "package.json" -type f 2>/dev/null | while read -r pkg; do
    if [[ "$pkg" != *"node_modules"* ]]; then
        if grep -E "(preinstall|postinstall).*setup_bun|bun_environment" "$pkg" 2>/dev/null; then
            echo "$pkg"
        fi
    fi
done)

if [[ -n "$suspicious_scripts" ]]; then
    log_error "Found suspicious install scripts:"
    echo "$suspicious_scripts"
else
    log_ok "No suspicious install scripts found in project package.json files"
fi

# =============================================================================
# 5. Check credentials files
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Checking credentials files (potential exfiltration targets)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CRED_PATHS=(
    "$HOME/.npmrc"
    "$HOME/.aws/credentials"
    "$HOME/.azure"
    "$HOME/.config/gcloud"
)

for cred_path in "${CRED_PATHS[@]}"; do
    if [[ -e "$cred_path" ]]; then
        log_warn "Found credential file: $cred_path"
        echo "         → Consider rotating these credentials"
    fi
done

# =============================================================================
# 6. Check for Bun in unexpected locations
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Checking for Bun runtime in unexpected locations..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Expected Bun locations
EXPECTED_BUN_PATHS=(
    "$HOME/.bun"
    "/usr/local/bin/bun"
    "/opt/homebrew/bin/bun"
)

unexpected_bun=$(find "$SCAN_PATH" -name "bun" -type f -executable 2>/dev/null | while read -r bun_path; do
    is_expected=false
    for expected in "${EXPECTED_BUN_PATHS[@]}"; do
        if [[ "$bun_path" == "$expected"* ]]; then
            is_expected=true
            break
        fi
    done
    if [[ "$is_expected" == false ]]; then
        echo "$bun_path"
    fi
done)

if [[ -n "$unexpected_bun" ]]; then
    log_error "Found Bun in unexpected location (potential malware dropper):"
    echo "$unexpected_bun"
else
    log_ok "No unexpected Bun installations found"
fi

# =============================================================================
# 7. Check npm cache
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Checking npm cache for IOCs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

npm_cache_path=$(npm config get cache 2>/dev/null || echo "$HOME/.npm")
if [[ -d "$npm_cache_path" ]]; then
    cache_iocs=$(find "$npm_cache_path" \( -name "setup_bun.js" -o -name "bun_environment.js" \) -type f 2>/dev/null)
    if [[ -n "$cache_iocs" ]]; then
        log_error "Found IOCs in npm cache!"
        echo "$cache_iocs"
        echo "         → Run: npm cache clean --force"
    else
        log_ok "npm cache appears clean"
    fi
else
    log_info "npm cache not found at $npm_cache_path"
fi

# =============================================================================
# 8. Check for GitHub repos with Shai-Hulud markers
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Reminder: Check your GitHub account..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "Manually check for suspicious repos on your GitHub account:"
echo "         → https://github.com/YOUR_USERNAME?tab=repositories"
echo "         → Look for repos with description: 'Sha1-Hulud: The Second Coming'"
echo "         → Look for repos with '-migration' suffix"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                         SCAN SUMMARY                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [[ $FOUND_ISSUES -eq 0 ]]; then
    echo -e "${GREEN}✅ No indicators of Shai-Hulud 2.0 compromise detected.${NC}"
    echo ""
    echo "Your system appears clean from this specific attack."
    echo "However, continue to:"
    echo "  • Monitor for new IOCs"
    echo "  • Keep dependencies updated (after verification)"
    echo "  • Use Socket.dev or similar for real-time protection"
    exit 0
else
    echo -e "${RED}⚠️  Found $FOUND_ISSUES potential issues!${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  1. Do NOT run npm/bun install until resolved"
    echo "  2. Rotate ALL credentials (npm, GitHub, AWS, etc.)"
    echo "  3. Check IOC files and remove if confirmed malicious"
    echo "  4. Clear caches: npm cache clean --force"
    echo "  5. Pin dependencies to pre-Nov 21, 2025 versions"
    echo ""
    echo "For detailed remediation, see:"
    echo "  https://github.com/miccy/hunting-worms-guide/blob/main/docs/remediation.md"
    
    if [[ "$CI_MODE" == true ]]; then
        exit 1
    fi
fi

# Output to file if requested
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "Issues found: $FOUND_ISSUES" > "$OUTPUT_FILE"
    echo "Scan completed. Results saved to $OUTPUT_FILE"
fi
