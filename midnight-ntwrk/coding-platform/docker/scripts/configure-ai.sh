#!/bin/bash
# Configure AI services based on available credentials

echo -e "\033[0;34m🔧 Configuring AI Services...\033[0m"

# Detect available AI services
VERTEX_AI_PROJECT=""
VERTEX_AI_LOCATION="us-central1"

# Check for gcloud credentials in multiple locations
# Cloud Workstations uses /home/user/.config/gcloud
# Local development uses $HOME/.config/gcloud
GCLOUD_PATHS=(
    "/home/user/.config/gcloud/application_default_credentials.json"
    "$HOME/.config/gcloud/application_default_credentials.json"
    "/root/.config/gcloud/application_default_credentials.json"
)

for path in "${GCLOUD_PATHS[@]}"; do
    if [ -f "$path" ]; then
        export GOOGLE_APPLICATION_CREDENTIALS="$path"
        echo -e "\033[0;32m✓ Found Google Cloud credentials at $path\033[0m"
        
        # Try to get project from environment or gcloud config
        if [ -n "$GCP_PROJECT_ID" ]; then
            VERTEX_AI_PROJECT="$GCP_PROJECT_ID"
        elif [ -n "$GOOGLE_CLOUD_PROJECT" ]; then
            VERTEX_AI_PROJECT="$GOOGLE_CLOUD_PROJECT"
        else
            VERTEX_AI_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
        fi
        
        if [ -n "$VERTEX_AI_PROJECT" ]; then
            echo -e "\033[0;32m✓ Vertex AI configured\033[0m with project: $VERTEX_AI_PROJECT"
            export VERTEX_AI_PROJECT
            export VERTEX_AI_LOCATION
            export GCP_PROJECT_ID="$VERTEX_AI_PROJECT"
        fi
        break
    fi
done

if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ] || [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo -e "\033[1;33m⚠ Google Cloud credentials not found\033[0m"
    echo "  To use Vertex AI, run: gcloud auth application-default login"
fi
    fi
    
    # Set Vertex AI environment variables
    export VERTEX_AI_PROJECT="$GCP_PROJECT_ID"
    export VERTEX_AI_LOCATION="${VERTEX_AI_LOCATION:-us-central1}"
    
    echo -e "${GREEN}✓ Vertex AI configured${NC}"
    echo "  Project: $VERTEX_AI_PROJECT"
    echo "  Location: $VERTEX_AI_LOCATION"
    
elif [ -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
    echo -e "${GREEN}✓ Google Cloud credentials found (user)${NC}"
    export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
else
    echo -e "${YELLOW}⚠ Google Cloud credentials not found${NC}"
    echo "  To use Vertex AI, run: gcloud auth application-default login"
fi

# Check for OpenAI credentials
if [ -n "$OPENAI_API_KEY" ]; then
    echo -e "${GREEN}✓ OpenAI API key configured${NC}"
    export OPENAI_API_KEY="$OPENAI_API_KEY"
elif [ -f "$HOME/.openai/api_key" ]; then
    export OPENAI_API_KEY=$(cat "$HOME/.openai/api_key")
    echo -e "${GREEN}✓ OpenAI API key loaded from file${NC}"
else
    echo -e "${YELLOW}⚠ OpenAI API key not found${NC}"
    echo "  To use OpenAI, set: export OPENAI_API_KEY='your-key'"
fi

# Check for Anthropic Claude credentials
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo -e "${GREEN}✓ Anthropic API key configured${NC}"
    export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
elif [ -f "$HOME/.anthropic/api_key" ]; then
    export ANTHROPIC_API_KEY=$(cat "$HOME/.anthropic/api_key")
    echo -e "${GREEN}✓ Anthropic API key loaded from file${NC}"
else
    echo -e "${YELLOW}⚠ Anthropic API key not found${NC}"
    echo "  To use Claude, set: export ANTHROPIC_API_KEY='your-key'"
fi

# Configure AI tools based on available credentials
if [ -n "$VERTEX_AI_PROJECT" ] || [ -n "$OPENAI_API_KEY" ] || [ -n "$ANTHROPIC_API_KEY" ]; then
    echo ""
    echo -e "${GREEN}✅ AI services are configured and ready!${NC}"
    
    # Create configuration file for opencode using the template
    mkdir -p $HOME/.config/opencode
    
    # Copy the template and substitute environment variables
    if [ -f "/opt/midnight/config/opencode-config-template.json" ]; then
        cp /opt/midnight/config/opencode-config-template.json $HOME/.config/opencode/opencode.json
        echo "OpenCode configuration created at ~/.config/opencode/opencode.json"
    else
        # Fallback: create a basic configuration
        cat > $HOME/.config/opencode/opencode.json <<EOF
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
        "project": "${GCP_PROJECT_ID:-}",
        "location": "global"
      }
    },
    "google-vertex": {
      "models": {
        "gemini-2.5-flash": {},
        "gemini-2.5-pro": {}
      },
      "options": {
        "project": "${GCP_PROJECT_ID:-}",
        "location": "global"
      }
    },
    "anthropic": {
      "models": {
        "claude-3-opus-20240229": {},
        "claude-3-5-sonnet-20241022": {},
        "claude-3-5-haiku-20241022": {}
      },
      "options": {
        "apiKey": "${ANTHROPIC_API_KEY:-}"
      }
    }
  }
}
EOF
        echo "OpenCode configuration created at ~/.config/opencode/opencode.json"
    fi
else
    echo ""
    echo -e "${YELLOW}⚠ No AI credentials configured${NC}"
    echo ""
    echo "To enable AI features, configure one of:"
    echo "  • Vertex AI: gcloud auth application-default login"
    echo "  • OpenAI: export OPENAI_API_KEY='your-key'"
    echo "  • Anthropic: export ANTHROPIC_API_KEY='your-key'"
fi

# Export configuration status
export AI_CONFIGURED=$([ -n "$VERTEX_AI_PROJECT" ] || [ -n "$OPENAI_API_KEY" ] || [ -n "$ANTHROPIC_API_KEY" ] && echo "true" || echo "false")