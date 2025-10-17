#!/bin/bash
# Configure OpenCode with Vertex AI providers

set -e

# Get project ID from environment or gcloud
PROJECT_ID="${GCP_PROJECT_ID:-${PROJECT_ID:-}}"
if [ -z "$PROJECT_ID" ]; then
    # Try to get from gcloud if authenticated
    if command -v gcloud &> /dev/null; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
    fi
fi

# Default to a placeholder if no project ID found
if [ -z "$PROJECT_ID" ]; then
    echo "Warning: No GCP project ID found. Using placeholder."
    PROJECT_ID="your-gcp-project"
fi

echo "Configuring OpenCode with project: $PROJECT_ID"

# Create OpenCode config directory
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

# Generate config file with actual project ID
cat > "$OPENCODE_CONFIG_DIR/opencode.json" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "theme": "opencode",
  "autoupdate": true,
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
        "project": "${PROJECT_ID}",
        "location": "global"
      }
    },
    "google-vertex": {
      "models": {
        "gemini-2.5-flash": {},
        "gemini-2.5-pro": {}
      },
      "options": {
        "project": "${PROJECT_ID}",
        "location": "global"
      }
    }
  },
  "tools": {
    "write": true,
    "edit": true,
    "bash": true,
    "read": true
  },
  "tui": {
    "scroll_speed": 3
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

echo "OpenCode configuration created at: $OPENCODE_CONFIG_DIR/opencode.json"

# Check if gcloud is authenticated
if command -v gcloud &> /dev/null; then
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
        echo "Google Cloud authentication detected."
        
        # Enable required APIs
        echo "Ensuring Vertex AI APIs are enabled..."
        gcloud services enable aiplatform.googleapis.com --project="$PROJECT_ID" 2>/dev/null || true
        
        # List available models (optional - for verification)
        echo "Checking available models..."
        gcloud ai models list --region=global --project="$PROJECT_ID" 2>/dev/null | head -20 || true
        
        # Set application default credentials if not already set
        if [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
            echo "Setting up Application Default Credentials..."
            gcloud auth application-default login --no-launch-browser || true
        fi
    else
        echo "Warning: Not authenticated with Google Cloud."
        echo "To use Vertex AI models, run: gcloud auth login"
    fi
else
    echo "Warning: gcloud CLI not found. Vertex AI models will not work without authentication."
fi

# Create a helper script for switching models
cat > "$OPENCODE_CONFIG_DIR/switch-model.sh" << 'EOF'
#!/bin/bash
# Helper script to switch between different models

echo "Available providers and models:"
echo ""
echo "=== Anthropic Models (via Vertex AI) ==="
echo "1. Claude Opus 4.1 (Most Advanced)"
echo "2. Claude 3.5 Sonnet v2 (Balanced)"
echo "3. Claude 3.5 Haiku (Fast)"
echo ""
echo "=== Google Gemini Models ==="
echo "4. Gemini 2.5 Pro (Advanced)"
echo "5. Gemini 2.5 Flash (Fast)"
echo ""
read -p "Select model (1-5): " choice

case $choice in
    1)
        provider="google-vertex-anthropic"
        model="claude-opus-4-1@20250805"
        name="Claude Opus 4.1"
        ;;
    2)
        provider="google-vertex-anthropic"
        model="claude-3-5-sonnet-v2@20241022"
        name="Claude 3.5 Sonnet v2"
        ;;
    3)
        provider="google-vertex-anthropic"
        model="claude-3-5-haiku@20241022"
        name="Claude 3.5 Haiku"
        ;;
    4)
        provider="google-vertex"
        model="gemini-2.5-pro"
        name="Gemini 2.5 Pro"
        ;;
    5)
        provider="google-vertex"
        model="gemini-2.5-flash"
        name="Gemini 2.5 Flash"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Update config
model_full="${provider}/${model}"
jq --arg model "$model_full" \
   '.model = $model' \
   ~/.config/opencode/opencode.json > ~/.config/opencode/opencode.json.tmp && \
   mv ~/.config/opencode/opencode.json.tmp ~/.config/opencode/opencode.json

echo ""
echo "✓ Switched to $name"
echo "  Provider: $provider"
echo "  Model: $model"
EOF

chmod +x "$OPENCODE_CONFIG_DIR/switch-model.sh"

echo ""
echo "OpenCode configuration complete!"
echo ""
echo "To switch models, run: ~/.config/opencode/switch-model.sh"
echo "To use Vertex AI, ensure you're authenticated: gcloud auth login"
echo ""