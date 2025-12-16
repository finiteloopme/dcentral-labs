#!/bin/bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==============================================================================
# Usage
# ==============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Stop and remove Midnight development containers.

Options:
    -c, --container NAME      Container name (default: $DEFAULT_CONTAINER_NAME)
    -a, --all                 Remove all midnight-related containers
    -i, --images              Also remove images
    -f, --force               Force removal without confirmation
    -h, --help                Show this help message

Environment Variables:
    CONTAINER_NAME            Override default container name

Examples:
    $(basename "$0")                  # Stop and remove default container
    $(basename "$0") -a               # Remove all midnight containers
    $(basename "$0") -a -i            # Remove all containers and images
EOF
}

# ==============================================================================
# Cleanup Functions
# ==============================================================================

stop_and_remove_container() {
    local container_name="$1"
    
    if podman ps -aq --filter "name=^${container_name}$" | grep -q .; then
        log_cleanup "Stopping and removing container: $container_name"
        podman rm -f "$container_name" >/dev/null 2>&1
        log_success "Container removed: $container_name"
    else
        log_info "Container not found: $container_name"
    fi
}

remove_image() {
    local image_name="$1"
    local image_tag="$2"
    local full_image
    full_image="$(get_full_image "$image_name" "$image_tag")"
    
    if podman image exists "$full_image" 2>/dev/null; then
        log_cleanup "Removing image: $full_image"
        podman rmi -f "$full_image" >/dev/null
        log_success "Image removed: $full_image"
    else
        log_info "Image not found: $full_image"
    fi
}

clean_all_containers() {
    local containers
    containers=$(podman ps -aq --filter "name=midnight" 2>/dev/null || true)
    
    if [[ -n "$containers" ]]; then
        log_cleanup "Removing all midnight containers..."
        echo "$containers" | xargs -r podman rm -f >/dev/null
        log_success "All midnight containers removed"
    else
        log_info "No midnight containers found"
    fi
}

clean_all_images() {
    local images
    images=$(podman images --filter "reference=*midnight*" -q 2>/dev/null || true)
    
    if [[ -n "$images" ]]; then
        log_cleanup "Removing all midnight images..."
        echo "$images" | xargs -r podman rmi -f >/dev/null
        log_success "All midnight images removed"
    else
        log_info "No midnight images found"
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local container_name=""
    local remove_all="false"
    local remove_images="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--container)
                container_name="$2"
                shift 2
                ;;
            -a|--all)
                remove_all="true"
                shift
                ;;
            -i|--images)
                remove_images="true"
                shift
                ;;
            -f|--force)
                # Force flag (currently always forced, placeholder for future)
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Load .env file if present
    load_env

    # Resolve container name
    container_name="$(resolve_container_name "$container_name")"

    # Validate dependencies
    require_podman

    # Perform cleanup
    if [[ "$remove_all" == "true" ]]; then
        clean_all_containers
        if [[ "$remove_images" == "true" ]]; then
            clean_all_images
        fi
    else
        stop_and_remove_container "$container_name"
        if [[ "$remove_images" == "true" ]]; then
            local image_name image_tag
            image_name="$(resolve_image_name "")"
            image_tag="$(resolve_image_tag "")"
            remove_image "$image_name" "$image_tag"
        fi
    fi

    log_success "Cleanup complete"
}

main "$@"
