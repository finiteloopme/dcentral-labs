#!/bin/bash
# Initialize Terraform with GCS backend

set -e
source "$(dirname "$0")/common.sh"

# Initialize Terraform with backend configuration
init_terraform() {
    local project_id=$1
    local bucket_name="${2:-${project_id}-terraform-state}"
    
    log_info "Initializing Terraform with GCS backend..."
    
    # Create bucket if it doesn't exist
    if ! gsutil ls -b "gs://${bucket_name}" &>/dev/null; then
        log_info "Creating state bucket: ${bucket_name}"
        gsutil mb -p "${project_id}" -l US "gs://${bucket_name}"
        gsutil versioning set on "gs://${bucket_name}"
    fi
    
    cd terraform
    
    # Initialize with backend config
    terraform init \
        -backend-config="bucket=${bucket_name}" \
        -backend-config="prefix=terraform/state" \
        -upgrade
    
    log_success "Terraform initialized with GCS backend"
    cd ..
}

# Validate configuration
validate_terraform() {
    log_info "Validating Terraform configuration..."
    cd terraform
    terraform validate
    terraform fmt -check
    cd ..
    log_success "Terraform configuration valid"
}

# Main execution
main() {
    local project_id="${1:-$PROJECT_ID}"
    local bucket_name="${2:-}"
    
    if [ -z "$project_id" ]; then
        log_error "PROJECT_ID not set"
        exit 1
    fi
    
    init_terraform "$project_id" "$bucket_name"
    validate_terraform
}

main "$@"