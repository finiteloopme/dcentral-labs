#!/bin/bash
# Clean local artifacts

set -e
source "$(dirname "$0")/common.sh"

# Clean Terraform files
clean_terraform() {
    log_info "Cleaning Terraform artifacts..."
    rm -rf terraform/.terraform
    rm -f terraform/terraform.tfstate*
    rm -f terraform/tfplan
    rm -f terraform/.terraform.lock.hcl
}

# Clean container images
clean_containers() {
    local image_name="${1:-midnight-workstation}"
    local runtime=$(detect_container_runtime)
    
    if [ -n "$runtime" ]; then
        log_info "Cleaning container images..."
        $runtime rmi "$image_name" 2>/dev/null || true
        
        if [ "$runtime" = "podman" ]; then
            podman system prune -f
        elif [ "$runtime" = "docker" ]; then
            docker system prune -f
        fi
    fi
}

# Clean build artifacts
clean_build() {
    log_info "Cleaning build artifacts..."
    find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.tar" -delete 2>/dev/null || true
    find . -type f -name "*.tar.gz" -delete 2>/dev/null || true
}

# Main execution
main() {
    log_info "Cleaning local artifacts..."
    
    clean_terraform
    clean_containers "$@"
    clean_build
    
    log_success "Clean complete"
}

main "$@"