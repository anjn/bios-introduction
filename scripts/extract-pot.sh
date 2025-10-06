#!/bin/bash
# Extract translatable strings from Japanese source to POT template

set -e  # Exit on error

echo "📝 Extracting translatable strings from Japanese source..."
echo "=========================================================="

# Create po directory if it doesn't exist
mkdir -p po

# Extract strings using mdbook-i18n-helpers
MDBOOK_OUTPUT='{"xgettext": {"pot-file": "po/messages.pot"}}' \
  mdbook build -d po

# Check if extraction was successful
if [ -f "po/messages.pot" ]; then
    echo "✅ Successfully extracted strings to po/messages.pot"

    # Show statistics
    msgcount=$(grep -c "^msgid" po/messages.pot || true)
    echo "📊 Total messages: $msgcount"

    # If en.po exists, update it
    if [ -f "po/en.po" ]; then
        echo ""
        echo "🔄 Updating existing English translation file..."
        msgmerge --update --backup=none po/en.po po/messages.pot

        # Show translation statistics
        translated=$(msggrep --translated -o /dev/null po/en.po 2>&1 | grep -c "^msgid" || echo "0")
        untranslated=$(msggrep --untranslated -o /dev/null po/en.po 2>&1 | grep -c "^msgid" || echo "0")
        fuzzy=$(msggrep --only-fuzzy -o /dev/null po/en.po 2>&1 | grep -c "^msgid" || echo "0")

        echo "📊 Translation status:"
        echo "  ✓ Translated:   $translated"
        echo "  ⚠ Fuzzy:        $fuzzy"
        echo "  ✗ Untranslated: $untranslated"
    else
        echo ""
        echo "ℹ️  No English translation file found."
        echo "   To create one, run:"
        echo "   msginit -i po/messages.pot -l en -o po/en.po"
    fi
else
    echo "❌ Failed to extract strings"
    exit 1
fi

echo ""
echo "Next steps:"
echo "1. Edit po/en.po with a PO editor (e.g., Poedit)"
echo "2. Run ./scripts/build-all-languages.sh to build translated versions"
