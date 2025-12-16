#!/bin/bash
#
# Common utilities and configuration for Midnight development scripts.
# Source this file in other scripts: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
#

# Prevent double-sourcing
if [[ -n "${_COMMON_SH_LOADED:-}" ]]; then
    return 0
fi
readonly _COMMON_SH_LOADED=1

# ==============================================================================
# Configuration
# ==============================================================================

# Resolve paths relative to the script that sources this file
readonly SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
readonly DOCKERFILE="${PROJECT_ROOT}/Dockerfile"

# Default image configuration
readonly DEFAULT_IMAGE_NAME="midnight-vibe-platform"
readonly DEFAULT_IMAGE_TAG="latest"
readonly DEFAULT_CONTAINER_NAME="midnight-dev"

# ==============================================================================
# Logging Functions
# ==============================================================================

log_info() {
    echo "🌙 $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1" >&2
}

log_warning() {
    echo "⚠️  $1"
}

log_build() {
    echo "🏗️  $1"
}

log_launch() {
    echo "🚀 $1"
}

log_cleanup() {
    echo "🧹 $1"
}

log_wait() {
    echo "⏳ $1"
}

# ==============================================================================
# Environment Loading
# ==============================================================================

load_env() {
    local env_file="${PROJECT_ROOT}/.env"
    if [[ -f "$env_file" ]]; then
        log_info "Loading environment from .env file..."
        # shellcheck source=/dev/null
        source "$env_file"
    fi
}

# ==============================================================================
# Validation Functions
# ==============================================================================

require_podman() {
    if ! command -v podman &>/dev/null; then
        log_error "Podman is not installed. Please install podman first."
        exit 1
    fi
}

require_dockerfile() {
    if [[ ! -f "$DOCKERFILE" ]]; then
        log_error "Dockerfile not found at: $DOCKERFILE"
        exit 1
    fi
}

require_image() {
    local full_image="$1"
    if ! podman image exists "$full_image" 2>/dev/null; then
        log_error "Image not found: $full_image"
        log_info "Run 'make build' or './scripts/build-local.sh' first."
        exit 1
    fi
}

# ==============================================================================
# Image Helpers
# ==============================================================================

# Resolve image name with priority: CLI arg > env var > default
resolve_image_name() {
    local cli_arg="${1:-}"
    echo "${cli_arg:-${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}}"
}

# Resolve image tag with priority: CLI arg > env var > default
resolve_image_tag() {
    local cli_arg="${1:-}"
    echo "${cli_arg:-${IMAGE_TAG:-$DEFAULT_IMAGE_TAG}}"
}

# Resolve container name with priority: CLI arg > env var > default
resolve_container_name() {
    local cli_arg="${1:-}"
    echo "${cli_arg:-${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}}"
}

# Get full image reference (name:tag)
get_full_image() {
    local name="$1"
    local tag="$2"
    echo "${name}:${tag}"
}
