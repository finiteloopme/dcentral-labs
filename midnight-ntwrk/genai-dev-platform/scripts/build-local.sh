#!/bin/bash
#
# Build the development container locally using Podman
#

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build the Midnight development container locally using Podman.

Options:
    -n, --name NAME     Image name (default: $DEFAULT_IMAGE_NAME)
    -t, --tag TAG       Image tag (default: $DEFAULT_IMAGE_TAG)
    --no-cache          Build without cache
    -h, --help          Show this help message

Examples:
    $(basename "$0")                    # Build with defaults
    $(basename "$0") -t dev             # Build with custom tag
    $(basename "$0") --no-cache         # Force rebuild
EOF
}

main() {
    local image_name=""
    local image_tag=""
    local no_cache=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                image_name="$2"
                shift 2
                ;;
            -t|--tag)
                image_tag="$2"
                shift 2
                ;;
            --no-cache)
                no_cache="--no-cache"
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

    image_name="$(resolve_image_name "$image_name")"
    image_tag="$(resolve_image_tag "$image_tag")"

    require_podman

    local full_image
    full_image="$(get_full_image "$image_name" "$image_tag")"

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_dir="${script_dir}/.."

    log_info "Building image: $full_image"
    
    podman build \
        $no_cache \
        -t "$full_image" \
        "$project_dir"

    log_success "Image built: $full_image"
}

main "$@"
