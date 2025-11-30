#!/bin/bash
#
# release.sh - Interactive release automation script
# Usage: ./scripts/release.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}Error: You have uncommitted changes.${NC}"
    echo "Please commit or stash them before running the release script."
    git status --short
    exit 1
fi

# 2. Check branch (must be on dev or *-dev)
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "dev" && "$CURRENT_BRANCH" != *"-dev" ]]; then
    echo -e "${RED}Error: You must be on 'dev' or a '*-dev' branch to start a release.${NC}"
    echo "Current branch: $CURRENT_BRANCH"
    echo "Run: git checkout dev"
    exit 1
fi

# 3. Get current version
CURRENT_VERSION=$(grep -m 1 "^## \[[0-9]\+\.[0-9]\+\.[0-9]\+\]" CHANGELOG.md | sed -E 's/## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/')
echo -e "${BLUE}Current version: ${GREEN}$CURRENT_VERSION${NC}"

# 4. Ask for new version
echo -e "\nEnter new version number (e.g., 1.4.0):"
read -r NEW_VERSION

if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Use Semantic Versioning (X.Y.Z)${NC}"
    exit 1
fi

if [ "$NEW_VERSION" == "$CURRENT_VERSION" ]; then
    echo -e "${RED}Error: New version must be different from current version.${NC}"
    exit 1
fi

# 5. Create release branch
RELEASE_BRANCH="preview/v$NEW_VERSION"
echo -e "\n${BLUE}Creating preview branch: ${GREEN}$RELEASE_BRANCH${NC}"
git checkout -b "$RELEASE_BRANCH"

# 6. Update CHANGELOG.md
echo -e "\n${BLUE}Updating CHANGELOG.md...${NC}"
DATE=$(date +%Y-%m-%d)
HEADER="## [$NEW_VERSION] - $DATE"

if grep -q "## \[Unreleased\]" CHANGELOG.md; then
    echo "Please add the following header to CHANGELOG.md:"
    echo -e "${YELLOW}$HEADER${NC}"
else
    # Insert at line 8
    sed -i.bak "8i\\
$HEADER\\
\\
### Added\\
- \\
\\
" CHANGELOG.md && rm CHANGELOG.md.bak
fi

# 6b. Append comparison link
echo -e "\n${BLUE}Appending comparison link...${NC}"
REPO_URL="https://github.com/miccy/dont-be-shy-hulud"
LINK="[$NEW_VERSION]: $REPO_URL/compare/v$CURRENT_VERSION...v$NEW_VERSION"
# Ensure newline before link if not present (though echo >> adds one)
echo "$LINK" >> CHANGELOG.md

# 7. Open Editor
echo -e "${YELLOW}Opening CHANGELOG.md. Please fill in the release notes.${NC}"
echo "Save and close the file when done."

if command -v code &> /dev/null; then
    code -w CHANGELOG.md
elif [ -n "$EDITOR" ]; then
    $EDITOR CHANGELOG.md
elif command -v nano &> /dev/null; then
    nano CHANGELOG.md
elif command -v vim &> /dev/null; then
    vim CHANGELOG.md
elif command -v vi &> /dev/null; then
    vi CHANGELOG.md
else
    echo "Press [Enter] when you have finished editing CHANGELOG.md"
    read -r
fi

# 8. Sync versions
echo -e "\n${BLUE}Synchronizing version numbers...${NC}"
./scripts/sync-version.sh

# 9. Commit and Push
echo -e "\n${YELLOW}Ready to prepare release v$NEW_VERSION.${NC}"
echo "This will:"
echo "  1. Commit changes to branch '$RELEASE_BRANCH'"
echo "  2. Push branch to origin"
echo -e "Continue? [y/N]"
read -r CONFIRM

if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
    git add CHANGELOG.md scripts/
    git commit -m "chore: release v$NEW_VERSION"

    echo -e "\n${BLUE}Pushing branch to GitHub...${NC}"
    git push -u origin "$RELEASE_BRANCH"

    echo -e "\n${GREEN}✅ Release branch created!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open a Pull Request: https://github.com/miccy/dont-be-shy-hulud/compare/main...$RELEASE_BRANCH"
    echo "2. Review and merge the PR into 'main' (Ensure 'Merge commit' or 'Rebase' is used to keep the commit message)"
    echo "3. Wait for the GitHub Action to automatically create the Release and Tag"
else
    echo -e "${RED}Release cancelled.${NC}"
    # Cleanup branch if desired? No, keep it safe.
    echo "You are on branch $RELEASE_BRANCH. To go back: git checkout dev"
    exit 0
fi
