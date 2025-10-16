#!/bin/bash
# Build container image

set -e
source "$(dirname "$0")/common.sh"

# Build container image
build_image() {
    local image_name="${1:-midnight-workstation}"
    local image_tag="${2:-latest}"
    
    log_info "Building container image: ${image_name}:${image_tag}"
    
    if ! container_cmd build -t "${image_name}:${image_tag}" docker/; then
        log_error "Failed to build container image"
        return 1
    fi
    
    log_success "Container image built: ${image_name}:${image_tag}"
}

# Main execution
main() {
    local image_name="${1:-midnight-workstation}"
    local image_tag="${2:-latest}"
    
    # Check for container runtime
    if [ -z "$(detect_container_runtime)" ]; then
        log_error "No container runtime found. Please install podman or docker."
        exit 1
    fi
    
    build_image "$image_name" "$image_tag"
}

main "$@"