#!/bin/bash
VERSION="1.5.1"

if [[ "$1" == "--version" ]]; then
    echo "$VERSION"
    exit 0
fi
#
# set-language.sh - Removes unwanted language files from the repository
# Usage: ./scripts/set-language.sh [en|cs|both]
#

set -euo pipefail

LANG="${1:-both}"

# Update CodeRabbit config if it exists
if [ -f ".coderabbit.yaml" ]; then
    if [ "$LANG" == "cs" ]; then
        sed -i.bak 's/language: "en-US"/language: "cs-CZ"/' .coderabbit.yaml && rm .coderabbit.yaml.bak
        echo "  ✓ Updated CodeRabbit language to cs-CZ"
    elif [ "$LANG" == "en" ]; then
        sed -i.bak 's/language: "cs-CZ"/language: "en-US"/' .coderabbit.yaml && rm .coderabbit.yaml.bak
        echo "  ✓ Updated CodeRabbit language to en-US"
    fi
fi

echo "Setting repository language to: $LANG"

case "$LANG" in
    "en")
        echo "Removing Czech files..."
        rm -rf packages/docs-content/cs/
        echo "Done. Repository is now English-only."
        ;;
    "cs")
        echo "Removing English docs..."
        rm -rf packages/docs-content/en/

        echo "Promoting Czech files..."
        # Move CS content to EN location for Astro
        mv packages/docs-content/cs packages/docs-content/en

        echo "Done. Repository is now Czech-only."
        ;;
    "both")
        echo "Keeping both languages (default)."
        ;;
    "--help"|"-h")
        echo "Usage: $0 [en|cs|both]"
        echo ""
        echo "Options:"
        echo "  en    - Remove Czech files, keep English only"
        echo "  cs    - Remove English files, keep Czech only"
        echo "  both  - Keep both languages (default)"
        exit 0
        ;;
    *)
        echo "Usage: $0 [en|cs|both]"
        exit 1
        ;;
esac
