#!/bin/bash

# Midnight Development Platform - IDE Configuration
# This script configures the IDE environment for Vertex AI and service account usage

set -e

echo "🌙 Midnight Development Platform - Configuring IDE Environment"

# Export Vertex AI environment variables for IDE
export GOOGLE_VERTEX_PROJECT="${GOOGLE_VERTEX_PROJECT:-$GOOGLE_CLOUD_PROJECT}"
export GOOGLE_VERTEX_LOCATION="${GOOGLE_VERTEX_LOCATION:-us-central1}"

echo "✅ Vertex AI Configuration:"
echo "   Project: $GOOGLE_VERTEX_PROJECT"
echo "   Location: $GOOGLE_VERTEX_LOCATION"

# Configure gcloud to use workstation's built-in service account
echo "🔑 Configuring gcloud with workstation service account..."

# The workstation automatically uses its service account via metadata service
# No manual credential setup needed - just configure project and environment
gcloud config set project "$GOOGLE_CLOUD_PROJECT" || echo "⚠️  Project configuration failed"

# Verify service account is accessible
SERVICE_ACCOUNT=$(curl -s -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email")

if [ -n "$SERVICE_ACCOUNT" ]; then
    echo "✅ Using service account: $SERVICE_ACCOUNT"
else
    echo "⚠️  Could not detect service account from metadata"
fi

# Configure Git for Midnight development
git config --global user.name "Midnight Developer"
git config --global user.email "developer@midnight.dev"

# Set up useful aliases
echo 'alias ll="ls -la"' >> ~/.bashrc
echo 'alias midnight-status="gcloud workstations list --region=$GOOGLE_VERTEX_LOCATION"' >> ~/.bashrc

# Configure OpenCode for all users
echo "🔧 Configuring OpenCode for Midnight development..."

# Create OpenCode config directory
mkdir -p ~/.config/opencode

# Copy OpenCode configuration template
if [ -f "/tmp/midnight-config/opencode-config-template.json" ]; then
    cp /tmp/midnight-config/opencode-config-template.json ~/.config/opencode/config.json
    echo "✅ OpenCode configuration installed"
else
    echo "⚠️  OpenCode configuration template not found, creating default..."
    # Create default configuration if template not available
    cat > ~/.config/opencode/config.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "opencode",
  "autoupdate": true,
  "provider": {
    "google-vertex-anthropic": {
      "options": {
        "project": "{env:GOOGLE_VERTEX_PROJECT}",
        "location": "global"
      }
    },
    "google-vertex": {
      "options": {
        "project": "{env:GOOGLE_VERTEX_PROJECT}",
        "location": "global"
      }
    }
  },
  "instructions": [
    "You are an expert Web3, blockchain security, and Midnight Network developer with deep knowledge of:",
    "- Smart contract development and security best practices",
    "- Zero-knowledge proofs and privacy-preserving technologies",
    "- Midnight's Compact language and circuit development",
    "- DApp architecture and decentralized systems",
    "- Cryptographic protocols and implementations",
    "",
    "When working with Midnight projects:",
    "- Prioritize security and privacy in all implementations",
    "- Follow Midnight's best practices for circuit design",
    "- Ensure proper use of @shielded decorators for private state",
    "- Implement comprehensive tests for circuits and proofs",
    "- Consider gas optimization and proof generation efficiency"
  ]
}
EOF
fi

# Verify OpenCode is available and configured
if command -v opencode &> /dev/null; then
    echo "✅ OpenCode is available at: $(which opencode)"
    echo "✅ OpenCode version: $(opencode --version 2>/dev/null || echo 'unknown')"
    
    # Test OpenCode configuration
    if [ -f "$HOME/.config/opencode/config.json" ]; then
        echo "✅ OpenCode configuration found at: $HOME/.config/opencode/config.json"
        
        # Validate configuration syntax
        if python3 -m json.tool "$HOME/.config/opencode/config.json" > /dev/null 2>&1; then
            echo "✅ OpenCode configuration is valid JSON"
        else
            echo "⚠️  OpenCode configuration has JSON syntax errors"
        fi
    else
        echo "⚠️  OpenCode configuration not found"
    fi
else
    echo "⚠️  OpenCode not found in PATH"
fi

# Set OpenCode environment variables for current session
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
echo "✅ OpenCode configuration directory: $OPENCODE_CONFIG_DIR"

# Add OpenCode to user's bashrc if not already present
if ! grep -q "opencode" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# OpenCode AI Assistant" >> ~/.bashrc
    echo 'export PATH="/usr/local/opencode:\$PATH"' >> ~/.bashrc
    echo 'export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"' >> ~/.bashrc
    echo "✅ OpenCode environment variables added to ~/.bashrc"
fi

# Display environment summary
echo ""
echo "🚀 Midnight Development Environment Ready!"
echo "   Project: $GOOGLE_CLOUD_PROJECT"
echo "   Region: $GOOGLE_VERTEX_LOCATION" 
echo "   Environment: $MIDNIGHT_ENV"
echo "   Network: $MIDNIGHT_NETWORK"
echo ""
echo "📚 Useful Commands:"
echo "   gcloud ai models list                 # List Vertex AI models"
echo "   gcloud ai endpoints list             # List Vertex AI endpoints"
echo "   midnight --help                      # Midnight CLI help"
echo "   make ws-tunnel                       # Access IDE via localhost:8080"
echo ""