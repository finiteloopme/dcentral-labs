#!/bin/bash
# OpenCode AI wrapper - ensures proper configuration before running

# Clean up any invalid GOOGLE_APPLICATION_CREDENTIALS
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    if [ "$GOOGLE_APPLICATION_CREDENTIALS" = "/dev/null" ] || [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        unset GOOGLE_APPLICATION_CREDENTIALS
    fi
fi

# Ensure authentication is configured
if [ -f /opt/midnight/bin/auto-auth ] && [ -z "$GOOGLE_AUTH_CONFIGURED" ]; then
    source /opt/midnight/bin/auto-auth
fi

# Configure AI credentials
if [ -f /opt/midnight/bin/configure-ai ]; then
    source /opt/midnight/bin/configure-ai >/dev/null 2>&1
fi

# Check if OpenCode config exists, create if not
if [ ! -f "$HOME/.config/opencode/opencode.json" ]; then
    echo "Creating OpenCode configuration..."
    if [ -x /usr/local/bin/configure-opencode ]; then
        /usr/local/bin/configure-opencode
    elif [ -x /opt/midnight/bin/configure-opencode ]; then
        /opt/midnight/bin/configure-opencode
    fi
fi

# Check if opencode-ai is installed
if command -v opencode-ai >/dev/null 2>&1; then
    # Run opencode-ai directly
    exec opencode-ai "$@"
elif command -v opencode >/dev/null 2>&1; then
    # Run opencode if that's what's installed
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
    
    if [ -z "$GCP_PROJECT_ID" ] && [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Then configure your AI provider:"
        echo "  • For Vertex AI: This should work automatically in Cloud Workstations"
        echo "  • For OpenAI: export OPENAI_API_KEY='your-key'"
        echo "  • For Anthropic: export ANTHROPIC_API_KEY='your-key'"
    else
        echo "AI provider configured:"
        [ -n "$GCP_PROJECT_ID" ] && echo "  • Vertex AI (Project: $GCP_PROJECT_ID)"
        [ -n "$OPENAI_API_KEY" ] && echo "  • OpenAI"
        [ -n "$ANTHROPIC_API_KEY" ] && echo "  • Anthropic"
    fi
fi