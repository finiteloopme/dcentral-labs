#!/bin/bash
# Main deployment script

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
PROJECT_ID="${1:-$PROJECT_ID}"
REGION="${2:-us-central1}"
ZONE="${3:-us-central1-a}"
ENV="${4:-mvp}"

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
        exit 1
    fi
    
    check_all_dependencies
    init_project
    run_deployment
    show_completion
}

# Run main function
main