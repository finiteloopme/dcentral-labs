#!/bin/bash
#
# Clean up local development containers
#

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Stop and remove Midnight development containers.

Options:
    -c, --container NAME    Container name (default: $DEFAULT_CONTAINER_NAME)
    -a, --all               Remove all midnight-* containers
    -h, --help              Show this help message

Examples:
    $(basename "$0")                    # Clean default container
    $(basename "$0") -c my-container    # Clean specific container
    $(basename "$0") -a                 # Clean all midnight containers
EOF
}

main() {
    local container_name=""
    local clean_all="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--container)
                container_name="$2"
                shift 2
                ;;
            -a|--all)
                clean_all="true"
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

    load_env
    require_podman

    if [[ "$clean_all" == "true" ]]; then
        log_info "Stopping all midnight containers..."
        podman ps -a --filter "name=midnight" --format "{{.Names}}" | while read -r name; do
            if [[ -n "$name" ]]; then
                log_info "Stopping: $name"
                podman stop "$name" 2>/dev/null || true
                podman rm "$name" 2>/dev/null || true
            fi
        done
        log_success "All midnight containers removed"
    else
        container_name="$(resolve_container_name "$container_name")"
        
        if podman ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
            log_info "Stopping container: $container_name"
            podman stop "$container_name" 2>/dev/null || true
            podman rm "$container_name" 2>/dev/null || true
            log_success "Container removed: $container_name"
        else
            log_info "Container not found: $container_name"
        fi
    fi
}

main "$@"
