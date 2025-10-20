#!/bin/bash
# Fix Vertex AI authentication for Cloud Workstations

set -e

echo "=== Vertex AI Authentication Fix for Cloud Workstations ==="
echo ""

# Get project ID
PROJECT_ID="${GCP_PROJECT_ID:-${PROJECT_ID:-}}"
if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
fi

if [ -z "$PROJECT_ID" ]; then
    echo "Error: No GCP project ID found."
    echo "Please set GCP_PROJECT_ID environment variable or run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Using project: $PROJECT_ID"
echo ""

# Check if running inside a Cloud Workstation
if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ]; then
    echo "✓ Running inside a Cloud Workstation"
    
    # Get the service account being used
    SERVICE_ACCOUNT=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" \
        -H "Metadata-Flavor: Google" 2>/dev/null || echo "")
    
    if [ -n "$SERVICE_ACCOUNT" ]; then
        echo "Current service account: $SERVICE_ACCOUNT"
    else
        echo "Warning: Could not detect service account"
    fi
else
    echo "Note: Not running inside a Cloud Workstation. This script is for workstation environments."
fi

echo ""
echo "Checking Vertex AI API status..."

# Check if Vertex AI API is enabled
if gcloud services list --enabled --filter="name:aiplatform.googleapis.com" --project="$PROJECT_ID" | grep -q aiplatform; then
    echo "✓ Vertex AI API is enabled"
else
    echo "✗ Vertex AI API is not enabled"
    echo "Enabling Vertex AI API..."
    gcloud services enable aiplatform.googleapis.com --project="$PROJECT_ID"
    echo "✓ Vertex AI API enabled"
fi

echo ""
echo "Checking authentication..."

# Check gcloud authentication
if gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo "✓ Authenticated as: $ACTIVE_ACCOUNT"
else
    echo "✗ Not authenticated with gcloud"
    echo ""
    echo "To authenticate, run:"
    echo "  gcloud auth login"
    echo "  gcloud auth application-default login"
fi

# Check Application Default Credentials
if [ -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
    echo "✓ Application Default Credentials found"
else
    echo "✗ Application Default Credentials not found"
    echo ""
    echo "Setting up Application Default Credentials..."
    
    if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ]; then
        # In Cloud Workstation, try to use metadata service
        echo "Using workstation metadata service for authentication..."
        
        # Test if we can access Vertex AI
        echo "Testing Vertex AI access..."
        if gcloud ai models list --region=global --project="$PROJECT_ID" --limit=1 &>/dev/null; then
            echo "✓ Vertex AI access confirmed via metadata service"
        else
            echo "✗ Cannot access Vertex AI. Service account may need permissions."
            echo ""
            echo "The workstation service account needs the following IAM roles:"
            echo "  - roles/aiplatform.user"
            echo "  - roles/serviceusage.serviceUsageConsumer"
            echo ""
            echo "To fix this, an administrator needs to run:"
            echo "  terraform apply"
            echo ""
            echo "Or manually grant permissions:"
            echo "  gcloud projects add-iam-policy-binding $PROJECT_ID \\"
            echo "    --member=\"serviceAccount:$SERVICE_ACCOUNT\" \\"
            echo "    --role=\"roles/aiplatform.user\""
        fi
    else
        echo "Run: gcloud auth application-default login"
    fi
fi

echo ""
echo "Testing Vertex AI model access..."

# Test Claude models
echo "Checking Claude models availability..."
if gcloud ai models list --region=global --project="$PROJECT_ID" 2>/dev/null | grep -q "claude"; then
    echo "✓ Claude models are available"
    gcloud ai models list --region=global --project="$PROJECT_ID" 2>/dev/null | grep "claude" | head -3
else
    echo "✗ Claude models not found. They may not be available in your region or project."
fi

echo ""
echo "Checking Gemini models availability..."
if gcloud ai models list --region=global --project="$PROJECT_ID" 2>/dev/null | grep -q "gemini"; then
    echo "✓ Gemini models are available"
    gcloud ai models list --region=global --project="$PROJECT_ID" 2>/dev/null | grep "gemini" | head -3
else
    echo "✗ Gemini models not found"
fi

# Configure OpenCode
echo ""
echo "Configuring OpenCode..."
if [ -x /usr/local/bin/configure-opencode ]; then
    /usr/local/bin/configure-opencode
elif [ -x /opt/scripts/configure-opencode.sh ]; then
    /opt/scripts/configure-opencode.sh
else
    echo "Warning: configure-opencode script not found"
fi

echo ""
echo "=== Diagnostics Complete ==="
echo ""

if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ] && [ -n "$SERVICE_ACCOUNT" ]; then
    echo "If Vertex AI is still not working, the service account needs IAM permissions."
    echo ""
    echo "Ask your administrator to:"
    echo "1. Apply the terraform changes to create a dedicated service account"
    echo "2. Or manually grant permissions to: $SERVICE_ACCOUNT"
    echo ""
    echo "Required roles:"
    echo "  - roles/aiplatform.user"
    echo "  - roles/serviceusage.serviceUsageConsumer"
else
    echo "For local development, ensure you have:"
    echo "1. Authenticated with: gcloud auth login"
    echo "2. Set application defaults: gcloud auth application-default login"
    echo "3. Set project: gcloud config set project $PROJECT_ID"
fi

echo ""
echo "To test OpenCode with Vertex AI, run:"
echo "  opencode"
echo "Then try: /model google-vertex-anthropic/claude-3-5-haiku@20241022"