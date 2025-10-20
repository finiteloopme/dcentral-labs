#!/bin/bash
# Configure OpenCode with Vertex AI providers

set -e

# Function to get project ID from metadata service
get_project_from_metadata() {
    if curl -s -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id" &>/dev/null; then
        curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id"
    else
        echo ""
    fi
}

# Detect if we're in Cloud Workstations
IS_CLOUD_WORKSTATION=false
if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ] || curl -s -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/" &>/dev/null; then
    IS_CLOUD_WORKSTATION=true
fi

# Get project ID from various sources
PROJECT_ID="${GCP_PROJECT_ID:-${GOOGLE_CLOUD_PROJECT:-${PROJECT_ID:-}}}"

# If no project ID yet and we're in Cloud Workstation, try metadata
if [ -z "$PROJECT_ID" ] && [ "$IS_CLOUD_WORKSTATION" = true ]; then
    echo "Detecting project from Cloud Workstation metadata..."
    PROJECT_ID=$(get_project_from_metadata)
    if [ -n "$PROJECT_ID" ]; then
        echo "Detected project: $PROJECT_ID"
        export GCP_PROJECT_ID="$PROJECT_ID"
        export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
    fi
fi

# If still no project ID, try gcloud
if [ -z "$PROJECT_ID" ]; then
    # Try to get from gcloud if authenticated
    if command -v gcloud &> /dev/null; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
    fi
fi

# Default to a placeholder if no project ID found
if [ -z "$PROJECT_ID" ]; then
    echo "Warning: No GCP project ID found. Using placeholder."
    echo "In Cloud Workstations, this should auto-detect. Please check your environment."
    PROJECT_ID="your-gcp-project"
fi

# Silent configuration unless there's an issue
if [ "$PROJECT_ID" = "your-gcp-project" ]; then
    echo "Note: No GCP project detected. OpenCode may need manual configuration."
fi

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

# Configuration created silently

# Configure authentication based on environment
if [ "$IS_CLOUD_WORKSTATION" = true ]; then
    # Silent authentication setup for Cloud Workstation
    
    # Ensure auto-auth has run
    if [ -f /opt/midnight/bin/auto-auth ] && [ -z "$GOOGLE_AUTH_CONFIGURED" ]; then
        source /opt/midnight/bin/auto-auth
    fi
    
    # Set gcloud to use the detected project
    if command -v gcloud &> /dev/null && [ "$PROJECT_ID" != "your-gcp-project" ]; then
        gcloud config set project "$PROJECT_ID" --quiet 2>/dev/null || true
        
        # Test authentication silently
        if gcloud ai models list --region=global --limit=1 --project="$PROJECT_ID" &>/dev/null; then
            # Vertex AI is working - enable API silently if needed
            gcloud services enable aiplatform.googleapis.com --project="$PROJECT_ID" --quiet 2>/dev/null || true
        else
            echo "⚠ Cannot access Vertex AI. The workstation service account may need IAM permissions."
            echo "  Required roles: roles/aiplatform.user"
            
            # Try to get more info about the error
            echo "Checking service account..."
            SA=$(curl -s -H "Metadata-Flavor: Google" \
                "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" 2>/dev/null)
            if [ -n "$SA" ]; then
                echo "  Service account: $SA"
                echo "  To grant permissions, run:"
                echo "    gcloud projects add-iam-policy-binding $PROJECT_ID \\"
                echo "      --member=\"serviceAccount:$SA\" \\"
                echo "      --role=\"roles/aiplatform.user\""
            fi
        fi
    fi
else
    # Not in Cloud Workstation - use traditional authentication
    if command -v gcloud &> /dev/null; then
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
            echo "Google Cloud authentication detected."
            
            # Enable required APIs
            echo "Ensuring Vertex AI APIs are enabled..."
            gcloud services enable aiplatform.googleapis.com --project="$PROJECT_ID" 2>/dev/null || true
            
            # Set application default credentials if not already set
            if [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
                echo "Note: Application Default Credentials not set."
                echo "To use Vertex AI, run: gcloud auth application-default login"
            fi
        else
            echo "Warning: Not authenticated with Google Cloud."
            echo "To use Vertex AI models, run:"
            echo "  gcloud auth login"
            echo "  gcloud auth application-default login"
        fi
    else
        echo "Warning: gcloud CLI not found. Vertex AI models will not work without authentication."
    fi
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