#!/bin/bash
#
# Build the Midnight SDK container image
#
# This builds the SDK packages from source (midnight-ledger, midnight-wallet, midnight-js)
# and creates a container image that the main Dockerfile can use.
#
# The SDK image contains /opt/vendor with all built packages.
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

Build the Midnight SDK container image from source.

This builds:
  - midnight-ledger (WASM packages via Nix)
  - midnight-wallet (TypeScript packages)
  - midnight-js (TypeScript packages)

The resulting image contains /opt/vendor with all built packages.

Options:
    -n, --name NAME     Image name (default: $DEFAULT_SDK_IMAGE_NAME)
    -t, --tag TAG       Image tag (default: $DEFAULT_SDK_IMAGE_TAG)
    --no-cache          Build without cache
    --composite-tag     Use composite version tag (ledger-X_wallet-Y_js-Z)
    -h, --help          Show this help message

Examples:
    $(basename "$0")                    # Build with defaults
    $(basename "$0") --composite-tag    # Build with version-based tag
    $(basename "$0") --no-cache         # Force rebuild
EOF
}

# Extract version ARGs from Dockerfile.sdk
get_sdk_versions() {
    local dockerfile="$1"
    
    LEDGER_TAG=$(grep -E '^ARG LEDGER_TAG=' "$dockerfile" | cut -d= -f2)
    WALLET_COMMIT=$(grep -E '^ARG WALLET_COMMIT=' "$dockerfile" | cut -d= -f2)
    JS_TAG=$(grep -E '^ARG JS_TAG=' "$dockerfile" | cut -d= -f2)
    
    # Clean up version strings for use in tag
    LEDGER_TAG_CLEAN=$(echo "$LEDGER_TAG" | sed 's/ledger-//')
    WALLET_COMMIT_CLEAN=$(echo "$WALLET_COMMIT" | cut -c1-7)
    JS_TAG_CLEAN=$(echo "$JS_TAG" | sed 's/v//')
}

# Generate composite tag from versions
generate_composite_tag() {
    echo "ledger-${LEDGER_TAG_CLEAN}_wallet-${WALLET_COMMIT_CLEAN}_js-${JS_TAG_CLEAN}"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local sdk_image_name=""
    local sdk_image_tag=""
    local no_cache=""
    local use_composite_tag=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                sdk_image_name="$2"
                shift 2
                ;;
            -t|--tag)
                sdk_image_tag="$2"
                shift 2
                ;;
            --no-cache)
                no_cache="--no-cache"
                shift
                ;;
            --composite-tag)
                use_composite_tag=true
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

    # Resolve image name
    sdk_image_name="${sdk_image_name:-${SDK_IMAGE_NAME:-$DEFAULT_SDK_IMAGE_NAME}}"

    require_podman

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_dir="${script_dir}/.."
    local dockerfile="${project_dir}/Dockerfile.sdk"

    if [[ ! -f "$dockerfile" ]]; then
        log_error "Dockerfile.sdk not found at: $dockerfile"
        exit 1
    fi

    # Get versions from Dockerfile.sdk
    get_sdk_versions "$dockerfile"

    # Determine tag
    if [[ "$use_composite_tag" == "true" ]]; then
        sdk_image_tag=$(generate_composite_tag)
        log_info "Using composite tag: $sdk_image_tag"
    else
        sdk_image_tag="${sdk_image_tag:-${SDK_IMAGE_TAG:-$DEFAULT_SDK_IMAGE_TAG}}"
    fi

    local full_image="${sdk_image_name}:${sdk_image_tag}"

    log_info "Building SDK image: $full_image"
    log_info "  Ledger:  $LEDGER_TAG"
    log_info "  Wallet:  $WALLET_COMMIT"
    log_info "  JS:      $JS_TAG"
    echo ""
    log_warning "This may take 30+ minutes on first build (Nix cache is empty)"
    echo ""

    podman build \
        $no_cache \
        -f "$dockerfile" \
        -t "$full_image" \
        "$project_dir"

    # Also tag as latest if using composite tag
    if [[ "$use_composite_tag" == "true" ]]; then
        local latest_image="${sdk_image_name}:latest"
        log_info "Tagging as: $latest_image"
        podman tag "$full_image" "$latest_image"
    fi

    log_success "SDK image built: $full_image"
    echo ""
    log_info "Next steps:"
    log_info "  make build    # Build main container using SDK image"
}

main "$@"
