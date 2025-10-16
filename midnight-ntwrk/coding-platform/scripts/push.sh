#!/bin/bash
# Push container image to registry

set -e
source "$(dirname "$0")/common.sh"

# Get registry URL from Terraform
get_registry_url() {
    cd terraform && terraform output -raw registry_url 2>/dev/null || echo ""
}

# Push image to registry
push_image() {
    local image_name="${1:-midnight-workstation}"
    local image_tag="${2:-latest}"
    
    log_info "Pushing container image to registry..."
    
    # Get registry URL
    local registry_url=$(get_registry_url)
    if [ -z "$registry_url" ]; then
        log_error "Registry not found. Run 'make deploy' first"
        return 1
    fi
    
    log_info "Registry URL: ${registry_url}"
    
    # Configure authentication
    local registry_host=$(echo "$registry_url" | cut -d'/' -f1)
    gcloud auth configure-docker "$registry_host" --quiet
    
    # Tag and push
    local full_image="${registry_url}/${image_name}:${image_tag}"
    container_cmd tag "${image_name}:${image_tag}" "$full_image"
    container_cmd push "$full_image"
    
    log_success "Image pushed to registry"
}

# Main execution
main() {
    local image_name="${1:-midnight-workstation}"
    local image_tag="${2:-latest}"
    
    # Check dependencies
    if ! check_dependencies gcloud; then
        exit 1
    fi
    
    # Check for container runtime
    if [ -z "$(detect_container_runtime)" ]; then
        log_error "No container runtime found"
        exit 1
    fi
    
    push_image "$image_name" "$image_tag"
}

main "$@"