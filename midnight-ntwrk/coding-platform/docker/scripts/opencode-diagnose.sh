#!/bin/bash
# Diagnose OpenCode configuration and authentication issues

echo "=== OpenCode Diagnostics ==="
echo ""

# Check environment
echo "Environment Detection:"
if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ]; then
    echo "  ✓ CLOUD_WORKSTATIONS_CONFIG is set"
fi

if curl -s -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/" &>/dev/null 2>&1; then
    echo "  ✓ Metadata service is accessible"
    IS_WORKSTATION=true
else
    echo "  ✗ Metadata service not accessible (not in Cloud Workstation)"
    IS_WORKSTATION=false
fi

echo ""
echo "Project Configuration:"
echo "  GCP_PROJECT_ID: ${GCP_PROJECT_ID:-<not set>}"
echo "  GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT:-<not set>}"
echo "  GOOGLE_APPLICATION_CREDENTIALS: ${GOOGLE_APPLICATION_CREDENTIALS:-<not set>}"

if [ "$IS_WORKSTATION" = true ]; then
    METADATA_PROJECT=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || echo "")
    echo "  Project from metadata: ${METADATA_PROJECT:-<failed to retrieve>}"
fi

echo ""
echo "Authentication Status:"

# Check gcloud auth
if command -v gcloud &> /dev/null; then
    GCLOUD_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    echo "  gcloud project: ${GCLOUD_PROJECT:-<not set>}"
    
    GCLOUD_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || echo "")
    if [ -n "$GCLOUD_ACCOUNT" ]; then
        echo "  gcloud account: $GCLOUD_ACCOUNT"
    else
        echo "  gcloud account: <not authenticated>"
    fi
else
    echo "  gcloud: <not installed>"
fi

# Check for credential files
echo ""
echo "Credential Files:"
CRED_PATHS=(
    "$HOME/.config/gcloud/application_default_credentials.json"
    "/home/user/.config/gcloud/application_default_credentials.json"
    "/root/.config/gcloud/application_default_credentials.json"
)

for path in "${CRED_PATHS[@]}"; do
    if [ -f "$path" ]; then
        echo "  ✓ Found: $path"
    fi
done

# Check OpenCode installation
echo ""
echo "OpenCode Installation:"
if command -v opencode-ai &> /dev/null; then
    echo "  ✓ opencode-ai is installed"
    OPENCODE_VERSION=$(opencode-ai --version 2>/dev/null || echo "unknown")
    echo "    Version: $OPENCODE_VERSION"
elif command -v opencode &> /dev/null; then
    echo "  ✓ opencode is installed"
    OPENCODE_VERSION=$(opencode --version 2>/dev/null || echo "unknown")
    echo "    Version: $OPENCODE_VERSION"
else
    echo "  ✗ OpenCode not found in PATH"
fi

# Check OpenCode config
echo ""
echo "OpenCode Configuration:"
if [ -f "$HOME/.config/opencode/opencode.json" ]; then
    echo "  ✓ Config file exists: $HOME/.config/opencode/opencode.json"
    
    # Extract project from config
    CONFIG_PROJECT=$(jq -r '.provider."google-vertex-anthropic".options.project // empty' "$HOME/.config/opencode/opencode.json" 2>/dev/null)
    if [ -n "$CONFIG_PROJECT" ]; then
        echo "    Configured project: $CONFIG_PROJECT"
    fi
    
    # Check model configuration
    MODEL=$(jq -r '.model // empty' "$HOME/.config/opencode/opencode.json" 2>/dev/null)
    if [ -n "$MODEL" ]; then
        echo "    Default model: $MODEL"
    fi
else
    echo "  ✗ Config file not found"
fi

# Test Vertex AI access
echo ""
echo "Vertex AI Access Test:"
if [ -n "$GCP_PROJECT_ID" ] || [ -n "$METADATA_PROJECT" ]; then
    TEST_PROJECT="${GCP_PROJECT_ID:-$METADATA_PROJECT}"
    
    # Unset credentials to use metadata if in workstation
    if [ "$IS_WORKSTATION" = true ]; then
        unset GOOGLE_APPLICATION_CREDENTIALS
    fi
    
    echo "  Testing with project: $TEST_PROJECT"
    
    if gcloud ai models list --region=global --project="$TEST_PROJECT" --limit=1 &>/dev/null 2>&1; then
        echo "  ✓ Vertex AI API is accessible"
        
        MODEL_COUNT=$(gcloud ai models list --region=global --project="$TEST_PROJECT" --format="value(name)" 2>/dev/null | wc -l)
        echo "  ✓ Found $MODEL_COUNT models available"
    else
        echo "  ✗ Cannot access Vertex AI API"
        echo "    This could mean:"
        echo "    - The API is not enabled"
        echo "    - The service account lacks permissions"
        echo "    - Authentication is not configured"
    fi
else
    echo "  ✗ No project configured"
fi

# Recommendations
echo ""
echo "=== Recommendations ==="

if [ "$IS_WORKSTATION" = true ]; then
    if [ -z "$GCP_PROJECT_ID" ] && [ -n "$METADATA_PROJECT" ]; then
        echo "• Set GCP_PROJECT_ID environment variable:"
        echo "    export GCP_PROJECT_ID=$METADATA_PROJECT"
    fi
    
    if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        echo "• Unset GOOGLE_APPLICATION_CREDENTIALS to use metadata service:"
        echo "    unset GOOGLE_APPLICATION_CREDENTIALS"
    fi
    
    if [ ! -f "$HOME/.config/opencode/opencode.json" ]; then
        echo "• Run configure-opencode to create configuration:"
        echo "    configure-opencode"
    fi
else
    if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
        echo "• Set up application default credentials:"
        echo "    gcloud auth application-default login"
    fi
fi

echo ""
echo "To start OpenCode after fixing issues, run:"
echo "  opencode"
echo ""