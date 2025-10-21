#!/bin/bash
#
# Auto-detect and set GCP_PROJECT_ID for all bash sessions
# This file is sourced by /etc/bash.bashrc for ALL bash shells
#

# Function to detect and set GCP project
set_gcp_project() {
    # Skip if already set
    if [ -n "$GCP_PROJECT_ID" ]; then
        return 0
    fi
    
    # Try to get from metadata service (if in GCP)
    local project_id=$(curl -s -f -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
    
    if [ -n "$project_id" ]; then
        export GCP_PROJECT_ID="$project_id"
        export GOOGLE_CLOUD_PROJECT="$project_id"
        return 0
    fi
    
    # Try to get from gcloud config (if available)
    if command -v gcloud >/dev/null 2>&1; then
        project_id=$(gcloud config get-value project 2>/dev/null)
        if [ -n "$project_id" ] && [ "$project_id" != "(unset)" ]; then
            export GCP_PROJECT_ID="$project_id"
            export GOOGLE_CLOUD_PROJECT="$project_id"
            return 0
        fi
    fi
    
    return 1
}

# Set GCP project for this session
set_gcp_project

# Also ensure it's available for non-interactive shells
if [ -n "$GCP_PROJECT_ID" ]; then
    # Export for child processes
    export GCP_PROJECT_ID
    export GOOGLE_CLOUD_PROJECT="$GCP_PROJECT_ID"
fi