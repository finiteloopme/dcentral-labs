#!/bin/bash
# Main deployment script
# Supports both local and Cloud Build deployment

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
PROJECT_ID="${1:-$PROJECT_ID}"
REGION="${2:-us-central1}"
ZONE="${3:-us-central1-a}"
ENV="${4:-mvp}"
USE_CLOUD_BUILD="${USE_CLOUD_BUILD:-false}"

# Check dependencies
check_all_dependencies() {
    log_info "Checking dependencies..."
    
    local required_tools=("gcloud" "terraform")
    if ! check_dependencies "${required_tools[@]}"; then
        exit 1
    fi
    
    # Check for container runtime
    local runtime=$(detect_container_runtime)
    if [ -z "$runtime" ]; then
        log_error "No container runtime found (podman or docker)"
        log_info "Please install: https://podman.io or https://docker.com"
        exit 1
    fi
    log_info "Using container runtime: $runtime"
    
    log_success "All dependencies found"
}

# Initialize GCP project
init_project() {
    log_info "Initializing GCP project: $PROJECT_ID"
    gcloud config set project "$PROJECT_ID"
}

# Run deployment steps
run_deployment() {
    log_info "Starting deployment..."
    
    # Initialize Terraform with GCS backend
    "${SCRIPT_DIR}/terraform-init.sh" "$PROJECT_ID"
    
    # Deploy infrastructure
    "${SCRIPT_DIR}/terraform-deploy.sh" "$PROJECT_ID" "$REGION" "$ZONE" "$ENV"
    
    # Build container image
    "${SCRIPT_DIR}/build.sh"
    
    # Push to registry
    "${SCRIPT_DIR}/push.sh"
    
    # Show status
    "${SCRIPT_DIR}/status.sh" "$PROJECT_ID" "$ENV" "$REGION"
}

# Display completion message
show_completion() {
    echo ""
    echo "=========================================="
    echo "✅ Deployment Complete!"
    echo "=========================================="
    echo ""
    
    # Get workstation URL
    if [ -f terraform/terraform.tfstate ]; then
        WORKSTATION_URL=$(cd terraform && terraform output -raw workstation_url 2>/dev/null || echo "")
        if [ -n "$WORKSTATION_URL" ]; then
            echo "Workstation URL: $WORKSTATION_URL"
            echo ""
        fi
    fi
    
    echo "Next Steps:"
    echo "1. Open the workstation URL in your browser"
    echo "2. In the terminal, run: midnight new my-dapp"
    echo "3. Compile with: make compile"
    echo "4. Start dev server: make dev"
    echo ""
    echo "To check status: make status"
    echo "To view logs: make logs"
}

# Deploy using Cloud Build
deploy_with_cloud_build() {
    log_info "Deploying using Cloud Build..."
    
    # Check if Cloud Build is set up
    if ! gcloud services list --enabled --filter="name:cloudbuild.googleapis.com" --format="value(name)" | grep -q cloudbuild; then
        log_warn "Cloud Build API not enabled. Enabling now..."
        gcloud services enable cloudbuild.googleapis.com
    fi
    
    # Submit build
    log_info "Submitting build to Cloud Build..."
    gcloud builds submit \
        --config=cicd/cloudbuild/cloudbuild.yaml \
        --substitutions="_ENVIRONMENT=${ENV},_TERRAFORM_ACTION=apply,_AUTO_APPROVE=true,_REGION=${REGION},_ZONE=${ZONE}" \
        --project=${PROJECT_ID} \
        .
    
    if [ $? -eq 0 ]; then
        log_success "Cloud Build deployment completed successfully!"
        echo ""
        echo "View build logs:"
        echo "  https://console.cloud.google.com/cloud-build/builds?project=${PROJECT_ID}"
    else
        log_error "Cloud Build deployment failed"
        exit 1
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "Midnight Development Platform Deployment"
    echo "=========================================="
    echo ""
    
    # Validate project ID
    if [ -z "$PROJECT_ID" ]; then
        log_error "PROJECT_ID not set"
        echo "Usage: $0 <project-id> [region] [zone] [environment]"
        echo "Example: $0 my-gcp-project us-central1 us-central1-a mvp"
        echo ""
        echo "For Cloud Build deployment:"
        echo "  USE_CLOUD_BUILD=true $0 my-gcp-project"
        exit 1
    fi
    
    if [ "$USE_CLOUD_BUILD" = "true" ]; then
        log_info "Using Cloud Build for deployment"
        deploy_with_cloud_build
    else
        log_info "Using local deployment"
        check_all_dependencies
        init_project
        run_deployment
        show_completion
    fi
}

# Run main function
main