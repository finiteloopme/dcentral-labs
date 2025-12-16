#!/bin/bash
#
# Common utilities for local development scripts
#

set -euo pipefail

# ==============================================================================
# Defaults
# ==============================================================================

readonly DEFAULT_IMAGE_NAME="midnight-dev-platform"
readonly DEFAULT_IMAGE_TAG="latest"
readonly DEFAULT_CONTAINER_NAME="midnight-dev"

# ==============================================================================
# Logging
# ==============================================================================

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[OK] $1"
}

log_warning() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_launch() {
    echo "[LAUNCH] $1"
}

# ==============================================================================
# Environment
# ==============================================================================

load_env() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local env_file="${script_dir}/../.env"
    
    if [[ -f "$env_file" ]]; then
        # shellcheck source=/dev/null
        source "$env_file"
    fi
}

# ==============================================================================
# Image/Container Resolution
# ==============================================================================

resolve_image_name() {
    local cli_value="${1:-}"
    echo "${cli_value:-${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}}"
}

resolve_image_tag() {
    local cli_value="${1:-}"
    echo "${cli_value:-${IMAGE_TAG:-$DEFAULT_IMAGE_TAG}}"
}

resolve_container_name() {
    local cli_value="${1:-}"
    echo "${cli_value:-${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}}"
}

get_full_image() {
    local name="$1"
    local tag="$2"
    echo "${name}:${tag}"
}

# ==============================================================================
# Validation
# ==============================================================================

require_podman() {
    if ! command -v podman &> /dev/null; then
        log_error "podman is required but not installed"
        log_info "Install podman: https://podman.io/getting-started/installation"
        exit 1
    fi
}

require_image() {
    local image="$1"
    if ! podman image exists "$image" 2>/dev/null; then
        log_error "Image not found: $image"
        log_info "Run: make build"
        exit 1
    fi
}
