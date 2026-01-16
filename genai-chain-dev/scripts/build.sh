#!/usr/bin/env bash
# Build chain development images
#
# Usage:
#   ./scripts/build.sh <chain>              # Build locally
#   ./scripts/build.sh <chain> --push       # Build and push to registry
#
# Examples:
#   ./scripts/build.sh somnia
#   ./scripts/build.sh somnia --push --project-id=my-project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

CHAIN=""
PUSH=false
PROJECT_ID=""
REGION="$DEFAULT_REGION"
TAG="$DEFAULT_TAG"
TARGET="dev"

# =============================================================================
# Parse Arguments
# =============================================================================

show_help() {
    cat << EOF
Build chain development images

Usage:
  $(basename "$0") <chain> [options]

Arguments:
  chain                     Chain to build (e.g., somnia, evm)

Options:
  --push                    Push image to Artifact Registry
  --project-id=ID           GCP project ID (required for --push)
  --region=REGION           GCP region (default: us-central1)
  --tag=TAG                 Image tag (default: latest)
  --target=TARGET           Earthly target (default: dev)
  -h, --help                Show this help message

Available chains:
$(list_chains | sed 's/^/  /')

Examples:
  $(basename "$0") somnia
  $(basename "$0") somnia --push --project-id=my-project
  $(basename "$0") somnia --tag=v1.0.0 --push --project-id=my-project
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --project-id=*)
            PROJECT_ID="${1#*=}"
            shift
            ;;
        --region=*)
            REGION="${1#*=}"
            shift
            ;;
        --tag=*)
            TAG="${1#*=}"
            shift
            ;;
        --target=*)
            TARGET="${1#*=}"
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$CHAIN" ]]; then
                CHAIN="$1"
            else
                log_error "Unexpected argument: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# =============================================================================
# Validate
# =============================================================================

if [[ -z "$CHAIN" ]]; then
    log_error "Chain argument required"
    show_help
    exit 1
fi

require_chain "$CHAIN"

if [[ "$PUSH" == "true" && -z "$PROJECT_ID" ]]; then
    log_error "--project-id required when using --push"
    exit 1
fi

# =============================================================================
# Build
# =============================================================================

log_info "Building ${CHAIN} development image..."
log_info "  Target: ${TARGET}"
log_info "  Tag: ${TAG}"

if [[ "$PUSH" == "true" ]]; then
    log_info "  Push: ${REGION}-docker.pkg.dev/${PROJECT_ID}/dev-images/${CHAIN}-dev:${TAG}"
    push_chain_image "$CHAIN" "$PROJECT_ID" "$REGION" "$TAG"
else
    build_chain_image "$CHAIN" "$TARGET"
fi

log_success "Build complete!"
