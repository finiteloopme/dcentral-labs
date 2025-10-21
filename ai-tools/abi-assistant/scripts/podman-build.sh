#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

# Build type: dev or release
BUILD_TYPE=${1:-dev}

case "$BUILD_TYPE" in
    dev)
        log_info "Building development container..."
        podman build -f Dockerfile.dev -t abi-assistant-dev:latest .
        ;;
    release)
        log_info "Building release container..."
        podman build -f Dockerfile -t abi-assistant:latest .
        ;;
    *)
        log_error "Invalid build type: $BUILD_TYPE (use 'dev' or 'release')"
        exit 1
        ;;
esac

log_info "✅ Build complete!"