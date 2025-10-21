#!/bin/bash
# Build script for Midnight Development Workstation container image
# Supports both Docker and Podman

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Detect container runtime (podman or docker)
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
else
    echo "Error: No container runtime found. Please install Podman or Docker."
    echo "  Podman: https://podman.io/getting-started/installation"
    echo "  Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "Using container runtime: $CONTAINER_CMD"

# Default values
IMAGE_NAME="midnight-workstation"
IMAGE_TAG="latest"
REGISTRY=""
PUSH=false

# Proof service configuration
# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --proof-url|--proof-key|--proof-mode)
            # Deprecated - ignore these options
            echo "Warning: $1 is deprecated and ignored (proof server is now built-in)"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --name NAME       Container image name (default: midnight-workstation)"
            echo "  --tag TAG         Container image tag (default: latest)"
            echo "  --registry REG    Registry URL (e.g., us-central1-docker.pkg.dev/PROJECT/REPO)"
            echo "  --push            Push image to registry after building"
            echo "  --proof-url URL   External proof service URL (sets mode to external)"
            echo "  --proof-key KEY   API key for external proof service (optional)"
            echo "  --proof-mode MODE Proof service mode: local or external (default: local)"
            echo "  --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  # Build with local proof service (default)"
            echo "  $0"
            echo ""
            echo "  # Build with external proof service"
            echo "  $0 --proof-url https://proof-api.midnight.network"
            echo ""
            echo "  # Build with external proof service and API key"
            echo "  $0 --proof-url https://proof-api.midnight.network --proof-key mykey"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Construct full image name
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
else
    FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
fi

echo "========================================"
echo "Building Midnight Development Workstation"
echo "========================================"
echo ""
echo "Image: $FULL_IMAGE_NAME"
echo "Context: $SCRIPT_DIR"
echo "Proof Service: Integrated mock server (port 8081)"
echo ""

# Build the container image using the docker directory as context
# This is simpler and avoids issues with missing directories
echo "Building container image..."
$CONTAINER_CMD build \
    -t "$FULL_IMAGE_NAME" \
    "$SCRIPT_DIR"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build successful!"
    echo ""
    echo "Image: $FULL_IMAGE_NAME"
    if [ "$CONTAINER_CMD" = "docker" ]; then
        echo "Size: $(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$IMAGE_NAME:$IMAGE_TAG" | awk '{print $2}')"
    else
        echo "Size: $($CONTAINER_CMD images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$IMAGE_NAME:$IMAGE_TAG" | awk '{print $2}')"
    fi
    
    if [ "$PUSH" = true ] && [ -n "$REGISTRY" ]; then
        echo ""
        echo "Pushing image to registry..."
        $CONTAINER_CMD push "$FULL_IMAGE_NAME"
        if [ $? -eq 0 ]; then
            echo "✓ Image pushed successfully!"
        else
            echo "✗ Failed to push image"
            exit 1
        fi
    fi
    
    echo ""
    echo "To test locally:"
    echo "  $CONTAINER_CMD run -p 8080:80 -p 8081:8080 --privileged $FULL_IMAGE_NAME"
    echo ""
    echo "To push to registry:"
    echo "  $CONTAINER_CMD push $FULL_IMAGE_NAME"
else
    echo ""
    echo "✗ Build failed!"
    exit 1
fi