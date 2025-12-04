#!/usr/bin/env bash
# =============================================================================
# update-iocs.sh - Automated IOC Update Script
# =============================================================================
#
# Fetches latest Indicators of Compromise from security vendor sources
# and merges them into the local IOC database.
#
# Usage:
#   ./update-iocs.sh [options]
#
# Options:
#   --dry-run       Show what would be updated without making changes
#   --verbose       Show detailed output
#   --source <src>  Update from specific source only (datadog|wiz|tenable|safedep)
#   --output <dir>  Output directory (default: ./ioc)
#   --help          Show this help message
#
# Sources:
#   - Datadog: https://github.com/DataDog/indicators-of-compromise
#   - Wiz: https://github.com/wiz-sec-public/wiz-research-iocs
#   - Tenable: https://github.com/tenable/shai-hulud-second-coming-affected-packages
#   - SafeDep: https://safedep.io/shai-hulud-second-coming-supply-chain-attack/
#
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOC_DIR="${SCRIPT_DIR}/../ioc"
TEMP_DIR="/tmp/hulud-ioc-update-$$"
DRY_RUN=false
VERBOSE=false
SPECIFIC_SOURCE=""
UPDATED_COUNT=0

# Vendor sources
declare -A VENDOR_URLS=(
    ["datadog"]="https://raw.githubusercontent.com/DataDog/indicators-of-compromise/main/shai-hulud-2.0/packages.json"
    ["wiz"]="https://raw.githubusercontent.com/wiz-sec-public/wiz-research-iocs/main/shai-hulud-2.0/packages.json"
    ["tenable"]="https://raw.githubusercontent.com/tenable/shai-hulud-second-coming-affected-packages/main/packages.json"
)

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

show_help() {
    head -28 "$0" | tail -24
    exit 0
}

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# =============================================================================
# Fetch Functions
# =============================================================================

fetch_datadog() {
    log_info "Fetching IOCs from Datadog..."

    local url="${VENDOR_URLS[datadog]}"
    local output="$TEMP_DIR/datadog.json"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would fetch from: $url"
        return 0
    fi

    if curl -sSL "$url" -o "$output" 2>/dev/null; then
        local count
        count=$(jq 'if type == "array" then length else .packages | length end' "$output" 2>/dev/null || echo "0")
        log_success "Fetched $count packages from Datadog"
        return 0
    else
        log_warn "Failed to fetch from Datadog (source may not exist yet)"
        return 1
    fi
}

fetch_wiz() {
    log_info "Fetching IOCs from Wiz..."

    local url="${VENDOR_URLS[wiz]}"
    local output="$TEMP_DIR/wiz.json"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would fetch from: $url"
        return 0
    fi

    if curl -sSL "$url" -o "$output" 2>/dev/null; then
        local count
        count=$(jq 'if type == "array" then length else .packages | length end' "$output" 2>/dev/null || echo "0")
        log_success "Fetched $count packages from Wiz"
        return 0
    else
        log_warn "Failed to fetch from Wiz (source may not exist yet)"
        return 1
    fi
}

fetch_tenable() {
    log_info "Fetching IOCs from Tenable..."

    local url="${VENDOR_URLS[tenable]}"
    local output="$TEMP_DIR/tenable.json"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would fetch from: $url"
        return 0
    fi

    if curl -sSL "$url" -o "$output" 2>/dev/null; then
        local count
        count=$(jq 'if type == "array" then length else .packages | length end' "$output" 2>/dev/null || echo "0")
        log_success "Fetched $count packages from Tenable"
        return 0
    else
        log_warn "Failed to fetch from Tenable (source may not exist yet)"
        return 1
    fi
}

# =============================================================================
# Merge Functions
# =============================================================================

merge_packages() {
    log_info "Merging package lists..."

    local merged="$TEMP_DIR/merged.json"
    local existing="$IOC_DIR/malicious-packages.json"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would merge packages into: $existing"
        return 0
    fi

    # Start with existing packages
    if [[ -f "$existing" ]]; then
        cp "$existing" "$merged"
    else
        echo '{"packages":[]}' > "$merged"
    fi

    # Merge each vendor file
    for vendor_file in "$TEMP_DIR"/*.json; do
        if [[ -f "$vendor_file" && "$vendor_file" != "$merged" ]]; then
            local vendor_name
            vendor_name=$(basename "$vendor_file" .json)
            log_verbose "Processing $vendor_name..."

            # Extract packages and merge (deduplicate by name)
            local new_packages
            new_packages=$(jq -s '
                .[0].packages as $existing |
                (.[1].packages // .[1]) as $new |
                ($existing + $new) | unique_by(.name)
            ' "$merged" "$vendor_file" 2>/dev/null || echo "[]")

            if [[ -n "$new_packages" && "$new_packages" != "[]" ]]; then
                echo "{\"packages\": $new_packages}" > "$merged"
            fi
        fi
    done

    # Count new packages
    local old_count new_count
    old_count=$(jq '.packages | length' "$existing" 2>/dev/null || echo "0")
    new_count=$(jq '.packages | length' "$merged" 2>/dev/null || echo "0")
    UPDATED_COUNT=$((new_count - old_count))

    # Update the file
    if [[ $UPDATED_COUNT -gt 0 ]]; then
        # Add metadata
        jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.last_updated = $date | .source = "auto-update"' \
           "$merged" > "$existing"
        log_success "Added $UPDATED_COUNT new packages (total: $new_count)"
    else
        log_info "No new packages to add"
    fi
}

generate_changelog() {
    local changelog="$IOC_DIR/CHANGELOG-ioc.md"
    local date_str
    date_str=$(date +"%Y-%m-%d")

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would update changelog: $changelog"
        return 0
    fi

    if [[ $UPDATED_COUNT -gt 0 ]]; then
        local entry="## [$date_str] - Auto-update\n\n### Added\n- $UPDATED_COUNT new packages from vendor sources\n\n"

        if [[ -f "$changelog" ]]; then
            # Prepend to existing changelog
            local existing
            existing=$(cat "$changelog")
            echo -e "$entry$existing" > "$changelog"
        else
            # Create new changelog
            echo -e "# IOC Database Changelog\n\n$entry" > "$changelog"
        fi

        log_success "Updated IOC changelog"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --source)
                SPECIFIC_SOURCE="$2"
                shift 2
                ;;
            --output)
                IOC_DIR="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done

    # Check dependencies
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi

    # Create temp directory
    mkdir -p "$TEMP_DIR"
    mkdir -p "$IOC_DIR"

    # Banner
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     📦 ${YELLOW}Shai-Hulud IOC Auto-Updater${NC}                           ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     Fetching latest indicators from security vendors          ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    # Fetch from sources
    if [[ -n "$SPECIFIC_SOURCE" ]]; then
        case "$SPECIFIC_SOURCE" in
            datadog) fetch_datadog ;;
            wiz) fetch_wiz ;;
            tenable) fetch_tenable ;;
            *)
                log_error "Unknown source: $SPECIFIC_SOURCE"
                exit 1
                ;;
        esac
    else
        # Fetch from all sources
        fetch_datadog || true
        fetch_wiz || true
        fetch_tenable || true
    fi

    # Merge and update
    merge_packages
    generate_changelog

    # Summary
    echo ""
    if [[ $UPDATED_COUNT -gt 0 ]]; then
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✅ UPDATE COMPLETE: Added $UPDATED_COUNT new packages${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    else
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}ℹ️  UPDATE COMPLETE: No new packages found${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    fi
    echo ""

    log_info "IOC database location: $IOC_DIR/malicious-packages.json"
}

main "$@"
