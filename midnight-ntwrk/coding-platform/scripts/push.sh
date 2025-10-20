#!/bin/bash

# Push container to Google Container Registry

set -e

PROJECT_ID="$1"
REGION="$2"

if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
    echo "Usage: $0 PROJECT_ID REGION"
    exit 1
fi

IMAGE_NAME="midnight-dev-environment"
TAG="latest"

echo "Configuring Docker for GCR..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

echo "Tagging image..."
docker tag "${IMAGE_NAME}:${TAG}" "${REGION}-docker.pkg.dev/${PROJECT_ID}/midnight-dev/${IMAGE_NAME}:${TAG}"

echo "Pushing to registry..."
docker push "${REGION}-docker.pkg.dev/${PROJECT_ID}/midnight-dev/${IMAGE_NAME}:${TAG}"

echo "Push complete!"