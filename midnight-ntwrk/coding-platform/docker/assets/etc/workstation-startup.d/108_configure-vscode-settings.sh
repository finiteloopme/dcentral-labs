#!/bin/bash
#
# Configure VS Code/Code OSS settings for proper terminal environment
# This runs right before IDE starts (108 < 110)
#

echo "Configuring Code OSS settings for GCP environment..."

# VS Code settings locations (try multiple possible locations)
VSCODE_SETTINGS_PATHS=(
    "/home/user/.codeoss-cloudworkstations/data/Machine/settings.json"
    "/home/user/.vscode-oss/data/Machine/settings.json"
    "/home/user/.config/Code - OSS/User/settings.json"
    "/home/user/.config/Code/User/settings.json"
)

# Settings to ensure GCP environment in terminals
TERMINAL_SETTINGS=$(cat << 'EOF'
{
  "terminal.integrated.env.linux": {
    "GCP_PROJECT_ID": "${env:GCP_PROJECT_ID}",
    "GOOGLE_CLOUD_PROJECT": "${env:GOOGLE_CLOUD_PROJECT}"
  },
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash",
      "args": ["-l", "-c", "source /etc/bash.bashrc 2>/dev/null; exec bash"],
      "icon": "terminal-bash",
      "env": {
        "FORCE_GCP_DETECT": "1"
      }
    }
  },
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.inheritEnv": true,
  "terminal.integrated.shellIntegration.enabled": true
}
EOF
)

# Function to merge JSON settings
merge_settings() {
    local settings_file="$1"
    local parent_dir=$(dirname "$settings_file")
    
    # Create directory if it doesn't exist
    mkdir -p "$parent_dir"
    
    if [ -f "$settings_file" ]; then
        # File exists, merge settings
        echo "  Updating existing settings: $settings_file"
        
        # Create backup
        cp "$settings_file" "${settings_file}.backup.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
        
        # Use jq if available, otherwise use simple append
        if command -v jq >/dev/null 2>&1; then
            # Merge using jq
            echo "$TERMINAL_SETTINGS" | jq -s '.[0] * .[1]' "$settings_file" - > "${settings_file}.tmp" 2>/dev/null && \
                mv "${settings_file}.tmp" "$settings_file"
        else
            # Simple check if terminal settings exist
            if ! grep -q "terminal.integrated.env.linux" "$settings_file" 2>/dev/null; then
                # Add terminal settings before the last closing brace
                sed -i '$ s/}/,\n  "terminal.integrated.env.linux": {\n    "GCP_PROJECT_ID": "${env:GCP_PROJECT_ID}",\n    "GOOGLE_CLOUD_PROJECT": "${env:GOOGLE_CLOUD_PROJECT}"\n  },\n  "terminal.integrated.inheritEnv": true\n}/' "$settings_file" 2>/dev/null || true
            fi
        fi
    else
        # File doesn't exist, create it
        echo "  Creating new settings: $settings_file"
        echo "$TERMINAL_SETTINGS" > "$settings_file"
    fi
    
    # Set proper ownership
    chown user:user "$settings_file" 2>/dev/null || true
}

# Apply settings to all possible locations
for settings_path in "${VSCODE_SETTINGS_PATHS[@]}"; do
    if [ -d "$(dirname "$(dirname "$settings_path")")" ]; then
        merge_settings "$settings_path"
    fi
done

# Also create a wrapper script for the terminal
cat > /usr/local/bin/vscode-terminal-wrapper << 'EOF'
#!/bin/bash
# Wrapper script to ensure GCP environment in VS Code terminals

# Source system bashrc to get GCP settings
[ -f /etc/bash.bashrc ] && source /etc/bash.bashrc

# Auto-detect GCP project if not set
if [ -z "$GCP_PROJECT_ID" ]; then
    GCP_PROJECT_ID=$(curl -s -f -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
    if [ -n "$GCP_PROJECT_ID" ]; then
        export GCP_PROJECT_ID
        export GOOGLE_CLOUD_PROJECT="$GCP_PROJECT_ID"
    fi
fi

# Start bash with proper environment
exec /bin/bash "$@"
EOF

chmod +x /usr/local/bin/vscode-terminal-wrapper

echo "✓ Code OSS terminal settings configured"