#!/bin/bash
# OpenCode AI wrapper - ensures proper configuration before running

# Configure AI credentials
if [ -f /opt/midnight/bin/configure-ai ]; then
    source /opt/midnight/bin/configure-ai >/dev/null 2>&1
fi

# Check if opencode-ai is installed
if command -v opencode >/dev/null 2>&1; then
    # Run the real opencode with proper environment
    exec opencode "$@"
else
    echo "🤖 OpenCode AI Assistant"
    echo "========================"
    echo ""
    echo "OpenCode is being installed..."
    echo "Please wait a moment and try again."
    echo ""
    echo "If the issue persists, run:"
    echo "  npm install -g opencode-ai"
    echo ""
    echo "Then configure your AI provider:"
    echo "  • For Vertex AI: gcloud auth application-default login"
    echo "  • For OpenAI: export OPENAI_API_KEY='your-key'"
    echo "  • For Anthropic: export ANTHROPIC_API_KEY='your-key'"
fi