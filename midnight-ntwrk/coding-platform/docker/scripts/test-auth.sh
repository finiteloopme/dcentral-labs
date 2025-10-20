#!/bin/bash
# Test Google Cloud authentication

echo "=== Testing Google Cloud Authentication ==="
echo ""

# Check environment
echo "Environment Variables:"
echo "  GCP_PROJECT_ID: ${GCP_PROJECT_ID:-<not set>}"
echo "  GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT:-<not set>}"
echo "  GOOGLE_APPLICATION_CREDENTIALS: ${GOOGLE_APPLICATION_CREDENTIALS:-<not set>}"
echo "  CLOUD_WORKSTATIONS_CONFIG: ${CLOUD_WORKSTATIONS_CONFIG:-<not set>}"
echo ""

# Check if in Cloud Workstation
echo "Checking environment type..."
if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ]; then
    echo "✓ Running in Cloud Workstation"
    
    # Test metadata service
    echo ""
    echo "Testing metadata service..."
    if curl -s -f -m 1 -H "Metadata-Flavor: Google" \
         "http://metadata.google.internal/computeMetadata/v1/instance" &>/dev/null; then
        echo "✓ Metadata service is accessible"
        
        # Get project from metadata
        PROJECT=$(curl -s -H "Metadata-Flavor: Google" \
            "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
        echo "  Project from metadata: $PROJECT"
        
        # Get service account
        SA=$(curl -s -H "Metadata-Flavor: Google" \
            "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" 2>/dev/null)
        echo "  Service account: $SA"
    else
        echo "✗ Metadata service not accessible"
    fi
else
    echo "✓ Running in local environment"
    
    if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        if [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
            echo "✓ Application default credentials file exists"
        else
            echo "✗ Application default credentials file not found: $GOOGLE_APPLICATION_CREDENTIALS"
        fi
    else
        echo "  Note: GOOGLE_APPLICATION_CREDENTIALS not set"
    fi
fi

# Test gcloud
echo ""
echo "Testing gcloud CLI..."
if command -v gcloud &>/dev/null; then
    echo "✓ gcloud is installed"
    
    # Get current configuration
    GCLOUD_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    GCLOUD_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || echo "")
    
    echo "  Project: ${GCLOUD_PROJECT:-<not set>}"
    echo "  Account: ${GCLOUD_ACCOUNT:-<not authenticated>}"
    
    # Test API access
    echo ""
    echo "Testing API access..."
    if gcloud projects describe "${GCP_PROJECT_ID:-$GCLOUD_PROJECT}" &>/dev/null 2>&1; then
        echo "✓ Can access project information"
    else
        echo "✗ Cannot access project information"
    fi
    
    # Test Vertex AI
    echo ""
    echo "Testing Vertex AI access..."
    if gcloud ai models list --region=global --limit=1 &>/dev/null 2>&1; then
        echo "✓ Can access Vertex AI"
        MODEL_COUNT=$(gcloud ai models list --region=global --format="value(name)" 2>/dev/null | wc -l)
        echo "  Found $MODEL_COUNT models"
    else
        echo "✗ Cannot access Vertex AI"
        echo "  This might mean:"
        echo "  - Vertex AI API is not enabled"
        echo "  - Service account lacks permissions"
        echo "  - Authentication is not properly configured"
    fi
else
    echo "✗ gcloud is not installed"
fi

# Test with Python (Google Cloud libraries)
echo ""
echo "Testing with Python Google Cloud libraries..."
if command -v python3 &>/dev/null; then
    python3 -c "
import os
import sys
try:
    from google.auth import default
    credentials, project = default()
    print('✓ Python authentication successful')
    print(f'  Project: {project}')
    print(f'  Credentials type: {type(credentials).__name__}')
except Exception as e:
    print('✗ Python authentication failed')
    print(f'  Error: {e}')
" 2>/dev/null || echo "  Python Google Cloud libraries not installed"
fi

echo ""
echo "=== Authentication Test Complete ==="
echo ""

# Provide recommendations
if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ]; then
    if [ -z "$GCP_PROJECT_ID" ]; then
        echo "Recommendation: Project ID not set. Run:"
        echo "  source /opt/midnight/bin/auto-auth"
    fi
else
    if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ] || [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        echo "Recommendation: Set up application default credentials:"
        echo "  gcloud auth application-default login"
    fi
fi