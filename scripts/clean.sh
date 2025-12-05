#!/bin/bash
# Global cleanup script for monorepo
# Removes all node_modules, lockfiles, and temporary directories

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🧹 Global Cleanup for dont-be-shy-hulud"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd "$ROOT_DIR"

# Count before cleanup
echo "📊 Scanning for cleanup targets..."
NODE_MODULES_COUNT=$(find . -name "node_modules" -type d -prune 2>/dev/null | wc -l | tr -d ' ')
LOCKFILES_COUNT=$(find . \( -name "package-lock.json" -o -name "bun.lockb" -o -name "yarn.lock" -o -name "pnpm-lock.yaml" \) -type f 2>/dev/null | wc -l | tr -d ' ')

echo "  - node_modules directories: $NODE_MODULES_COUNT"
echo "  - Lock files: $LOCKFILES_COUNT"
echo ""

# Dry run check
if [[ "$1" == "--dry-run" ]]; then
    echo "${YELLOW}🔍 DRY RUN - showing what would be deleted:${NC}"
    echo ""
    echo "node_modules directories:"
    find . -name "node_modules" -type d -prune 2>/dev/null || true
    echo ""
    echo "Lock files:"
    find . \( -name "package-lock.json" -o -name "bun.lockb" -o -name "yarn.lock" -o -name "pnpm-lock.yaml" \) -type f 2>/dev/null || true
    echo ""
    echo "Temporary directories:"
    find . \( -name ".turbo" -o -name ".astro" -o -name "dist" -o -name ".next" -o -name ".nuxt" -o -name ".cache" -o -name ".parcel-cache" \) -type d -prune 2>/dev/null || true
    echo ""
    echo "Run without --dry-run to actually delete."
    exit 0
fi

# Confirm
if [[ "$1" != "-y" && "$1" != "--yes" ]]; then
    read -p "⚠️  This will delete all node_modules, lockfiles, and temp directories. Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

echo ""
echo "🗑️  Removing node_modules directories..."
find . -name "node_modules" -type d -prune -exec rm -rf {} \; 2>/dev/null || true

echo "🗑️  Removing lock files..."
find . -name "package-lock.json" -type f -delete 2>/dev/null || true
find . -name "bun.lockb" -type f -delete 2>/dev/null || true
find . -name "yarn.lock" -type f -delete 2>/dev/null || true
find . -name "pnpm-lock.yaml" -type f -delete 2>/dev/null || true
# Keep bun.lock in root (it's the main lockfile)
# rm -f "$ROOT_DIR/bun.lock" 2>/dev/null || true

echo "🗑️  Removing Turbo cache..."
find . -name ".turbo" -type d -prune -exec rm -rf {} \; 2>/dev/null || true

echo "🗑️  Removing build outputs..."
find . -name "dist" -type d -prune -exec rm -rf {} \; 2>/dev/null || true
find . -name ".astro" -type d -prune -exec rm -rf {} \; 2>/dev/null || true
find . -name ".next" -type d -prune -exec rm -rf {} \; 2>/dev/null || true
find . -name ".nuxt" -type d -prune -exec rm -rf {} \; 2>/dev/null || true

echo "🗑️  Removing cache directories..."
find . -name ".cache" -type d -prune -exec rm -rf {} \; 2>/dev/null || true
find . -name ".parcel-cache" -type d -prune -exec rm -rf {} \; 2>/dev/null || true

echo "🗑️  Removing TypeScript build info..."
find . -name "*.tsbuildinfo" -type f -delete 2>/dev/null || true
find . -name "tsconfig.tsbuildinfo" -type f -delete 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "To reinstall dependencies, run:"
echo "  bun install"
