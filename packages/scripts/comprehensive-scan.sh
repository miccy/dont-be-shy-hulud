#!/usr/bin/env bash
#
# comprehensive-scan.sh - Full system Shai-Hulud malware scan
#
# Purpose:
#   Comprehensive scan of entire system for Shai-Hulud 2.0 malware
#   Scans all critical locations with intelligent exclusions
#   Parallelized for speed, detailed logging for forensics
#
# Usage:
#   ./comprehensive-scan.sh [OPTIONS]
#
# Options:
#   --quick           Quick scan (only critical locations)
#   --full            Full HOME scan (slow but thorough)
#   --projects-only   Scan only ~/Dev/ and ~/Projects/
#   --parallel N      Number of parallel jobs (default: 4)
#   --no-parallel     Disable parallelization
#   --dry-run         Show what would be scanned without scanning
#   -h, --help        Show this help
#
# Output:
#   ~/Log/security/comprehensive-scan/scan_YYYY-MM-DD_HH-MM-SS.log
#   ~/Log/security/comprehensive-scan/summary_YYYY-MM-DD_HH-MM-SS.txt
#
# Examples:
#   ./comprehensive-scan.sh --quick              # Fast scan of critical areas
#   ./comprehensive-scan.sh --full               # Full HOME scan (slow!)
#   ./comprehensive-scan.sh --projects-only      # Just dev projects
#   ./comprehensive-scan.sh --parallel 8         # Use 8 parallel jobs
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTOR_SCRIPT="$SCRIPT_DIR/detect.sh"

# Verify detect.sh exists
if [[ ! -x "$DETECTOR_SCRIPT" ]]; then
    echo -e "${RED}ERROR: detect.sh not found or not executable!${NC}"
    echo "Expected at: $DETECTOR_SCRIPT"
    echo ""
    echo "Make sure you're running from the dont-be-shy-hulud repository."
    exit 1
fi

# Scan mode
SCAN_MODE="quick"
PARALLEL_JOBS=4
USE_PARALLEL=true
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            SCAN_MODE="quick"
            shift
            ;;
        --full)
            SCAN_MODE="full"
            shift
            ;;
        --projects-only|--projects)
            SCAN_MODE="projects"
            shift
            ;;
        --parallel)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        --no-parallel)
            USE_PARALLEL=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Setup logging
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_DIR="$HOME/Log/security/comprehensive-scan"
mkdir -p "$LOG_DIR"
SCAN_LOG="$LOG_DIR/scan_$TIMESTAMP.log"
SUMMARY_FILE="$LOG_DIR/summary_$TIMESTAMP.txt"
TEMP_DIR=$(mktemp -d)

# Trap cleanup
trap 'rm -rf "$TEMP_DIR"' EXIT

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "$SCAN_LOG"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*" | tee -a "$SCAN_LOG"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $*" | tee -a "$SCAN_LOG"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*" | tee -a "$SCAN_LOG"
}

log_info() {
    echo -e "${CYAN}[i]${NC} $*" | tee -a "$SCAN_LOG"
}

# Progress tracking
TOTAL_LOCATIONS=0
SCANNED_LOCATIONS=0
THREATS_FOUND=0

update_progress() {
    ((SCANNED_LOCATIONS++))
    local percent=$((SCANNED_LOCATIONS * 100 / TOTAL_LOCATIONS))
    echo -ne "\r${CYAN}Progress: ${percent}% (${SCANNED_LOCATIONS}/${TOTAL_LOCATIONS})${NC}"
}

# Scan function
scan_location() {
    local location="$1"
    local label="$2"
    local result_file="$TEMP_DIR/scan_$(echo "$location" | sed 's|/|_|g').txt"

    if [[ ! -d "$location" ]] && [[ ! -f "$location" ]]; then
        echo "SKIP: Location does not exist: $location" > "$result_file"
        return
    fi

    # Run detector with timeout
    if timeout 300s "$DETECTOR_SCRIPT" "$location" > "$result_file" 2>&1; then
        if grep -qi "critical\|error\|detected" "$result_file"; then
            echo "THREAT" > "${result_file}.status"
        else
            echo "CLEAN" > "${result_file}.status"
        fi
    else
        echo "TIMEOUT" > "${result_file}.status"
        echo "TIMEOUT: Scan exceeded 5 minutes" >> "$result_file"
    fi

    update_progress
}

# Note: Progress tracking doesn't work with GNU Parallel (subshells)
# We track completion by counting result files instead

# Define scan locations based on mode
declare -a SCAN_LOCATIONS
declare -a SCAN_LABELS

case $SCAN_MODE in
    quick)
        log "🔍 QUICK SCAN MODE - Critical locations only"
        SCAN_LOCATIONS=(
            "$HOME/Dev"
            "$HOME/Projects"
            "$HOME/.npm"
            "$HOME/.bun"
            "$HOME/.cache"
            "$(npm root -g 2>/dev/null || echo '/usr/local/lib/node_modules')"
            "$HOME/.config"
            "$HOME/.local"
        )
        SCAN_LABELS=(
            "Dev Projects"
            "Projects Directory"
            "NPM Cache"
            "Bun Directory"
            "User Cache"
            "NPM Global Packages"
            "Config Directory"
            "Local Directory"
        )
        ;;

    full)
        log "🔍 FULL SCAN MODE - Entire HOME directory (slow!)"
        log_warn "This may take several hours depending on system size"

        # Build full scan list with exclusions
        EXCLUDE_PATTERNS=(
            "Library"
            "Downloads"
            "Documents"
            "Music"
            "Movies"
            "Pictures"
            "Desktop"
            ".Trash"
            "Applications"
            ".git"
            ".cache/Homebrew"
            ".npm/_cacache"
        )

        # Find all directories in HOME (up to 3 levels deep)
        while IFS= read -r dir; do
            SCAN_LOCATIONS+=("$dir")
            SCAN_LABELS+=("$(basename "$dir")")
        done < <(find "$HOME" -maxdepth 3 -type d \
            $(printf "! -path *%s* " "${EXCLUDE_PATTERNS[@]}") \
            2>/dev/null || true)
        ;;

    projects)
        log "🔍 PROJECTS ONLY MODE - Development directories"
        # Common development directory names (auto-detect which exist)
        SCAN_LOCATIONS=()
        SCAN_LABELS=()
        for dir in Dev Development Projects Code repos src workspace work; do
            if [[ -d "$HOME/$dir" ]]; then
                SCAN_LOCATIONS+=("$HOME/$dir")
                SCAN_LABELS+=("$dir")
            fi
        done
        if [[ ${#SCAN_LOCATIONS[@]} -eq 0 ]]; then
            log_warn "No common dev directories found (Dev, Projects, Code, etc.)"
            log_info "Falling back to current directory"
            SCAN_LOCATIONS=("$(pwd)")
            SCAN_LABELS=("Current Directory")
        fi
        ;;
esac

# Note: We don't add individual node_modules directories because
# detect.sh already scans recursively. Adding them would cause
# massive duplication (17k+ locations instead of ~10).

TOTAL_LOCATIONS=${#SCAN_LOCATIONS[@]}

# Header
cat > "$SCAN_LOG" << EOF
================================================================================
COMPREHENSIVE SHAI-HULUD SCAN
================================================================================
Date: $(date)
Mode: $SCAN_MODE
Parallel Jobs: $PARALLEL_JOBS
Locations to Scan: $TOTAL_LOCATIONS
Detector: $DETECTOR_SCRIPT
================================================================================

EOF

log "📋 Scan Configuration:"
log "   Mode: $SCAN_MODE"
log "   Locations: $TOTAL_LOCATIONS"
log "   Parallel: $USE_PARALLEL (jobs: $PARALLEL_JOBS)"
log "   Detector: $DETECTOR_SCRIPT"
log ""

# Dry run mode
if $DRY_RUN; then
    log_warn "DRY RUN MODE - No actual scanning"
    log ""
    log "Would scan the following locations:"
    for i in "${!SCAN_LOCATIONS[@]}"; do
        printf "  %3d. %s\n" $((i+1)) "${SCAN_LOCATIONS[$i]}" | tee -a "$SCAN_LOG"
    done
    exit 0
fi

# Start scan
log "🚀 Starting comprehensive scan..."
log ""

START_TIME=$(date +%s)

if $USE_PARALLEL && command -v parallel >/dev/null 2>&1; then
    log_info "Using GNU Parallel for faster scanning ($PARALLEL_JOBS jobs)"

    # Create job file
    for i in "${!SCAN_LOCATIONS[@]}"; do
        echo "${SCAN_LOCATIONS[$i]}"
    done > "$TEMP_DIR/jobs.txt"

    # Export function and variables for parallel
    export -f scan_location
    export DETECTOR_SCRIPT TEMP_DIR
    export RED GREEN YELLOW BLUE CYAN NC

    # Run parallel scans with progress bar
    parallel --bar -j "$PARALLEL_JOBS" scan_location {} "scan" :::: "$TEMP_DIR/jobs.txt"
    echo ""  # New line after progress
else
    if $USE_PARALLEL; then
        log_warn "GNU Parallel not found, falling back to sequential scan"
        log_info "Install with: brew install parallel"
    fi

    # Sequential scan
    for i in "${!SCAN_LOCATIONS[@]}"; do
        location="${SCAN_LOCATIONS[$i]}"
        label="${SCAN_LABELS[$i]}"

        log "Scanning [$((i+1))/$TOTAL_LOCATIONS]: $label"
        scan_location "$location" "$label"
    done
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Analyze results
log ""
log "📊 Analyzing scan results..."

CLEAN_COUNT=0
THREAT_COUNT=0
TIMEOUT_COUNT=0
SKIP_COUNT=0

for result_file in "$TEMP_DIR"/scan_*.txt; do
    [[ -f "$result_file" ]] || continue

    status_file="${result_file}.status"

    if [[ -f "$status_file" ]]; then
        status=$(cat "$status_file")
        case $status in
            CLEAN) ((CLEAN_COUNT++)) ;;
            THREAT) ((THREAT_COUNT++)) ;;
            TIMEOUT) ((TIMEOUT_COUNT++)) ;;
        esac
    elif grep -q "^SKIP:" "$result_file"; then
        ((SKIP_COUNT++))
    fi
done

# Generate summary
cat > "$SUMMARY_FILE" << EOF
================================================================================
COMPREHENSIVE SCAN SUMMARY
================================================================================
Scan Date:        $(date)
Scan Mode:        $SCAN_MODE
Duration:         ${DURATION}s ($(date -ud "@$DURATION" +'%H:%M:%S'))
Detector:         $DETECTOR_SCRIPT

RESULTS:
--------
Total Locations:  $TOTAL_LOCATIONS
Clean:            $CLEAN_COUNT
Threats Found:    $THREAT_COUNT
Timeouts:         $TIMEOUT_COUNT
Skipped:          $SKIP_COUNT

EOF

# List threats if found
if (( THREAT_COUNT > 0 )); then
    cat >> "$SUMMARY_FILE" << EOF

🚨 THREATS DETECTED:
EOF

    for result_file in "$TEMP_DIR"/scan_*.txt; do
        [[ -f "$result_file" ]] || continue
        status_file="${result_file}.status"

        if [[ -f "$status_file" ]] && [[ "$(cat "$status_file")" == "THREAT" ]]; then
            location=$(basename "$result_file" | sed 's/^scan_//; s/_/\//g; s/.txt$//')
            cat >> "$SUMMARY_FILE" << EOF

Location: $location
$(cat "$result_file")

EOF
        fi
    done
fi

# List timeouts if any
if (( TIMEOUT_COUNT > 0 )); then
    cat >> "$SUMMARY_FILE" << EOF

⏱️  TIMEOUTS (>5 minutes):
EOF

    for result_file in "$TEMP_DIR"/scan_*.txt; do
        [[ -f "$result_file" ]] || continue
        status_file="${result_file}.status"

        if [[ -f "$status_file" ]] && [[ "$(cat "$status_file")" == "TIMEOUT" ]]; then
            location=$(basename "$result_file" | sed 's/^scan_//; s/_/\//g; s/.txt$//')
            echo "  - $location" >> "$SUMMARY_FILE"
        fi
    done
fi

cat >> "$SUMMARY_FILE" << EOF

LOGS:
-----
Full Log:    $SCAN_LOG
Summary:     $SUMMARY_FILE

EOF

# Append summary to log
cat "$SUMMARY_FILE" >> "$SCAN_LOG"

# Display summary
log ""
log "════════════════════════════════════════════════════════════════"
cat "$SUMMARY_FILE"
log "════════════════════════════════════════════════════════════════"
log ""

# Final status
if (( THREAT_COUNT > 0 )); then
    log_error "🚨 THREATS DETECTED: $THREAT_COUNT location(s) with malware indicators!"
    log_error "Review full report: $SUMMARY_FILE"
    log_error ""
    log_error "NEXT STEPS:"
    log_error "  1. Review threat details above"
    log_error "  2. DO NOT KILL processes with SIGKILL!"
    log_error "  3. Use SIGSTOP instead: kill -STOP <PID>"
    log_error "  4. Run forensic backup before cleanup"
    log_error "  5. Follow emergency response protocol"
    exit 1
elif (( TIMEOUT_COUNT > 0 )); then
    log_warn "⏱️  Some scans timed out - review manually"
    log_warn "Timeouts: $TIMEOUT_COUNT location(s)"
    exit 2
else
    log_success "✅ SCAN COMPLETE: No threats detected"
    log_success "Scanned $TOTAL_LOCATIONS locations in ${DURATION}s"
    exit 0
fi
