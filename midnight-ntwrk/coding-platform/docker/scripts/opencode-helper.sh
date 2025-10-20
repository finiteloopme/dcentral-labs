#!/bin/bash
# OpenCode helper script for Midnight Workstation

# Check if API key is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 OpenCode AI Assistant"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  API key not set!"
    echo ""
    echo "To use OpenCode, you need an Anthropic API key."
    echo ""
    echo "Steps:"
    echo "1. Get your API key from: https://console.anthropic.com/"
    echo "2. Set it in your terminal:"
    echo "   export ANTHROPIC_API_KEY='your-api-key-here'"
    echo "3. Run opencode again"
    echo ""
    echo "For persistence, add the export to ~/.bashrc"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

# Run OpenCode with the API key
echo "Starting OpenCode AI Assistant..."
echo "Model: ${OPENCODE_MODEL:-claude-3.5-sonnet}"
echo "Type 'exit' or Ctrl+D to quit"
echo ""

exec opencode "$@"