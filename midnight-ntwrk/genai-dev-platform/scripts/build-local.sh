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

Build the Midnight development container locally using Podman.

Options:
    -n, --name NAME     Image name (default: $DEFAULT_IMAGE_NAME)
    -t, --tag TAG       Image tag (default: $DEFAULT_IMAGE_TAG)
    -f, --file FILE     Dockerfile path (default: $DOCKERFILE)
    --no-cache          Build without using cache
    -h, --help          Show this help message

Environment Variables:
    IMAGE_NAME          Override default image name
    IMAGE_TAG           Override default image tag

Examples:
    $(basename "$0")                          # Build with defaults
    $(basename "$0") -t dev                   # Build with 'dev' tag
    $(basename "$0") -n my-image -t v1.0      # Custom name and tag
    $(basename "$0") --no-cache               # Force rebuild without cache
EOF
}

# ==============================================================================
# Build Function
# ==============================================================================

build_image() {
    local image_name="$1"
    local image_tag="$2"
    local dockerfile="$3"
    local no_cache="$4"
    local full_image
    full_image="$(get_full_image "$image_name" "$image_tag")"

    local build_args=(
        "-t" "$full_image"
        "-f" "$dockerfile"
    )

    if [[ "$no_cache" == "true" ]]; then
        build_args+=("--no-cache")
    fi

    build_args+=("$PROJECT_ROOT")

    log_build "Building image: $full_image"
    log_info "Dockerfile: $dockerfile"
    log_info "Context: $PROJECT_ROOT"
    echo ""

    if podman build "${build_args[@]}"; then
        echo ""
        log_success "Image built successfully: $full_image"
        echo ""
        log_info "To run the container:"
        echo "    podman run -it --rm $full_image"
    else
        log_error "Build failed"
        exit 1
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local image_name=""
    local image_tag=""
    local dockerfile="$DOCKERFILE"
    local no_cache="false"

    # Parse arguments
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
            -f|--file)
                dockerfile="$2"
                shift 2
                ;;
            --no-cache)
                no_cache="true"
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

    # Resolve values with priority: CLI args > env vars > defaults
    image_name="$(resolve_image_name "$image_name")"
    image_tag="$(resolve_image_tag "$image_tag")"

    # Validate dependencies
    require_podman
    require_dockerfile

    # Build
    build_image "$image_name" "$image_tag" "$dockerfile" "$no_cache"
}

main "$@"
