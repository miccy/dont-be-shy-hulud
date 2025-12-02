#!/bin/bash
VERSION="1.5.0"

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
        rm -rf cs/
        echo "Done. Repository is now English-only."
        ;;
    "cs")
        echo "Removing English root files..."
        # Remove English versions where Czech exists in cs/
        [ -f cs/README.md ] && rm README.md
        [ -f cs/CONTRIBUTING.md ] && rm CONTRIBUTING.md
        [ -f cs/CODE_OF_CONDUCT.md ] && rm CODE_OF_CONDUCT.md
        [ -f cs/SECURITY.md ] && rm SECURITY.md
        [ -f cs/AGENTS.md ] && rm AGENTS.md

        # Remove English docs
        rm -rf docs/

        echo "Promoting Czech files to root..."
        cp -r cs/* .
        rm -rf cs/

        echo "Done. Repository is now Czech-only."
        ;;
    "both")
        echo "Keeping both languages (default)."
        ;;
    *)
        echo "Usage: $0 [en|cs|both]"
        exit 1
        ;;
esac
