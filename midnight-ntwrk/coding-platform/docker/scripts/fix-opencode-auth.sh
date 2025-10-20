#!/bin/bash
# Fix OpenCode authentication issues

echo "Fixing OpenCode authentication..."

# Clean up invalid GOOGLE_APPLICATION_CREDENTIALS
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    if [ "$GOOGLE_APPLICATION_CREDENTIALS" = "/dev/null" ] || [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        echo "Removing invalid GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"
        unset GOOGLE_APPLICATION_CREDENTIALS
    else
        echo "Valid credentials file found: $GOOGLE_APPLICATION_CREDENTIALS"
    fi
else
    echo "GOOGLE_APPLICATION_CREDENTIALS not set"
fi

# In Cloud Workstations, we don't need credential files
if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ]; then
    echo "Cloud Workstation detected - will use metadata service"
    unset GOOGLE_APPLICATION_CREDENTIALS
    
    # Get project from metadata
    if command -v curl &>/dev/null; then
        PROJECT=$(curl -s -H "Metadata-Flavor: Google" \
            "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || echo "")
        if [ -n "$PROJECT" ]; then
            export GCP_PROJECT_ID="$PROJECT"
            export GOOGLE_CLOUD_PROJECT="$PROJECT"
            echo "Project set to: $PROJECT"
        fi
    fi
else
    echo "Local environment - checking for credential files..."
    
    # Look for valid credential files
    CRED_PATHS=(
        "$HOME/.config/gcloud/application_default_credentials.json"
        "/home/user/.config/gcloud/application_default_credentials.json"
    )
    
    for path in "${CRED_PATHS[@]}"; do
        if [ -f "$path" ]; then
            export GOOGLE_APPLICATION_CREDENTIALS="$path"
            echo "Found credentials at: $path"
            break
        fi
    done
fi

# Update OpenCode configuration
if [ -f "$HOME/.config/opencode/opencode.json" ] && [ -n "$GCP_PROJECT_ID" ]; then
    echo "Updating OpenCode configuration with project: $GCP_PROJECT_ID"
    
    # Update the project in the config file
    if command -v jq &>/dev/null; then
        jq --arg project "$GCP_PROJECT_ID" \
           '(.provider."google-vertex-anthropic".options.project = $project) | 
            (.provider."google-vertex".options.project = $project)' \
           "$HOME/.config/opencode/opencode.json" > "$HOME/.config/opencode/opencode.json.tmp" && \
        mv "$HOME/.config/opencode/opencode.json.tmp" "$HOME/.config/opencode/opencode.json"
    fi
elif [ ! -f "$HOME/.config/opencode/opencode.json" ]; then
    echo "Creating OpenCode configuration..."
    /usr/local/bin/configure-opencode 2>/dev/null || /opt/midnight/bin/configure-opencode 2>/dev/null || true
fi

echo ""
echo "Authentication fix complete!"
echo ""
echo "Current settings:"
echo "  GCP_PROJECT_ID: ${GCP_PROJECT_ID:-<not set>}"
echo "  GOOGLE_APPLICATION_CREDENTIALS: ${GOOGLE_APPLICATION_CREDENTIALS:-<not set>}"
echo ""
echo "You can now run: opencode"