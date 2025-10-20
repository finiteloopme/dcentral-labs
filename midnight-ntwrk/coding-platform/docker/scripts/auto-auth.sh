#!/bin/bash
# Automatic authentication setup for Cloud Workstations
# This ensures users don't need to manually authenticate

# Function to check if we can access metadata service
check_metadata_service() {
    curl -s -f -m 1 -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance" &>/dev/null
}

# Function to get project from metadata
get_project_from_metadata() {
    curl -s -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || echo ""
}

# Function to get service account from metadata
get_service_account_from_metadata() {
    curl -s -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" 2>/dev/null || echo ""
}

# Main authentication logic
setup_auth() {
    # Check if we're in a Cloud Workstation
    if [ -n "$CLOUD_WORKSTATIONS_CONFIG" ] || check_metadata_service; then
        # We're in a Cloud Workstation - use metadata service
        
        # Get and set project ID
        if [ -z "$GCP_PROJECT_ID" ]; then
            GCP_PROJECT_ID=$(get_project_from_metadata)
            if [ -n "$GCP_PROJECT_ID" ]; then
                export GCP_PROJECT_ID
                export GOOGLE_CLOUD_PROJECT="$GCP_PROJECT_ID"
            fi
        fi
        
        # IMPORTANT: Don't set GOOGLE_APPLICATION_CREDENTIALS
        # The metadata service will be used automatically when this variable is unset
        unset GOOGLE_APPLICATION_CREDENTIALS
        
        # Configure gcloud to use the project
        if [ -n "$GCP_PROJECT_ID" ] && command -v gcloud &>/dev/null; then
            gcloud config set project "$GCP_PROJECT_ID" --quiet 2>/dev/null || true
            
            # Set the account to the service account from metadata
            SERVICE_ACCOUNT=$(get_service_account_from_metadata)
            if [ -n "$SERVICE_ACCOUNT" ]; then
                gcloud config set account "$SERVICE_ACCOUNT" --quiet 2>/dev/null || true
            fi
        fi
        
        # Set additional environment variables for libraries that need them
        export GOOGLE_CLOUD_PROJECT="${GCP_PROJECT_ID}"
        export GCP_PROJECT="${GCP_PROJECT_ID}"
        
        # For some Google Cloud libraries, we need to explicitly tell them to use metadata
        export GCE_METADATA_HOST="metadata.google.internal"
        export GCE_METADATA_TIMEOUT="5"
        
        return 0
    else
        # Not in Cloud Workstation - check for local credentials
        
        # Look for application default credentials
        POTENTIAL_CRED_FILES=(
            "$HOME/.config/gcloud/application_default_credentials.json"
            "/home/user/.config/gcloud/application_default_credentials.json"
        )
        
        # Add current GOOGLE_APPLICATION_CREDENTIALS only if it's a valid file
        if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ "$GOOGLE_APPLICATION_CREDENTIALS" != "/dev/null" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
            POTENTIAL_CRED_FILES+=("$GOOGLE_APPLICATION_CREDENTIALS")
        fi
        
        # Find the first valid credential file
        FOUND_CREDS=""
        for cred_file in "${POTENTIAL_CRED_FILES[@]}"; do
            if [ -n "$cred_file" ] && [ -f "$cred_file" ]; then
                FOUND_CREDS="$cred_file"
                break
            fi
        done
        
        # Only set GOOGLE_APPLICATION_CREDENTIALS if we found a valid file
        if [ -n "$FOUND_CREDS" ]; then
            export GOOGLE_APPLICATION_CREDENTIALS="$FOUND_CREDS"
        else
            # No valid credentials found - unset the variable
            unset GOOGLE_APPLICATION_CREDENTIALS
        fi
        
        # Try to get project from gcloud config
        if [ -z "$GCP_PROJECT_ID" ] && command -v gcloud &>/dev/null; then
            GCP_PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
            if [ -n "$GCP_PROJECT_ID" ]; then
                export GCP_PROJECT_ID
                export GOOGLE_CLOUD_PROJECT="$GCP_PROJECT_ID"
            fi
        fi
        
        return 0
    fi
}

# Run the setup
setup_auth

# Export a flag to indicate auth has been configured
export GOOGLE_AUTH_CONFIGURED=1