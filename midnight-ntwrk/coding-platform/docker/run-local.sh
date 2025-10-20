#!/bin/bash
# Run Cloud Workstation image locally following Google's documentation
# https://cloud.google.com/workstations/docs/customize-container-images#test_your_custom_container_image

echo "Starting Midnight Workstation locally..."
echo "Following Cloud Workstations testing guidelines"
echo ""

# Detect container runtime
if command -v docker &>/dev/null; then
    RUNTIME=docker
elif command -v podman &>/dev/null; then
    RUNTIME=podman
else
    echo "Error: No container runtime found (docker or podman)"
    exit 1
fi

# Build if needed
if ! $RUNTIME image inspect midnight-workstation:latest &>/dev/null; then
    echo "Building image..."
    $RUNTIME build -t midnight-workstation:latest .
fi

# Mount gcloud credentials if available
# Mount to a temp location and copy in entrypoint to avoid read-only issues
GCLOUD_MOUNT=""
GCP_PROJECT_ARG=""

if [ -d "$HOME/.config/gcloud" ]; then
    echo "✓ Google Cloud credentials detected"
    # Mount the entire gcloud config to a temp location
    # The entrypoint will copy what's needed to the user's home
    GCLOUD_MOUNT="-v $HOME/.config/gcloud:/tmp/gcloud-config:ro"
    
    # Try to get the current GCP project
    if command -v gcloud &>/dev/null; then
        CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
        if [ -n "$CURRENT_PROJECT" ]; then
            echo "✓ Using GCP project: $CURRENT_PROJECT"
            GCP_PROJECT_ARG="-e GCP_PROJECT_ID=$CURRENT_PROJECT"
        fi
    fi
else
    echo "⚠️  No Google Cloud credentials found at ~/.config/gcloud"
    echo "   Run 'gcloud auth application-default login' to set up credentials"
fi

# Allow override via environment variable
if [ -n "$GCP_PROJECT_ID" ]; then
    echo "✓ Using GCP project from environment: $GCP_PROJECT_ID"
    GCP_PROJECT_ARG="-e GCP_PROJECT_ID=$GCP_PROJECT_ID"
fi

# For local testing, we need to bypass the Cloud Workstations initialization
# which expects GCP environment. Use a simple entrypoint instead.
echo "Starting container..."
echo ""
echo "Services will be available at:"
echo "  • Code OSS: http://127.0.0.1:8080"
echo "  • Proof Server: http://127.0.0.1:8081"
echo ""
echo "Note: Use 127.0.0.1 instead of localhost for Code OSS"
echo ""

# Copy entrypoint and terminal wrapper into container
$RUNTIME run -it --rm \
    --name midnight-local \
    --privileged \
    -p 8080:80 \
    -p 8081:8081 \
    -v $(pwd)/entrypoint-local.sh:/entrypoint-local.sh:ro \
    -v $(pwd)/terminal-wrapper.sh:/terminal-wrapper.sh:ro \
    $GCLOUD_MOUNT \
    $GCP_PROJECT_ARG \
    --entrypoint /entrypoint-local.sh \
    midnight-workstation:latest