#!/usr/bin/env bash
# =============================================================================
# gh-scan-exfil.sh - GitHub API Scanner for Shai-Hulud Exfiltration Repos
# =============================================================================
#
# Scans GitHub for repositories that may contain exfiltrated data from
# Shai-Hulud 2.0 attacks. Uses GitHub CLI (gh) for API access.
#
# Usage:
#   ./gh-scan-exfil.sh [options]
#
# Options:
#   --user <username>     Scan specific user's repos
#   --org <org>           Scan organization's repos
#   --all                 Scan all accessible repos (authenticated user)
#   --runners             List self-hosted runners
#   --workflows           Audit recent workflow changes
#   --dry-run             Show what would be scanned without making API calls
#   --json                Output results in JSON format
#   --verbose             Show detailed output
#   --help                Show this help message
#
# Requirements:
#   - GitHub CLI (gh) installed and authenticated
#   - jq for JSON processing
#
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Patterns for detection
EXFIL_DESCRIPTION_PATTERNS=(
    "Sha1-Hulud: The Second Coming"
    "Shai-Hulud Migration"
    "Shai-Hulud: The Second Coming"
)

# Random 18-char repo name pattern
RANDOM_REPO_PATTERN='^[0-9a-z]{18}$'

# Known malicious runner names
MALICIOUS_RUNNER_NAMES=(
    "SHA1HULUD"
    "SHAIHULUD"
    "shai-hulud"
)

# Suspicious workflow file patterns
SUSPICIOUS_WORKFLOW_PATTERNS=(
    "discussion.yaml"
    "formatter_*.yml"
    "SHA1HULUD"
    "self-hosted"
)

# Global variables
VERBOSE=false
DRY_RUN=false
JSON_OUTPUT=false
SCAN_USER=""
SCAN_ORG=""
SCAN_ALL=false
CHECK_RUNNERS=false
CHECK_WORKFLOWS=false
FOUND_ISSUES=0

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_warn() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${YELLOW}[WARN]${NC} $1" >&2
    fi
}

log_error() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${RED}[ERROR]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${GREEN}[OK]${NC} $1"
    fi
}

log_alert() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${RED}[ALERT]${NC} $1" >&2
    fi
    ((FOUND_ISSUES++)) || true
}

log_verbose() {
    if [[ "$VERBOSE" == true && "$JSON_OUTPUT" == false ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

show_help() {
    head -35 "$0" | tail -30
    exit 0
}

check_dependencies() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed. Install it from https://cli.github.com/"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed. Install it with: brew install jq"
        exit 1
    fi

    # Check if gh is authenticated
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated. Run: gh auth login"
        exit 1
    fi

    log_verbose "Dependencies check passed"
}

# =============================================================================
# Scanning Functions
# =============================================================================

scan_repo_description() {
    local repo="$1"
    local description="$2"

    for pattern in "${EXFIL_DESCRIPTION_PATTERNS[@]}"; do
        if [[ "$description" == *"$pattern"* ]]; then
            log_alert "🚨 EXFILTRATION REPO DETECTED: $repo"
            log_alert "   Description contains: '$pattern'"
            return 0
        fi
    done
    return 1
}

scan_repo_name() {
    local repo="$1"
    local name
    name=$(basename "$repo")

    if [[ "$name" =~ $RANDOM_REPO_PATTERN ]]; then
        log_warn "⚠️  Suspicious random repo name: $repo (matches [0-9a-z]{18})"
        return 0
    fi
    return 1
}

scan_user_repos() {
    local user="$1"
    local repos
    local count=0
    local suspicious=0

    log_info "Scanning repositories for user: $user"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would scan repos for user: $user"
        return 0
    fi

    # Get all repos for user
    repos=$(gh repo list "$user" --json name,description,isPrivate,createdAt --limit 1000 2>/dev/null || echo "[]")

    if [[ "$repos" == "[]" ]]; then
        log_warn "No repos found or access denied for user: $user"
        return 0
    fi

    count=$(echo "$repos" | jq length)
    log_info "Found $count repositories"

    # Check each repo
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local name description full_name
        name=$(echo "$repo" | jq -r '.name')
        description=$(echo "$repo" | jq -r '.description // ""')
        full_name="$user/$name"

        log_verbose "Checking: $full_name"

        # Check description
        if scan_repo_description "$full_name" "$description"; then
            ((suspicious++)) || true
        fi

        # Check name pattern
        if scan_repo_name "$full_name"; then
            ((suspicious++)) || true
        fi
    done

    if [[ $suspicious -eq 0 ]]; then
        log_success "No suspicious repos found for user: $user"
    fi
}

scan_org_repos() {
    local org="$1"
    local repos
    local count=0

    log_info "Scanning repositories for organization: $org"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would scan repos for org: $org"
        return 0
    fi

    # Get all repos for org
    repos=$(gh repo list "$org" --json name,description,isPrivate,createdAt --limit 1000 2>/dev/null || echo "[]")

    if [[ "$repos" == "[]" ]]; then
        log_warn "No repos found or access denied for org: $org"
        return 0
    fi

    count=$(echo "$repos" | jq length)
    log_info "Found $count repositories"

    # Check each repo
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local name description full_name
        name=$(echo "$repo" | jq -r '.name')
        description=$(echo "$repo" | jq -r '.description // ""')
        full_name="$org/$name"

        log_verbose "Checking: $full_name"

        # Check description
        scan_repo_description "$full_name" "$description" || true

        # Check name pattern
        scan_repo_name "$full_name" || true
    done
}

scan_self_hosted_runners() {
    local target="$1"
    local runners

    log_info "Checking self-hosted runners for: $target"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would check runners for: $target"
        return 0
    fi

    # Try to list runners (requires admin access)
    runners=$(gh api "repos/$target/actions/runners" 2>/dev/null || echo '{"runners":[]}')

    local runner_count
    runner_count=$(echo "$runners" | jq '.runners | length')

    if [[ "$runner_count" -gt 0 ]]; then
        log_info "Found $runner_count self-hosted runner(s)"

        echo "$runners" | jq -c '.runners[]' | while read -r runner; do
            local runner_name runner_status
            runner_name=$(echo "$runner" | jq -r '.name')
            runner_status=$(echo "$runner" | jq -r '.status')

            # Check for malicious runner names
            for pattern in "${MALICIOUS_RUNNER_NAMES[@]}"; do
                if [[ "$runner_name" == *"$pattern"* ]]; then
                    log_alert "🚨 MALICIOUS RUNNER DETECTED: $runner_name (status: $runner_status)"
                fi
            done

            log_verbose "Runner: $runner_name (status: $runner_status)"
        done
    else
        log_verbose "No self-hosted runners found (or no access)"
    fi
}

scan_workflows() {
    local target="$1"
    local workflows

    log_info "Auditing workflows for: $target"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would audit workflows for: $target"
        return 0
    fi

    # List workflow files
    workflows=$(gh api "repos/$target/contents/.github/workflows" 2>/dev/null || echo "[]")

    if [[ "$workflows" == "[]" ]]; then
        log_verbose "No workflows found or access denied"
        return 0
    fi

    echo "$workflows" | jq -c '.[]' | while read -r workflow; do
        local workflow_name
        workflow_name=$(echo "$workflow" | jq -r '.name')

        # Check for suspicious workflow names
        for pattern in "${SUSPICIOUS_WORKFLOW_PATTERNS[@]}"; do
            if [[ "$workflow_name" == *"$pattern"* ]]; then
                log_alert "⚠️  Suspicious workflow file: $workflow_name in $target"
            fi
        done

        log_verbose "Workflow: $workflow_name"
    done

    # Check for discussion.yaml specifically (backdoor trigger)
    if gh api "repos/$target/contents/.github/workflows/discussion.yaml" &>/dev/null; then
        log_alert "🚨 BACKDOOR WORKFLOW DETECTED: discussion.yaml in $target"
        log_alert "   This workflow may be triggered via repository discussions!"
    fi
}

search_exfil_repos_global() {
    log_info "Searching GitHub for known exfiltration patterns..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would search GitHub for exfiltration patterns"
        return 0
    fi

    # Search for repos with known description patterns
    for pattern in "${EXFIL_DESCRIPTION_PATTERNS[@]}"; do
        log_verbose "Searching for: $pattern"

        local results
        results=$(gh search repos "$pattern" --json fullName,description --limit 100 2>/dev/null || echo "[]")

        local count
        count=$(echo "$results" | jq length)

        if [[ "$count" -gt 0 ]]; then
            log_alert "🚨 Found $count repos matching pattern: '$pattern'"

            echo "$results" | jq -c '.[]' | while read -r repo; do
                local full_name description
                full_name=$(echo "$repo" | jq -r '.fullName')
                description=$(echo "$repo" | jq -r '.description // ""')
                log_alert "   - $full_name"
                log_verbose "     Description: $description"
            done
        fi
    done
}

# =============================================================================
# JSON Output Functions
# =============================================================================

output_json_start() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        echo '{"scan_results": {'
        echo '  "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",'
        echo '  "findings": ['
    fi
}

output_json_end() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        echo '  ],'
        echo '  "total_issues": '$FOUND_ISSUES
        echo '}}'
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                SCAN_USER="$2"
                shift 2
                ;;
            --org)
                SCAN_ORG="$2"
                shift 2
                ;;
            --all)
                SCAN_ALL=true
                shift
                ;;
            --runners)
                CHECK_RUNNERS=true
                shift
                ;;
            --workflows)
                CHECK_WORKFLOWS=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
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
    check_dependencies

    # Start JSON output if needed
    output_json_start

    # Banner
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo ""
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}     🔍 ${YELLOW}Shai-Hulud Exfiltration Scanner${NC}                       ${RED}║${NC}"
        echo -e "${RED}║${NC}     GitHub API Scanner for Compromised Repositories          ${RED}║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi

    # Determine what to scan
    if [[ -n "$SCAN_USER" ]]; then
        scan_user_repos "$SCAN_USER"

        if [[ "$CHECK_RUNNERS" == true ]]; then
            # Scan runners for each repo
            gh repo list "$SCAN_USER" --json name --limit 100 2>/dev/null | jq -r '.[].name' | while read -r repo; do
                scan_self_hosted_runners "$SCAN_USER/$repo"
            done
        fi

        if [[ "$CHECK_WORKFLOWS" == true ]]; then
            gh repo list "$SCAN_USER" --json name --limit 100 2>/dev/null | jq -r '.[].name' | while read -r repo; do
                scan_workflows "$SCAN_USER/$repo"
            done
        fi
    fi

    if [[ -n "$SCAN_ORG" ]]; then
        scan_org_repos "$SCAN_ORG"

        if [[ "$CHECK_RUNNERS" == true ]]; then
            gh repo list "$SCAN_ORG" --json name --limit 100 2>/dev/null | jq -r '.[].name' | while read -r repo; do
                scan_self_hosted_runners "$SCAN_ORG/$repo"
            done
        fi

        if [[ "$CHECK_WORKFLOWS" == true ]]; then
            gh repo list "$SCAN_ORG" --json name --limit 100 2>/dev/null | jq -r '.[].name' | while read -r repo; do
                scan_workflows "$SCAN_ORG/$repo"
            done
        fi
    fi

    if [[ "$SCAN_ALL" == true ]]; then
        # Get authenticated user
        local current_user
        current_user=$(gh api user --jq '.login')
        log_info "Scanning repos for authenticated user: $current_user"
        scan_user_repos "$current_user"

        # Also do global search
        search_exfil_repos_global
    fi

    # If nothing specified, show help
    if [[ -z "$SCAN_USER" && -z "$SCAN_ORG" && "$SCAN_ALL" == false ]]; then
        log_error "No scan target specified. Use --user, --org, or --all"
        show_help
    fi

    # End JSON output
    output_json_end

    # Summary
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo ""
        if [[ $FOUND_ISSUES -gt 0 ]]; then
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${RED}⚠️  SCAN COMPLETE: Found $FOUND_ISSUES potential issue(s)${NC}"
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            exit 1
        else
            echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}✅ SCAN COMPLETE: No issues found${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
            exit 0
        fi
    fi
}

main "$@"
