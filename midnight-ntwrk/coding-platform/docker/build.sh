#!/bin/bash
# Build script for Midnight Development Workstation Docker image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
IMAGE_NAME="midnight-workstation"
IMAGE_TAG="latest"
REGISTRY=""
PUSH=false

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
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --name NAME       Docker image name (default: midnight-workstation)"
            echo "  --tag TAG         Docker image tag (default: latest)"
            echo "  --registry REG    Registry URL (e.g., us-central1-docker.pkg.dev/PROJECT/REPO)"
            echo "  --push            Push image to registry after building"
            echo "  --help            Show this help message"
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
echo ""

# Build the Docker image using the docker directory as context
# This is simpler and avoids issues with missing directories
echo "Building Docker image..."
docker build \
    -t "$FULL_IMAGE_NAME" \
    "$SCRIPT_DIR"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build successful!"
    echo ""
    echo "Image: $FULL_IMAGE_NAME"
    echo "Size: $(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$IMAGE_NAME:$IMAGE_TAG" | awk '{print $2}')"
    
    if [ "$PUSH" = true ] && [ -n "$REGISTRY" ]; then
        echo ""
        echo "Pushing image to registry..."
        docker push "$FULL_IMAGE_NAME"
        if [ $? -eq 0 ]; then
            echo "✓ Image pushed successfully!"
        else
            echo "✗ Failed to push image"
            exit 1
        fi
    fi
    
    echo ""
    echo "To test locally:"
    echo "  docker run -p 8080:80 -p 8081:8080 --privileged $FULL_IMAGE_NAME"
    echo ""
    echo "To push to registry:"
    echo "  docker push $FULL_IMAGE_NAME"
else
    echo ""
    echo "✗ Build failed!"
    exit 1
fi