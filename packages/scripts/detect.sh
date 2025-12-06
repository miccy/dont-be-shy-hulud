#!/usr/bin/env bash
#
# Shai-Hulud 2.0 Detection Script
# https://github.com/miccy/dont-be-shy-hulud
#
# Usage: ./detect.sh [path] [--output file] [--verbose] [--ci] [--format json|text]
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Config
SCAN_PATH="."
OUTPUT_FILE=""
VERBOSE=false
CI_MODE=false
SKIP_HASH=false
GITHUB_CHECK=false
FOUND_ISSUES=0
VERSION="1.5.1"
OUTPUT_FORMAT="text"
JSON_FINDINGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            echo "$VERSION"
            exit 0
            ;;
        --output=*)
            OUTPUT_FILE="${1#*=}"
            shift
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --ci)
            CI_MODE=true
            shift
            ;;
        --skip-hash)
            SKIP_HASH=true
            shift
            ;;
        --github-check)
            GITHUB_CHECK=true
            shift
            ;;
        --format=*)
            OUTPUT_FORMAT="${1#*=}"
            shift
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --sarif)
            OUTPUT_FORMAT="sarif"
            shift
            ;;
        -*)
            # Unknown flag, ignore or handle
            shift
            ;;
        *)
            SCAN_PATH="$1"
            shift
            ;;
    esac
done

# --- begin insertion ---
# Ensure OUTPUT_FILE is absolute in CI and pre-create file so the artifact step can find it.
if [[ -n "${OUTPUT_FILE:-}" ]]; then
  if [[ "${CI_MODE:-}" == "true" && -n "${GITHUB_WORKSPACE:-}" ]]; then
    OUTPUT_FILE="${GITHUB_WORKSPACE%/}/$OUTPUT_FILE"
  else
    OUTPUT_FILE="$(pwd)/$OUTPUT_FILE"
  fi
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  # Pre-create file so upload-artifact sees it even if script exits early.
  echo "Shai-Hulud scan started: $(date)" > "$OUTPUT_FILE" || true
fi

# Ensure we always append a summary on exit (runs on normal and error exits)
_trap_write_summary() {
  # Avoid failing in the trap (|| true assures non-zero in trap doesn't abort)
  if [[ -n "${OUTPUT_FILE:-}" ]]; then
    # If file is empty or doesn't exist, write NO_FINDINGS (unless we have found issues)
    if [[ ! -s "$OUTPUT_FILE" ]] && [[ "${FOUND_ISSUES:-0}" -eq 0 ]]; then
        echo "NO_FINDINGS" > "$OUTPUT_FILE" || true
    else
        # If we have content or issues, append summary
        echo "" >> "$OUTPUT_FILE" || true
        echo "Issues found: ${FOUND_ISSUES:-0}" >> "$OUTPUT_FILE" || true
        echo "Scan finished at: $(date)" >> "$OUTPUT_FILE" || true
    fi
  fi
}
trap _trap_write_summary EXIT
# --- end insertion ---

# JSON helper functions
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

add_json_finding() {
    local severity="$1"
    local category="$2"
    local message="$3"
    local file="${4:-}"

    local escaped_message
    escaped_message=$(json_escape "$message")
    local escaped_file
    escaped_file=$(json_escape "$file")

    local finding="{\"severity\":\"$severity\",\"category\":\"$category\",\"message\":\"$escaped_message\""
    if [[ -n "$file" ]]; then
        finding="$finding,\"file\":\"$escaped_file\""
    fi
    finding="$finding}"

    JSON_FINDINGS+=("$finding")
}

# Logging
log_info() {
    if [[ "$OUTPUT_FORMAT" != "json" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_warn() {
    if [[ "$OUTPUT_FORMAT" != "json" ]]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
    add_json_finding "warning" "general" "$1" "${2:-}"
    ((FOUND_ISSUES++))
}

log_error() {
    if [[ "$OUTPUT_FORMAT" != "json" ]]; then
        echo -e "${RED}[CRITICAL]${NC} $1"
    fi
    add_json_finding "critical" "general" "$1" "${2:-}"
    ((FOUND_ISSUES++))
}

log_ok() {
    if [[ "$OUTPUT_FORMAT" != "json" ]]; then
        echo -e "${GREEN}[OK]${NC} $1"
    fi
}

# Header (skip for JSON output)
if [[ "$OUTPUT_FORMAT" != "json" ]]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           🪱 SHAI-HULUD 2.0 DETECTION SCRIPT                   ║"
    echo "║           https://github.com/miccy/dont-be-shy-hulud              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Scanning: $SCAN_PATH"
    echo "Date: $(date)"
    echo ""
fi

# =============================================================================
# 1. Check for IOC files
# =============================================================================
if [[ "$OUTPUT_FORMAT" != "json" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Checking for IOC files..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# CRITICAL IOC files - unique names, search EVERYWHERE including node_modules
# These are specific to Shai-Hulud and unlikely to be legitimate
CRITICAL_IOC_FILES=(
    "setup_bun.js"
    "bun_environment.js"
    "actionsSecrets.json"
    "truffleSecrets.json"
)

# GENERIC IOC files - common names, search OUTSIDE node_modules only
# These names are too generic and cause false positives in dependencies
GENERIC_IOC_FILES=(
    "cloud.json"
    "contents.json"
    "environment.json"
    "data.json"
)

# Known malicious file hashes (SHA256)
MALICIOUS_HASHES=(
    "a3894003ad1d293ba96d77881ccd2071446dc3f65f434669b49b3da92421901a"  # setup_bun.js
    "62ee164b9b306250c1172583f138c9614139264f889fa99614903c12755468d0"  # bun_environment.js
    "46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09"  # bundle.js (v1)
)

# Secondary phase patterns
SECONDARY_PATTERNS=(
    "Sha1-Hulud: The Continued Coming"
    "Shai-Hulud Migration"
)

# Check CRITICAL IOC files - search everywhere including node_modules
for file in "${CRITICAL_IOC_FILES[@]}"; do
    found=$(find "$SCAN_PATH" -name "$file" -type f -not -path "*/.git/*" 2>/dev/null | head -5)
    if [[ -n "$found" ]]; then
        log_error "Found CRITICAL malicious file: $file"
        echo "$found" | while read -r f; do
            # Verify with hash if possible
            if command -v shasum &> /dev/null; then
                file_hash=$(shasum -a 256 "$f" 2>/dev/null | cut -d' ' -f1)
                echo "         → $f (SHA256: $file_hash)"
            else
                echo "         → $f"
            fi
        done
    else
        $VERBOSE && log_ok "Not found: $file"
    fi
done

# Check GENERIC IOC files - search only outside node_modules to avoid false positives
for file in "${GENERIC_IOC_FILES[@]}"; do
    found=$(find "$SCAN_PATH" -name "$file" -type f -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -5)
    if [[ -n "$found" ]]; then
        log_error "Found suspicious file: $file (outside node_modules)"
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

unexpected_bun=$(find "$SCAN_PATH" -name "bun" -type f -perm +111 2>/dev/null || find "$SCAN_PATH" -name "bun" -type f -executable 2>/dev/null || true | while read -r bun_path; do
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
echo "         → Look for repos with description: 'Sha1-Hulud: The Continued Coming'"
echo "         → Look for repos with '-migration' suffix"
echo "         → Check for unauthorized self-hosted runners named 'SHA1HULUD'"

# If gh CLI is available and user opted in
if [[ "$GITHUB_CHECK" == true ]]; then
    if command -v gh &> /dev/null; then
        log_info "GitHub CLI detected. Running automated check..."
        gh_repos=$(gh repo list --json name,description 2>/dev/null | grep -i "hulud" || true)
        if [[ -n "$gh_repos" ]]; then
            log_error "Found suspicious repositories on your account!"
            echo "$gh_repos"
        else
            log_ok "No suspicious repos found via GitHub CLI"
        fi
    else
        log_warn "GitHub check requested (--github-check) but 'gh' CLI not found."
    fi
else
    $VERBOSE && log_info "Skipping GitHub API check (use --github-check to enable)"
fi

# =============================================================================
# 9. Hash-based IOC detection (more reliable than filename)
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9. Hash-based malware detection..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check JS files between 1MB-15MB (payload size range)
# Detect hash command
HASH_CMD=""
if command -v shasum &>/dev/null; then
    HASH_CMD="shasum -a 256"
elif command -v sha256sum &>/dev/null; then
    HASH_CMD="sha256sum"
fi

if [[ "$SKIP_HASH" == true ]]; then
    log_info "Skipping hash-based detection (--skip-hash)"
elif [[ -z "$HASH_CMD" ]]; then
    log_warn "No suitable hash command found (shasum or sha256sum). Skipping hash checks."
else
    # Check JS files between 1MB-15MB (payload size range)
    hash_matches=0
    while IFS= read -r jsfile; do
        if [[ -f "$jsfile" ]]; then
            file_hash=$($HASH_CMD "$jsfile" 2>/dev/null | cut -d' ' -f1)
            for known_hash in "${MALICIOUS_HASHES[@]}"; do
                if [[ "$file_hash" == "$known_hash" ]]; then
                    log_error "MALICIOUS FILE DETECTED (hash match): $jsfile"
                    log_error "Hash: $file_hash"
                    ((hash_matches++))
                fi
            done
        fi
    done < <(find "$SCAN_PATH" -name "*.js" -type f -size +1M -size -15M 2>/dev/null)

    if [[ $hash_matches -eq 0 ]]; then
        log_ok "No known malicious hashes detected"
    fi
fi

# =============================================================================
# 10. Check for cloud metadata service abuse (CI/CD environments)
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "10. Checking for cloud metadata service abuse..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Common grep filters for whitelist approach
# Exclude our own IOC documentation files to avoid false positives
GREP_FILTERS=(
    --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx"
    --include="*.mjs" --include="*.cjs" --include="*.json" --include="*.yml"
    --include="*.yaml" --include="*.sh"
    --exclude="network.json" --exclude="malicious-packages.json" --exclude="detect.sh"
    --exclude="hashes.json" --exclude="ROADMAP.md" --exclude="*.spec.ts"
    --exclude-dir="node_modules" --exclude-dir=".git" --exclude-dir="packages/ioc"
    --exclude-dir="packages/docs-content"
)

metadata_abuse=$(grep -r "${GREP_FILTERS[@]}" "169\.254\.169\.254" "$SCAN_PATH" 2>/dev/null | grep -v ".git" | grep -v "node_modules" | head -5 || true)
if [[ -n "$metadata_abuse" ]]; then
    log_error "Found references to cloud metadata service (potential credential theft):"
    echo "$metadata_abuse"
else
    log_ok "No metadata service abuse indicators found"
fi

# =============================================================================
# 11. Check for secondary phase indicators
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "11. Checking for secondary phase (Continued Coming) indicators..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

secondary_found=false
for pattern in "${SECONDARY_PATTERNS[@]}"; do
    # Exclude our own documentation, IOC files, and detection scripts to avoid false positives
    matches=$(grep -r "${GREP_FILTERS[@]}" "$pattern" "$SCAN_PATH" 2>/dev/null | \
        grep -v ".git" | \
        grep -v "node_modules" | \
        grep -v "packages/ioc" | \
        grep -v "packages/docs-content" | \
        grep -v "packages/scripts" | \
        grep -v "ROADMAP.md" | \
        head -3 || true)
    if [[ -n "$matches" ]]; then
        log_error "Found secondary phase indicator: '$pattern'"
        echo "$matches"
        secondary_found=true
    fi
done

if [[ "$secondary_found" == false ]]; then
    log_ok "No secondary phase indicators found"
fi

# =============================================================================
# 12. Bun-specific security checks
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "12. Bun-specific security checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Bun is used
BUN_LOCK_FOUND=$(find "$SCAN_PATH" -name "bun.lockb" -not -path "*/node_modules/*" -print -quit 2>/dev/null || true)

if [[ -n "$BUN_LOCK_FOUND" ]] || command -v bun &> /dev/null; then
    log_info "Bun detected in project"
    echo "         → ⚠️  Remember: .npmrc ignore-scripts does NOT work reliably in Bun!"
    echo "         → ALWAYS use: bun install --ignore-scripts"

    # Check for trustedDependencies that might allow malicious scripts
    if [[ -f "$SCAN_PATH/package.json" ]]; then
        trusted=$(grep -o '"trustedDependencies"' "$SCAN_PATH/package.json" 2>/dev/null || true)
        if [[ -n "$trusted" ]]; then
            log_warn "trustedDependencies found in package.json - review carefully"
            grep -A 10 '"trustedDependencies"' "$SCAN_PATH/package.json" | head -12
        fi
    fi

    # Check .npmrc for false sense of security
    for npmrc in "$HOME/.npmrc" "$SCAN_PATH/.npmrc"; do
        if [[ -f "$npmrc" ]]; then
            npmrc_ignore=$(grep "ignore-scripts" "$npmrc" 2>/dev/null || true)
            if [[ -n "$npmrc_ignore" ]]; then
                log_warn "⚠️  .npmrc ignore-scripts found in $npmrc BUT:"
                echo "         → Bun does NOT reliably respect this setting!"
                echo "         → ALWAYS use: bun install --ignore-scripts"
            fi
        fi
    done
else
    log_ok "No Bun lockfile detected"
fi

# =============================================================================
# Summary
# =============================================================================

# =============================================================================
# JSON Output
# =============================================================================
output_json() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "{"
    echo "  \"version\": \"$VERSION\","
    echo "  \"timestamp\": \"$timestamp\","
    echo "  \"scan_path\": \"$(json_escape "$SCAN_PATH")\","
    echo "  \"total_issues\": $FOUND_ISSUES,"
    echo "  \"status\": \"$([ $FOUND_ISSUES -eq 0 ] && echo 'clean' || echo 'compromised')\","
    echo "  \"findings\": ["

    local first=true
    for finding in "${JSON_FINDINGS[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo ","
        fi
        echo -n "    $finding"
    done

    echo ""
    echo "  ]"
    echo "}"
}

# =============================================================================
# SARIF Output (GitHub Security Tab compatible)
# =============================================================================
output_sarif() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat <<EOF
{
  "\$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "Shai-Hulud Detector",
          "version": "$VERSION",
          "informationUri": "https://github.com/miccy/dont-be-shy-hulud",
          "rules": [
            {
              "id": "HULUD001",
              "name": "MaliciousFileDetected",
              "shortDescription": {
                "text": "Malicious IOC file detected"
              },
              "fullDescription": {
                "text": "A file matching known Shai-Hulud 2.0 indicators of compromise was detected."
              },
              "defaultConfiguration": {
                "level": "error"
              },
              "helpUri": "https://github.com/miccy/dont-be-shy-hulud/blob/main/docs/DETECTION.md"
            },
            {
              "id": "HULUD002",
              "name": "CompromisedPackageDetected",
              "shortDescription": {
                "text": "Compromised npm package detected"
              },
              "fullDescription": {
                "text": "A package matching known compromised packages from the Shai-Hulud 2.0 attack was detected."
              },
              "defaultConfiguration": {
                "level": "error"
              },
              "helpUri": "https://github.com/miccy/dont-be-shy-hulud/blob/main/docs/DETECTION.md"
            },
            {
              "id": "HULUD003",
              "name": "SuspiciousWorkflowDetected",
              "shortDescription": {
                "text": "Suspicious GitHub workflow detected"
              },
              "fullDescription": {
                "text": "A GitHub Actions workflow matching known malicious patterns was detected."
              },
              "defaultConfiguration": {
                "level": "warning"
              },
              "helpUri": "https://github.com/miccy/dont-be-shy-hulud/blob/main/docs/GITHUB-HARDENING.md"
            },
            {
              "id": "HULUD004",
              "name": "SuspiciousDirectoryDetected",
              "shortDescription": {
                "text": "Suspicious directory detected"
              },
              "fullDescription": {
                "text": "A directory matching known Shai-Hulud 2.0 staging locations was detected."
              },
              "defaultConfiguration": {
                "level": "warning"
              },
              "helpUri": "https://github.com/miccy/dont-be-shy-hulud/blob/main/docs/DETECTION.md"
            }
          ]
        }
      },
      "results": [
EOF

    local first=true
    local result_index=0
    for finding in "${JSON_FINDINGS[@]}"; do
        local severity message file rule_id
        severity=$(echo "$finding" | jq -r '.severity // "warning"')
        message=$(echo "$finding" | jq -r '.message // "Unknown issue"')
        file=$(echo "$finding" | jq -r '.file // ""')

        # Map severity to SARIF level
        local level="warning"
        case "$severity" in
            critical) level="error" ;;
            warning) level="warning" ;;
            info) level="note" ;;
        esac

        # Determine rule ID based on message content
        rule_id="HULUD001"
        if [[ "$message" == *"package"* ]]; then
            rule_id="HULUD002"
        elif [[ "$message" == *"workflow"* ]]; then
            rule_id="HULUD003"
        elif [[ "$message" == *"directory"* ]]; then
            rule_id="HULUD004"
        fi

        if [[ "$first" == true ]]; then
            first=false
        else
            echo ","
        fi

        cat <<RESULT
        {
          "ruleId": "$rule_id",
          "level": "$level",
          "message": {
            "text": "$(json_escape "$message")"
          }$(if [[ -n "$file" ]]; then echo ",
          \"locations\": [
            {
              \"physicalLocation\": {
                \"artifactLocation\": {
                  \"uri\": \"$(json_escape "$file")\"
                }
              }
            }
          ]"; fi)
        }
RESULT
        ((result_index++))
    done

    cat <<EOF

      ],
      "invocations": [
        {
          "executionSuccessful": $([ $FOUND_ISSUES -eq 0 ] && echo 'true' || echo 'false'),
          "endTimeUtc": "$timestamp"
        }
      ]
    }
  ]
}
EOF
}

# Output to file if requested (BEFORE exit)
if [[ -n "$OUTPUT_FILE" ]]; then
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        output_json > "$OUTPUT_FILE"
    elif [[ "$OUTPUT_FORMAT" == "sarif" ]]; then
        output_sarif > "$OUTPUT_FILE"
    else
        echo "Issues found: $FOUND_ISSUES" > "$OUTPUT_FILE"
    fi
    if [[ "$OUTPUT_FORMAT" != "json" ]]; then
        echo "Scan completed. Results saved to $OUTPUT_FILE"
    fi
fi

# JSON output to stdout
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    output_json
    if [[ $FOUND_ISSUES -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

# SARIF output to stdout
if [[ "$OUTPUT_FORMAT" == "sarif" ]]; then
    output_sarif
    if [[ $FOUND_ISSUES -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

# Text output summary
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
    echo "See [docs/REMEDIATION.md](docs/REMEDIATION.md) for detailed steps."

    if [[ "$CI_MODE" == true ]]; then
        # Ensure output file exists before exiting
        if [[ -n "$OUTPUT_FILE" ]] && [[ ! -f "$OUTPUT_FILE" ]]; then
             echo "No scan results were produced. Please check script logic." > "$OUTPUT_FILE"
        fi
        exit 1
    fi
fi

