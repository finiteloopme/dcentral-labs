#!/bin/bash

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if required environment variables are set
if [ -z "$PROJECT_ID" ]; then
    print_error "PROJECT_ID environment variable is not set"
    echo "Please set it using: export PROJECT_ID=your-project-id"
    exit 1
fi

# Set default values
REGION="${REGION:-us-central1}"
REPO_NAME="${REPO_NAME:-web3-workstation-images}"
IMAGE_NAME="${IMAGE_NAME:-web3-workstation}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
USE_DOCKER="${USE_DOCKER:-false}"

# Construct the full image URL
FULL_IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# Detect container runtime
CONTAINER_RUNTIME=""
if [ "$USE_DOCKER" = "true" ] && command -v docker &> /dev/null; then
    CONTAINER_RUNTIME="docker"
    print_info "Using Docker as container runtime (USE_DOCKER=true)"
elif command -v podman &> /dev/null; then
    CONTAINER_RUNTIME="podman"
    print_info "Using Podman as container runtime"
elif command -v docker &> /dev/null; then
    CONTAINER_RUNTIME="docker"
    print_warning "Podman not found, falling back to Docker"
else
    print_error "Neither Podman nor Docker is installed"
    echo "Please install Podman from: https://podman.io/getting-started/installation"
    echo "Or install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

print_status "Building and pushing container image for Web3 Workstation"
echo "Runtime: ${CONTAINER_RUNTIME}"
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Repository: ${REPO_NAME}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Full URL: ${FULL_IMAGE_URL}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Authenticate with gcloud
print_status "Authenticating with Google Cloud..."
gcloud auth application-default login --quiet 2>/dev/null || true

# Set the project
print_status "Setting GCP project to ${PROJECT_ID}..."
gcloud config set project ${PROJECT_ID}

# Configure container runtime authentication for Artifact Registry
if [ "$CONTAINER_RUNTIME" = "podman" ]; then
    print_status "Configuring Podman authentication for Artifact Registry..."
    
    # Get access token for authentication
    ACCESS_TOKEN=$(gcloud auth print-access-token)
    
    # Login to Artifact Registry with Podman
    echo $ACCESS_TOKEN | ${CONTAINER_RUNTIME} login -u oauth2accesstoken --password-stdin ${REGION}-docker.pkg.dev
    
    print_info "Podman authentication configured"
else
    print_status "Configuring Docker authentication for Artifact Registry..."
    gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
fi

# Check if the Artifact Registry repository exists
print_status "Checking if Artifact Registry repository exists..."
if ! gcloud artifacts repositories describe ${REPO_NAME} --location=${REGION} &>/dev/null; then
    print_warning "Artifact Registry repository '${REPO_NAME}' does not exist"
    print_status "Creating Artifact Registry repository..."
    gcloud artifacts repositories create ${REPO_NAME} \
        --repository-format=docker \
        --location=${REGION} \
        --description="Docker repository for Web3 workstation images"
fi

# Build the container image
print_status "Building container image with ${CONTAINER_RUNTIME}..."
cd docker

if [ "$CONTAINER_RUNTIME" = "podman" ]; then
    # Podman-specific build options
    ${CONTAINER_RUNTIME} build \
        --format docker \
        --layers \
        -t ${FULL_IMAGE_URL} \
        .
else
    # Docker build
    ${CONTAINER_RUNTIME} build -t ${FULL_IMAGE_URL} .
fi

if [ $? -eq 0 ]; then
    print_status "Container image built successfully"
else
    print_error "Failed to build container image"
    exit 1
fi

# Push the image to Artifact Registry
print_status "Pushing image to Artifact Registry..."
${CONTAINER_RUNTIME} push ${FULL_IMAGE_URL}

if [ $? -eq 0 ]; then
    print_status "Container image pushed successfully"
    echo ""
    echo "=================================================================================="
    echo "Image successfully built and pushed!"
    echo "Image URL: ${FULL_IMAGE_URL}"
    echo ""
    echo "You can now deploy the workstation using Terraform:"
    echo "  cd ../terraform"
    echo "  terraform init -backend-config=\"bucket=${PROJECT_ID}-web3-workstation-terraform-state\""
    echo "  terraform apply"
    echo "=================================================================================="
else
    print_error "Failed to push Docker image"
    exit 1
fi