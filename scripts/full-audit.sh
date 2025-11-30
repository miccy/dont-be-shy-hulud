#!/bin/bash
#
# full-audit.sh - Complete security audit for Shai-Hulud 2.0
# https://github.com/miccy/dont-be-shy-hulud
#
# Usage: ./full-audit.sh [path_to_projects]
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
VERSION="1.3.1"

if [[ "${1:-}" == "--version" ]]; then
    echo "$VERSION"
    exit 0
fi
SCAN_PATH="${1:-$HOME/Developer}"
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Unused
# IOC_DIR="$SCRIPT_DIR/../ioc" # Unused
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
echo "Scanning: $SCAN_PATH"
echo "Report: $REPORT_DIR"
echo "Date: $(date)"
echo ""

# Create report directory
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
# PHASE 1: Download current IOCs
# ============================================
echo -e "\n${CYAN}═══ PHASE 1: Update IOC database ═══${NC}"

IOC_SOURCES=(
    "https://raw.githubusercontent.com/tenable/shai-hulud-second-coming-affected-packages/main/list.json"
    "https://raw.githubusercontent.com/DataDog/indicators-of-compromise/main/shai-hulud-2.0/affected-packages.json"
)

mkdir -p "$REPORT_DIR/ioc"

for url in "${IOC_SOURCES[@]}"; do
    filename=$(basename "$url")
    log_info "Downloading IOC: $filename"
    if curl -sL "$url" -o "$REPORT_DIR/ioc/$filename" 2>/dev/null; then
        log_ok "Downloaded: $filename"
    else
        log_medium "Failed to download: $url"
    fi
done

# Extract package names
if [ -f "$REPORT_DIR/ioc/list.json" ]; then
    jq -r '.[].name // empty' "$REPORT_DIR/ioc/list.json" 2>/dev/null | sort -u > "$REPORT_DIR/ioc/malicious-packages.txt" || true
    log_info "Extracted $(wc -l < "$REPORT_DIR/ioc/malicious-packages.txt" | tr -d ' ') known malicious packages"
fi

# ============================================
# PHASE 2: Filesystem Check
# ============================================
echo -e "\n${CYAN}═══ PHASE 2: Filesystem Check ═══${NC}"

# 2.1 Payload files
log_info "Searching for payload files..."
find "$SCAN_PATH" -maxdepth 15 \
    \( -name "setup_bun.js" -o -name "bun_environment.js" \) \
    -type f 2>/dev/null > "$REPORT_DIR/payload-files.txt" || true

if [ -s "$REPORT_DIR/payload-files.txt" ]; then
    while read -r file; do
        log_critical "Payload found: $file"

        # Calculate hash
        if command -v shasum &>/dev/null; then
            hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
            echo "  SHA256: $hash" >> "$REPORT_DIR/findings.log"
        fi
    done < "$REPORT_DIR/payload-files.txt"
else
    log_ok "No payload files found"
fi

# 2.2 TruffleHog cache
log_info "Checking .truffler-cache..."
if [ -d "$HOME/.truffler-cache" ]; then
    log_critical "$HOME/.truffler-cache exists!"
    ls -la "$HOME/.truffler-cache" >> "$REPORT_DIR/findings.log" 2>/dev/null
else
    log_ok "$HOME/.truffler-cache does not exist"
fi

# 2.3 Suspicious workflow files
log_info "Searching for suspicious GitHub workflows..."
find "$SCAN_PATH" -path "*/.github/workflows/*.yaml" -o -path "*/.github/workflows/*.yml" 2>/dev/null | \
    while read -r file; do grep -l "self-hosted" "$file" >> "$REPORT_DIR/suspicious-workflows.txt" || true; done

if [ -s "$REPORT_DIR/suspicious-workflows.txt" ]; then
    while read -r file; do
        if grep -q "discussion" "$file" 2>/dev/null; then
            log_high "Suspicious workflow (discussion + self-hosted): $file"
        else
            log_low "Self-hosted workflow (review manually): $file"
        fi
    done < "$REPORT_DIR/suspicious-workflows.txt"
else
    log_ok "No suspicious workflow files"
fi

# ============================================
# PHASE 3: Dependency Check
# ============================================
echo -e "\n${CYAN}═══ PHASE 3: Dependency Check ═══${NC}"

# 3.1 Search package-lock.json and compare with IOC
log_info "Scanning package-lock.json files..."

if [ -f "$REPORT_DIR/ioc/malicious-packages.txt" ]; then
    find "$SCAN_PATH" -name "package-lock.json" -not -path "*/node_modules/*" 2>/dev/null || true | \
    while read -r lockfile; do
        log_info "Checking: $lockfile"

        # Extract packages from lockfile
        jq -r '.packages | keys[]' "$lockfile" 2>/dev/null | \
        sed 's|node_modules/||g' | \
        while read -r pkg; do
            pkg_name=$(echo "$pkg" | sed 's|@[^/]*/||' | cut -d'/' -f1)
            if grep -qF "$pkg_name" "$REPORT_DIR/ioc/malicious-packages.txt" 2>/dev/null; then
                log_high "Known malicious package: $pkg_name in $lockfile"
            fi
        done
    done
else
    log_medium "IOC list not available - skipping dependency check"
fi

# 3.2 Check preinstall scripts
log_info "Searching for suspicious preinstall scripts..."
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
# PHASE 4: Process and Network Check
# ============================================
echo -e "\n${CYAN}═══ PHASE 4: Process and Network Check ═══${NC}"

# 4.1 Running processes
log_info "Checking running processes..."
ps aux > "$REPORT_DIR/processes.txt" 2>/dev/null

if grep -qE "(bun_environment|trufflehog|setup_bun)" "$REPORT_DIR/processes.txt" 2>/dev/null; then
    log_critical "Suspicious processes running!"
    grep -E "(bun_environment|trufflehog|setup_bun)" "$REPORT_DIR/processes.txt" >> "$REPORT_DIR/findings.log"
else
    log_ok "No suspicious processes"
fi

# 4.2 Network connections
log_info "Checking network connections..."
if command -v lsof &>/dev/null; then
    lsof -i -n > "$REPORT_DIR/network.txt" 2>/dev/null || true
fi

# ============================================
# PHASE 5: Credentials Check
# ============================================
echo -e "\n${CYAN}═══ PHASE 5: Credentials Check ═══${NC}"

check_credential_file() {
    local path="$1"
    local name="$2"
    # local severity="${3:-MEDIUM}" # Unused

    if [ -f "$path" ]; then
        log_medium "$name exists: $path"
        echo "  Potentially compromised - rotation recommended" >> "$REPORT_DIR/findings.log"
    elif [ -d "$path" ]; then
        log_medium "$name directory exists: $path"
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
# PHASE 6: GitHub Check
# ============================================
echo -e "\n${CYAN}═══ PHASE 6: GitHub Check ═══${NC}"

if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    log_info "Checking GitHub repos..."

    # Search Shai-Hulud repos
    gh repo list --limit 500 --json name,description,createdAt 2>/dev/null | \
        jq -r '.[] | select(.description != null) | select(.description | test("hulud|Hulud"; "i")) |
        "REPO: \(.name) | CREATED: \(.createdAt) | DESC: \(.description)"' > "$REPORT_DIR/hulud-repos.txt" || true

    if [ -s "$REPORT_DIR/hulud-repos.txt" ]; then
        while read -r line; do
            log_critical "Shai-Hulud repo found: $line"
        done < "$REPORT_DIR/hulud-repos.txt"
    else
        log_ok "No Shai-Hulud repos"
    fi

    # Check recent repos
    log_info "Checking recently created repos..."
    WEEK_AGO=$(date -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d "7 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)

    gh repo list --limit 100 --json name,createdAt,description 2>/dev/null | \
        jq -r --arg date "$WEEK_AGO" '.[] | select(.createdAt > $date) |
        "\(.name) | \(.createdAt)"' > "$REPORT_DIR/recent-repos.txt" || true

    if [ -s "$REPORT_DIR/recent-repos.txt" ]; then
        log_info "Recently created repos (review manually):"
        cat "$REPORT_DIR/recent-repos.txt"
    fi
else
    log_info "gh CLI not available - skipping GitHub check"
fi

# ============================================
# PHASE 7: npm Check
# ============================================
echo -e "\n${CYAN}═══ PHASE 7: npm Check ═══${NC}"

if command -v npm &>/dev/null; then
    # npm whoami
    if npm whoami &>/dev/null 2>&1; then
        NPM_USER=$(npm whoami 2>/dev/null)
        log_info "npm user: $NPM_USER"

        # Check published packages
        log_info "Checking published packages..."
        npm access ls-packages 2>/dev/null > "$REPORT_DIR/npm-packages.txt" || true

        if [ -s "$REPORT_DIR/npm-packages.txt" ]; then
            log_info "Your packages:"
            cat "$REPORT_DIR/npm-packages.txt"
            log_medium "Recommendation: Check recent publications of these packages"
        fi
    else
        log_info "npm is not authenticated"
    fi

    # npm audit
    log_info "Running npm audit in available projects..."
    find "$SCAN_PATH" -name "package.json" -not -path "*/node_modules/*" -maxdepth 5 2>/dev/null | \
    head -10 | while read -r pkg; do
        dir=$(dirname "$pkg")
        if [ -f "$dir/package-lock.json" ]; then
            log_info "Audit: $dir"
            (cd "$dir" && npm audit --json 2>/dev/null || echo '{"metadata":{"vulnerabilities":{"high":0}}}' | jq -r '.metadata.vulnerabilities.high // 0' || echo "0") | \
            read -r high_vulns || high_vulns=0

            if [ "$high_vulns" != "0" ] && [ -n "$high_vulns" ]; then
                log_high "npm audit: $high_vulns high vulnerabilities in $dir"
            fi
        fi
    done
else
    log_info "npm is not installed"
fi

# ============================================
# PHASE 8: System Integrity Check
# ============================================
echo -e "\n${CYAN}═══ PHASE 8: System Integrity Check ═══${NC}"

if [ -f "/etc/sudoers.d/runner" ]; then
    log_critical "Privilege Escalation Artifact: /etc/sudoers.d/runner found!"
    ls -la /etc/sudoers.d/runner >> "$REPORT_DIR/findings.log"
fi

if [ -f "/tmp/resolved.conf" ]; then
    log_high "DNS Hijacking Artifact: /tmp/resolved.conf found!"
fi

# ============================================
# SUMMARY
# ============================================
echo ""
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                      AUDIT SUMMARY                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "Critical: ${RED}$CRITICAL${NC}"
echo -e "High:     ${RED}$HIGH${NC}"
echo -e "Medium:   ${YELLOW}$MEDIUM${NC}"
echo -e "Low:      ${YELLOW}$LOW${NC}"
echo ""
echo "Report saved: $REPORT_DIR"
echo ""

if [ $CRITICAL -gt 0 ] || [ $HIGH -gt 0 ]; then
    echo -e "${RED}⚠️  WARNING: Critical or high findings detected!${NC}"
    echo ""
    echo "Immediate actions:"
    echo "1. Isolate system from network"
    echo "2. Review $REPORT_DIR/findings.log"
    echo "3. Follow docs/REMEDIATION.md"
    echo "4. Rotate ALL credentials"
elif [ $MEDIUM -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Medium findings detected - review recommended${NC}"
else
    echo -e "${GREEN}✅ No significant findings${NC}"
    echo "Recommendation: Check docs/PREVENTION.md for hardening"
fi

# Generate HTML report
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
