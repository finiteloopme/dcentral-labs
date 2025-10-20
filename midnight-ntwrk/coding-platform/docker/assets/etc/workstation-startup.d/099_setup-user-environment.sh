#!/bin/bash
#
# Setup user environment - runs early to ensure everything is ready
#

echo "Setting up user environment..."

# For Cloud Workstations, setup happens for the 'user' account
USER_HOME="/home/user"

# Ensure the user home exists
if [ -d "$USER_HOME" ]; then
    # Create necessary directories
    mkdir -p $USER_HOME/.local/share/opencode/log
    mkdir -p $USER_HOME/.config/opencode
    
    # Create or update .bashrc with welcome message
    if [ ! -f "$USER_HOME/.bashrc" ]; then
        touch "$USER_HOME/.bashrc"
    fi
    
    # Create a separate welcome script instead of modifying bashrc
    # This avoids syntax errors from bashrc corruption
    WELCOME_SCRIPT="$USER_HOME/.midnight-welcome.sh"
    cat > "$WELCOME_SCRIPT" << 'EOF'
#!/bin/bash
# Midnight Workstation Welcome Message

# Auto-detect and export GCP project ID for Cloud Workstations
if [ -z "$GCP_PROJECT_ID" ] && [ -n "$CLOUD_WORKSTATIONS_CONFIG_DIRECTORY" ]; then
    export GCP_PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
fi

if [ -z "$MIDNIGHT_WELCOME_SHOWN" ]; then
    export MIDNIGHT_WELCOME_SHOWN=1
    echo "=========================================="
    echo "Midnight Development Workstation"
    echo "=========================================="
    echo ""
    echo "Services:"
    echo "  • Code OSS IDE (current window)"
    echo "  • Proof Server: http://localhost:8081"
    echo ""
    echo "Tools:"
    echo "  • opencode - AI assistant (Vertex AI)"
    echo "  • midnight - Midnight CLI"
    echo "  • compactc - Compact compiler"
    echo ""
    if [ -n "$GCP_PROJECT_ID" ]; then
        echo "GCP Project: $GCP_PROJECT_ID"
        echo ""
    fi
    echo "Quick start: Run 'opencode' for AI assistance"
    echo ""
fi
EOF
    chmod +x "$WELCOME_SCRIPT"
    
    # Add a single line to source our welcome script if not already there
    if ! grep -q "midnight-welcome.sh" "$USER_HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$USER_HOME/.bashrc"
        echo "# Source Midnight welcome message" >> "$USER_HOME/.bashrc"
        echo "[ -f ~/.midnight-welcome.sh ] && source ~/.midnight-welcome.sh" >> "$USER_HOME/.bashrc"
    fi
    
    # Ensure proper ownership if running as root
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        chown -R user:user $USER_HOME/.local 2>/dev/null || true
        chown -R user:user $USER_HOME/.config 2>/dev/null || true
        chown user:user $USER_HOME/.bashrc 2>/dev/null || true
    fi
fi

echo "✓ User environment setup complete"