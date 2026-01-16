# ==============================================================================
# OpenCode Configuration
# ==============================================================================
# Creates user config symlinks pointing to global config at /etc/opencode/
# Required for both local dev and Cloud Workstations.
#
# Global config contains:
#   - opencode.json: Vertex AI model configuration
#   - AGENTS.md: Chain-specific AI context
#
# Also sets VERTEX_LOCATION for Vertex AI API calls.
# ==============================================================================

# Set default Vertex AI location
export VERTEX_LOCATION="${VERTEX_LOCATION:-global}"

# Create symlinks to global OpenCode config if it exists
if [ -d /etc/opencode ] && [ ! -L "$HOME/.config/opencode/opencode.json" ]; then
    mkdir -p "$HOME/.config/opencode"
    
    # Link opencode.json (Vertex AI config)
    if [ -f /etc/opencode/opencode.json ]; then
        ln -sf /etc/opencode/opencode.json "$HOME/.config/opencode/opencode.json"
    fi
    
    # Link AGENTS.md (chain-specific AI context)
    if [ -f /etc/opencode/AGENTS.md ]; then
        ln -sf /etc/opencode/AGENTS.md "$HOME/.config/opencode/AGENTS.md"
    fi
fi
