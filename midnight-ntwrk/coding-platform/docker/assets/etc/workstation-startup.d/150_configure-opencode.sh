#!/bin/bash
#
# Configure OpenCode for Cloud Workstations with Vertex AI
#

# Skip this script in local development mode
# Local mode is detected by checking if we're running as root with ubuntu user present
if [[ "${EUID:-$(id -u)}" -eq 0 ]] && id ubuntu >/dev/null 2>&1; then
  echo "Skipping OpenCode configuration (local development mode)"
  exit 0
fi

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

echo "Configuring OpenCode for Cloud Workstations..."

# Ensure OpenCode directories exist
mkdir -p ~/.local/share/opencode/log
mkdir -p ~/.config/opencode

# Get GCP project ID - should already be set by 051_set-gcp-project.sh
if [ -z "$GCP_PROJECT_ID" ]; then
    # Fallback: try to get from metadata service if not already set
    if curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id" &>/dev/null; then
        GCP_PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id")
        echo "Detected GCP Project: $GCP_PROJECT_ID"
    fi
else
    echo "Using GCP Project: $GCP_PROJECT_ID"
fi

# Only create OpenCode configuration if it doesn't exist
# This prevents overwriting custom configurations in local development
if [ ! -f ~/.config/opencode/config.json ]; then
  echo "Creating OpenCode configuration for Vertex AI..."
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
else
  echo "OpenCode configuration already exists, skipping..."
fi

# Don't create any profile.d scripts in user home to avoid issues
# Environment setup is handled by /etc/profile.d/midnight-welcome.sh

echo "✓ OpenCode configuration complete"
echo "  Model: Claude Opus 4.1 via Vertex AI"
echo "  Project: ${GCP_PROJECT_ID:-will be auto-detected}"
echo "  Ready to use: just run 'opencode'"