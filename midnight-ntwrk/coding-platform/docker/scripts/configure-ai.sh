#!/bin/bash
# Configure AI services based on available credentials
# Note: This script is sourced, so be careful with exit commands

# Only show output if running interactively
VERBOSE=false
if [ -t 1 ]; then
    VERBOSE=true
fi

# Color codes (only if verbose)
if [ "$VERBOSE" = true ]; then
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    NC="\033[0m" # No Color
else
    GREEN=""
    YELLOW=""
    NC=""
fi

# Silent configuration - no startup messages

# Detect available AI services
VERTEX_AI_PROJECT=""
VERTEX_AI_LOCATION="us-central1"

# Check if we're in a Cloud Workstation (uses metadata service)
IS_CLOUD_WORKSTATION=false
if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ]; then
    IS_CLOUD_WORKSTATION=true
    [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ Cloud Workstation detected - using metadata service for auth${NC}"
    
    # Get project from metadata
    if [ -z "$GCP_PROJECT_ID" ] && command -v curl &>/dev/null; then
        GCP_PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || echo "")
    fi
    
    if [ -n "$GCP_PROJECT_ID" ]; then
        VERTEX_AI_PROJECT="$GCP_PROJECT_ID"
        export VERTEX_AI_PROJECT
        export VERTEX_AI_LOCATION
        export GCP_PROJECT_ID
        export GOOGLE_CLOUD_PROJECT="$GCP_PROJECT_ID"
        # Unset application credentials to force use of metadata service
        unset GOOGLE_APPLICATION_CREDENTIALS
        
        [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ Vertex AI configured${NC} with project: $VERTEX_AI_PROJECT"
        [ "$VERBOSE" = true ] && echo "  Using automatic authentication via metadata service"
    else
        [ "$VERBOSE" = true ] && echo -e "${YELLOW}⚠ Could not detect project ID from metadata${NC}"
    fi
else
    # Not in Cloud Workstation - check for credential files
    [ "$VERBOSE" = true ] && echo "Local environment detected - checking for credential files..."
    
    # Check for gcloud credentials in multiple locations
    GCLOUD_PATHS=(
        "/home/user/.config/gcloud/application_default_credentials.json"
        "$HOME/.config/gcloud/application_default_credentials.json"
        "/root/.config/gcloud/application_default_credentials.json"
    )
    
    for path in "${GCLOUD_PATHS[@]}"; do
        if [ -f "$path" ] && [ "$path" != "/dev/null" ]; then
            export GOOGLE_APPLICATION_CREDENTIALS="$path"
            [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ Found Google Cloud credentials at $path${NC}"
            
            # Try to get project from environment or gcloud config
            if [ -n "$GCP_PROJECT_ID" ]; then
                VERTEX_AI_PROJECT="$GCP_PROJECT_ID"
            elif [ -n "$GOOGLE_CLOUD_PROJECT" ]; then
                VERTEX_AI_PROJECT="$GOOGLE_CLOUD_PROJECT"
            elif command -v gcloud &>/dev/null; then
                VERTEX_AI_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
            fi
            
            if [ -n "$VERTEX_AI_PROJECT" ]; then
                [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ Vertex AI configured${NC} with project: $VERTEX_AI_PROJECT"
                export VERTEX_AI_PROJECT
                export VERTEX_AI_LOCATION
                export GCP_PROJECT_ID="$VERTEX_AI_PROJECT"
            fi
            break
        fi
    done
    
    if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ] || [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ] || [ "$GOOGLE_APPLICATION_CREDENTIALS" = "/dev/null" ]; then
        unset GOOGLE_APPLICATION_CREDENTIALS
        [ "$VERBOSE" = true ] && echo -e "${YELLOW}⚠ Google Cloud credentials not found${NC}"
        [ "$VERBOSE" = true ] && echo "  To use Vertex AI, run: gcloud auth application-default login"
    fi
fi

# Check for OpenAI credentials
if [ -n "$OPENAI_API_KEY" ]; then
    [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ OpenAI API key configured${NC}"
    export OPENAI_API_KEY="$OPENAI_API_KEY"
elif [ -f "$HOME/.openai/api_key" ]; then
    export OPENAI_API_KEY=$(cat "$HOME/.openai/api_key" 2>/dev/null || echo "")
    [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ OpenAI API key loaded from file${NC}"
else
    [ "$VERBOSE" = true ] && echo -e "${YELLOW}⚠ OpenAI API key not found${NC}"
    [ "$VERBOSE" = true ] && echo "  To use OpenAI, set: export OPENAI_API_KEY='your-key'"
fi

# Check for Anthropic Claude credentials
if [ -n "$ANTHROPIC_API_KEY" ]; then
    [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ Anthropic API key configured${NC}"
    export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
elif [ -f "$HOME/.anthropic/api_key" ]; then
    export ANTHROPIC_API_KEY=$(cat "$HOME/.anthropic/api_key" 2>/dev/null || echo "")
    [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ Anthropic API key loaded from file${NC}"
else
    [ "$VERBOSE" = true ] && echo -e "${YELLOW}⚠ Anthropic API key not found${NC}"
    [ "$VERBOSE" = true ] && echo "  To use Claude, set: export ANTHROPIC_API_KEY='your-key'"
fi

# Configure AI tools based on available credentials (only if verbose)
if [ "$VERBOSE" = true ]; then
    if [ -n "$VERTEX_AI_PROJECT" ] || [ -n "$OPENAI_API_KEY" ] || [ -n "$ANTHROPIC_API_KEY" ]; then
        echo ""
        echo -e "${GREEN}✅ AI services are configured and ready!${NC}"
        
        # Create configuration file for opencode using the template
        if [ ! -f "$HOME/.config/opencode/opencode.json" ]; then
            mkdir -p $HOME/.config/opencode 2>/dev/null || true
            
            # Copy the template and substitute environment variables
            if [ -f "/opt/midnight/config/opencode-config-template.json" ]; then
                cp /opt/midnight/config/opencode-config-template.json $HOME/.config/opencode/opencode.json 2>/dev/null || true
                echo "OpenCode configuration created at ~/.config/opencode/opencode.json"
            else
                # Fallback: create a basic configuration
                cat > $HOME/.config/opencode/opencode.json <<EOF 2>/dev/null || true
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
                [ -f "$HOME/.config/opencode/opencode.json" ] && echo "OpenCode configuration created at ~/.config/opencode/opencode.json"
            fi
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
fi

# Export configuration status
export AI_CONFIGURED=$([ -n "$VERTEX_AI_PROJECT" ] || [ -n "$OPENAI_API_KEY" ] || [ -n "$ANTHROPIC_API_KEY" ] && echo "true" || echo "false")