#!/bin/bash
#
# set-language.sh - Removes unwanted language files from the repository
# Usage: ./scripts/set-language.sh [en|cs|both]
#

set -euo pipefail

LANG="${1:-both}"

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
