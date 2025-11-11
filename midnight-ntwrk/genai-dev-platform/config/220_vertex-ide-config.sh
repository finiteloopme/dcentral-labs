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