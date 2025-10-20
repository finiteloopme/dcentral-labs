#!/bin/bash
# OpenCode AI Assistant - Wrapper Script

# Check if the functional AI assistant script exists
AI_SCRIPT="/opt/midnight/bin/opencode-ai"

if [ -f "$AI_SCRIPT" ] && [ -x "$AI_SCRIPT" ]; then
    # Use the functional AI assistant
    exec "$AI_SCRIPT" "$@"
else
    # Fallback if script not found
    echo "🤖 OpenCode AI Assistant"
    echo "========================"
    echo ""
    echo "Error: AI assistant script not found at $AI_SCRIPT"
    echo ""
    echo "Try these alternatives:"
    echo "  • midnight new <project> - Create new project"
    echo "  • midnight compile - Compile contracts"
    echo "  • compactc <file> - Compile Compact files"
    echo ""
    echo "For VS Code: http://localhost:8080"
fi