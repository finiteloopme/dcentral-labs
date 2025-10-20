#!/bin/bash
#
# Configure OpenCode for Cloud Workstations with Vertex AI
#

# In Cloud Workstations, this runs as the workstation user
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  # If running as root, switch to user if available
  if id user >/dev/null 2>&1; then
    exec runuser user "${BASH_SOURCE[0]}"
  else
    # No user account yet, skip for now
    exit 0
  fi
fi

echo "Configuring OpenCode for Vertex AI..."

# Ensure OpenCode directories exist
mkdir -p ~/.local/share/opencode/log
mkdir -p ~/.config/opencode

# Get GCP project ID from metadata service (Cloud Workstations environment)
GCP_PROJECT_ID=""
if curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null; then
    GCP_PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id")
    echo "Detected GCP Project: $GCP_PROJECT_ID"
fi

# Create OpenCode configuration for Vertex AI
cat > ~/.config/opencode/config.json << EOF
{
  "model": "google-vertex-anthropic/claude-opus-4-1@20250805",
  "small_model": "google-vertex-anthropic/claude-3-5-haiku@20241022",
  "provider": {
    "google-vertex-anthropic": {
      "models": {
        "claude-opus-4-1@20250805": {},
        "claude-3-5-sonnet-v2@20241022": {},
        "claude-3-5-haiku@20241022": {}
      },
      "options": {
        "project": "${GCP_PROJECT_ID:-\$GCP_PROJECT_ID}",
        "location": "us-central1"
      }
    }
  }
}
EOF

# Create a simple environment setup script
ENV_SCRIPT="$HOME/.midnight-env.sh"
cat > "$ENV_SCRIPT" << 'EOF'
#!/bin/bash
# Environment setup for Midnight Workstation

# Auto-detect and export GCP project ID for Cloud Workstations
if [ -z "$GCP_PROJECT_ID" ]; then
    if [ -n "$CLOUD_WORKSTATIONS_CONFIG_DIRECTORY" ]; then
        export GCP_PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" \
            "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
    fi
fi

# Ensure OpenCode directories exist
mkdir -p ~/.local/share/opencode/log 2>/dev/null
mkdir -p ~/.config/opencode 2>/dev/null
EOF

chmod +x "$ENV_SCRIPT"

# Add source line to bashrc if not already there
if [ -f ~/.bashrc ]; then
    # Add at the beginning of bashrc to ensure it runs early
    if ! grep -q "midnight-env.sh" ~/.bashrc 2>/dev/null; then
        # Create temp file with new content at top
        temp_bashrc=$(mktemp)
        echo "# Source Midnight environment setup" > "$temp_bashrc"
        echo "[ -f ~/.midnight-env.sh ] && source ~/.midnight-env.sh" >> "$temp_bashrc"
        echo "" >> "$temp_bashrc"
        cat ~/.bashrc >> "$temp_bashrc"
        mv "$temp_bashrc" ~/.bashrc
    fi
fi

echo "✓ OpenCode configuration complete"
echo "  Model: Claude Opus 4.1 via Vertex AI"
echo "  Project: ${GCP_PROJECT_ID:-will be auto-detected}"
echo "  Ready to use: just run 'opencode'"