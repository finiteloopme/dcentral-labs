#!/bin/bash

# Podman-specific build and push script with enhanced features

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    print_error "Podman is not installed"
    echo ""
    echo "Installation instructions:"
    echo ""
    echo "# Ubuntu/Debian:"
    echo "sudo apt-get update"
    echo "sudo apt-get install -y podman"
    echo ""
    echo "# RHEL/CentOS/Fedora:"
    echo "sudo dnf install -y podman"
    echo ""
    echo "# macOS:"
    echo "brew install podman"
    echo "podman machine init"
    echo "podman machine start"
    echo ""
    exit 1
fi

# Check Podman version
PODMAN_VERSION=$(podman --version | awk '{print $3}')
print_info "Podman version: ${PODMAN_VERSION}"

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
BUILD_FORMAT="${BUILD_FORMAT:-docker}"  # Use docker format for compatibility
ENABLE_CACHE="${ENABLE_CACHE:-true}"
PUSH_RETRY="${PUSH_RETRY:-3}"

# Construct the full image URL
FULL_IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
FULL_IMAGE_URL_SHA="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')"

print_status "Podman Build Configuration for Web3 Workstation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project ID:    ${PROJECT_ID}"
echo "Region:        ${REGION}"
echo "Repository:    ${REPO_NAME}"
echo "Image:         ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Format:        ${BUILD_FORMAT}"
echo "Cache:         ${ENABLE_CACHE}"
echo "Full URL:      ${FULL_IMAGE_URL}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if running on macOS and Podman machine is running
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_info "Detected macOS - checking Podman machine status..."
    if ! podman machine list | grep -q "Currently running"; then
        print_warning "Podman machine is not running"
        echo "Starting Podman machine..."
        podman machine start
    fi
fi

# Authenticate with gcloud
print_status "Authenticating with Google Cloud..."
gcloud auth application-default login --quiet 2>/dev/null || true

# Set the project
print_status "Setting GCP project to ${PROJECT_ID}..."
gcloud config set project ${PROJECT_ID}

# Configure Podman authentication for Artifact Registry
print_status "Configuring Podman authentication for Artifact Registry..."

# Method 1: Using gcloud access token (recommended)
ACCESS_TOKEN=$(gcloud auth print-access-token)
echo $ACCESS_TOKEN | podman login -u oauth2accesstoken --password-stdin ${REGION}-docker.pkg.dev

if [ $? -ne 0 ]; then
    print_warning "Primary authentication failed, trying alternative method..."
    
    # Method 2: Using service account key (fallback)
    KEY_FILE="/tmp/gcr-key.json"
    gcloud iam service-accounts keys create ${KEY_FILE} \
        --iam-account=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com 2>/dev/null || true
    
    if [ -f "$KEY_FILE" ]; then
        cat ${KEY_FILE} | podman login -u _json_key --password-stdin ${REGION}-docker.pkg.dev
        rm -f ${KEY_FILE}
    fi
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

# Create a Podman-specific build context
print_status "Preparing build context..."
cd docker

# Check for .dockerignore and create .containerignore if needed
if [ -f ".dockerignore" ] && [ ! -f ".containerignore" ]; then
    print_info "Creating .containerignore from .dockerignore"
    cp .dockerignore .containerignore
fi

# Build options
BUILD_OPTS=""

# Add format option
BUILD_OPTS="${BUILD_OPTS} --format ${BUILD_FORMAT}"

# Add layer caching
if [ "$ENABLE_CACHE" = "true" ]; then
    BUILD_OPTS="${BUILD_OPTS} --layers"
else
    BUILD_OPTS="${BUILD_OPTS} --no-cache"
fi

# Add security options
BUILD_OPTS="${BUILD_OPTS} --cap-drop=all"
BUILD_OPTS="${BUILD_OPTS} --security-opt label=disable"

# Build the container image
print_status "Building container image with Podman..."
print_info "Build command: podman build ${BUILD_OPTS} -t ${FULL_IMAGE_URL} ."

podman build ${BUILD_OPTS} \
    -t ${FULL_IMAGE_URL} \
    -t ${FULL_IMAGE_URL_SHA} \
    .

if [ $? -eq 0 ]; then
    print_status "Container image built successfully"
    
    # Display image information
    print_info "Image details:"
    podman images --filter "reference=${IMAGE_NAME}" --format "table {{.Repository}}:{{.Tag}} {{.Size}} {{.Created}}"
else
    print_error "Failed to build container image"
    exit 1
fi

# Verify image
print_status "Verifying image..."
podman inspect ${FULL_IMAGE_URL} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    print_error "Image verification failed"
    exit 1
fi

# Optional: Run security scan with Podman
if command -v trivy &> /dev/null; then
    print_info "Running security scan with Trivy..."
    podman save ${FULL_IMAGE_URL} | trivy image --input - --severity HIGH,CRITICAL --quiet || true
fi

# Push the image to Artifact Registry with retry logic
push_with_retry() {
    local url=$1
    local attempt=1
    
    while [ $attempt -le $PUSH_RETRY ]; do
        print_status "Pushing image (attempt ${attempt}/${PUSH_RETRY})..."
        
        if podman push ${url}; then
            print_status "Successfully pushed: ${url}"
            return 0
        else
            print_warning "Push attempt ${attempt} failed"
            attempt=$((attempt + 1))
            if [ $attempt -le $PUSH_RETRY ]; then
                print_info "Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done
    
    return 1
}

# Push with latest tag
if push_with_retry ${FULL_IMAGE_URL}; then
    print_status "Image pushed with 'latest' tag"
else
    print_error "Failed to push image after ${PUSH_RETRY} attempts"
    exit 1
fi

# Push with SHA tag
if [ "${FULL_IMAGE_URL_SHA}" != "${FULL_IMAGE_URL}" ]; then
    if push_with_retry ${FULL_IMAGE_URL_SHA}; then
        print_status "Image pushed with SHA tag"
    else
        print_warning "Failed to push SHA-tagged image, continuing..."
    fi
fi

# Clean up local images (optional)
read -p "Do you want to remove local images to save space? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing local images..."
    podman rmi ${FULL_IMAGE_URL} ${FULL_IMAGE_URL_SHA} 2>/dev/null || true
fi

# Display summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_status "Build and push completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Image URLs:"
echo "  • ${FULL_IMAGE_URL}"
if [ "${FULL_IMAGE_URL_SHA}" != "${FULL_IMAGE_URL}" ]; then
    echo "  • ${FULL_IMAGE_URL_SHA}"
fi
echo ""
echo "Next steps:"
echo "  1. Deploy with Terraform:"
echo "     cd ../terraform"
echo "     terraform init -backend-config=\"bucket=${PROJECT_ID}-web3-workstation-terraform-state\""
echo "     terraform apply"
echo ""
echo "  2. Verify image in Artifact Registry:"
echo "     gcloud artifacts docker images list --repository=${REPO_NAME} --location=${REGION}"
echo ""
echo "  3. Test locally with Podman:"
echo "     podman run --rm -it ${FULL_IMAGE_URL} /bin/bash"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"