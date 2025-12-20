#!/bin/bash
#
# Build the development container locally using Podman
#
# Requires the SDK image to be built first (make build-sdk)
#

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==============================================================================
# Defaults
# ==============================================================================

readonly DEFAULT_SDK_IMAGE_NAME="midnight-sdk"
readonly DEFAULT_SDK_IMAGE_TAG="latest"

# ==============================================================================
# Functions
# ==============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build the Midnight development container locally using Podman.

Requires the SDK image to be built first:
    make build-sdk

Options:
    -n, --name NAME         Image name (default: $DEFAULT_IMAGE_NAME)
    -t, --tag TAG           Image tag (default: $DEFAULT_IMAGE_TAG)
    --sdk-image IMAGE       SDK image to use (default: $DEFAULT_SDK_IMAGE_NAME:$DEFAULT_SDK_IMAGE_TAG)
    --no-cache              Build without cache
    -h, --help              Show this help message

Examples:
    $(basename "$0")                    # Build with defaults
    $(basename "$0") -t dev             # Build with custom tag
    $(basename "$0") --no-cache         # Force rebuild
EOF
}

require_sdk_image() {
    local sdk_image="$1"
    
    if ! podman image exists "$sdk_image" 2>/dev/null; then
        log_error "SDK image not found: $sdk_image"
        echo ""
        echo "The SDK image must be built first. Run:"
        echo ""
        echo "    make build-sdk"
        echo ""
        echo "This builds the Midnight SDK packages from source (~30 min first time)."
        echo "The SDK image only needs to be rebuilt when upgrading SDK versions."
        exit 1
    fi
    
    log_success "SDK image found: $sdk_image"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local image_name=""
    local image_tag=""
    local sdk_image=""
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
            --sdk-image)
                sdk_image="$2"
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
    
    # Resolve SDK image
    local sdk_image_name="${SDK_IMAGE_NAME:-$DEFAULT_SDK_IMAGE_NAME}"
    local sdk_image_tag="${SDK_IMAGE_TAG:-$DEFAULT_SDK_IMAGE_TAG}"
    sdk_image="${sdk_image:-${sdk_image_name}:${sdk_image_tag}}"

    require_podman
    require_sdk_image "$sdk_image"

    local full_image
    full_image="$(get_full_image "$image_name" "$image_tag")"

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_dir="${script_dir}/.."

    log_info "Building image: $full_image"
    log_info "Using SDK image: $sdk_image"
    
    podman build \
        $no_cache \
        --build-arg "SDK_IMAGE=${sdk_image}" \
        -t "$full_image" \
        "$project_dir"

    log_success "Image built: $full_image"
}

main "$@"
