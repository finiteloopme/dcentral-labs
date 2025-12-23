# ==============================================================================
# CLOUD WORKSTATIONS ONLY
# ==============================================================================
# This script detects GOOGLE_CLOUD_PROJECT from GCE metadata server.
# Only active on Cloud Workstations (metadata server not available locally).
#
# For Cloud Workstations:
#   - Queries GCE metadata server for project ID
#   - Required for OpenCode to authenticate with Vertex AI
#
# For local dev:
#   - GOOGLE_CLOUD_PROJECT is passed via 'make run' (-e flag)
#   - Metadata server is not available, curl fails silently
# ==============================================================================

if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
    PROJECT=$(curl -s -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
    if [ -n "$PROJECT" ]; then
        export GOOGLE_CLOUD_PROJECT="$PROJECT"
    fi
fi
