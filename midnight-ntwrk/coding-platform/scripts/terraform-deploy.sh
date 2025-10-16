#!/bin/bash
# Deploy infrastructure with Terraform

set -e
source "$(dirname "$0")/common.sh"

# Deploy infrastructure
deploy_infrastructure() {
    local project_id=$1
    local region=${2:-us-central1}
    local zone=${3:-us-central1-a}
    local environment=${4:-mvp}
    
    log_info "Deploying infrastructure..."
    log_info "Project: ${project_id}"
    log_info "Region: ${region}"
    log_info "Environment: ${environment}"
    
    cd terraform
    
    # Plan deployment
    terraform plan \
        -var="project_id=${project_id}" \
        -var="region=${region}" \
        -var="zone=${zone}" \
        -var="environment=${environment}" \
        -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    cd ..
    log_success "Infrastructure deployed"
}

# Get outputs
show_outputs() {
    log_info "Deployment outputs:"
    cd terraform
    echo ""
    terraform output
    cd ..
}

# Main execution
main() {
    local project_id="${1:-$(get_project_id)}"
    local region="${2:-us-central1}"
    local zone="${3:-us-central1-a}"
    local environment="${4:-mvp}"
    
    if [ -z "$project_id" ]; then
        log_error "PROJECT_ID not set"
        echo "Usage: $0 <project-id> [region] [zone] [environment]"
        exit 1
    fi
    
    deploy_infrastructure "$project_id" "$region" "$zone" "$environment"
    show_outputs
}

main "$@"