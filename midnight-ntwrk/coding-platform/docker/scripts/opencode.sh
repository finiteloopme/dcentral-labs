#!/bin/bash
# OpenCode AI Assistant - Interactive Mode

echo "🤖 OpenCode AI Assistant"
echo "========================"
echo ""
echo "Welcome to OpenCode - Your AI Coding Assistant"
echo ""

# Check for real opencode installation in node_modules or system
for path in /usr/local/lib/node_modules/@opencode/cli/bin/opencode \
            /usr/local/lib/node_modules/opencode/bin/opencode \
            /usr/lib/node_modules/@opencode/cli/bin/opencode \
            /usr/lib/node_modules/opencode/bin/opencode; do
    if [ -f "$path" ]; then
        echo "Found OpenCode at: $path"
        exec node "$path" "$@"
        exit 0
    fi
done

# If no real opencode found, provide helpful interface
echo "OpenCode CLI is not fully installed, but you have several options:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 🌐 Use VS Code with AI Extensions"
echo "   Open: http://localhost:8443"
echo "   • Install GitHub Copilot extension"
echo "   • Install Continue extension for AI chat"
echo ""
echo "2. 💻 Use Web Terminal"
echo "   Open: http://localhost:7681"
echo "   • Full bash environment"
echo "   • Install AI tools via npm"
echo ""
echo "3. 🔧 Install OpenCode Manually"
echo "   Run: npm install -g opencode"
echo "   Or: npm install -g @opencode/cli"
echo ""
echo "4. 🚀 Quick AI-Powered Commands"
echo "   • midnight new <project> - Create new project"
echo "   • midnight compile - Compile contracts"
echo "   • midnight test - Run tests"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "For immediate coding help, use VS Code at http://localhost:8443"
echo ""

# If arguments were provided, suggest alternatives
if [ $# -gt 0 ]; then
    echo "You tried to run: opencode $@"
    echo ""
    echo "Alternative commands:"
    echo "  • For new project: midnight new $1"
    echo "  • For compilation: compactc $1"
    echo "  • For testing: midnight test"
    echo ""
fi