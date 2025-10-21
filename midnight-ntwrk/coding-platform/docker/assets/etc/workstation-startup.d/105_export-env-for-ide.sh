#!/bin/bash
#
# Export environment variables for IDE processes
# This runs BEFORE the IDE starts (110_start-code-oss.sh)
#

echo "Exporting environment variables for IDE..."

# Source /etc/environment to get any variables set there
if [ -f /etc/environment ]; then
    # Convert /etc/environment format to export commands
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [ -z "$key" ] && continue
        
        # Remove quotes if present
        value="${value%\"}"
        value="${value#\"}"
        
        # Export the variable
        export "$key=$value"
        echo "  Exported: $key"
    done < /etc/environment
fi

# Ensure GCP_PROJECT_ID is set for Cloud Workstations
if [ -n "$CLOUD_WORKSTATIONS_CONFIG_DIRECTORY" ] || [ -n "$CLOUD_WORKSTATIONS_CLUSTER" ]; then
    if [ -z "$GCP_PROJECT_ID" ]; then
        # Try to fetch it one more time
        PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" \
            "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || true)
        if [ -n "$PROJECT_ID" ]; then
            export GCP_PROJECT_ID="$PROJECT_ID"
            export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
            echo "  Set GCP_PROJECT_ID=$PROJECT_ID"
        fi
    fi
fi

# These exports will be inherited by the IDE process started in 110_start-*.sh
echo "✓ Environment variables exported for IDE"