#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

log_info "Cleaning project..."

# Clean build artifacts
if [ -d "target" ]; then
    log_info "Removing target directory..."
    rm -rf target/
fi

# Clean logs
if [ -f "*.log" ]; then
    log_info "Removing log files..."
    rm -f *.log
fi

# Stop and remove containers
log_info "Stopping containers..."
podman stop abi-assistant-dev 2>/dev/null || true
podman stop abi-assistant-server 2>/dev/null || true

# Remove containers
podman rm abi-assistant-dev 2>/dev/null || true
podman rm abi-assistant-server 2>/dev/null || true

# Optionally remove images (only if --deep flag is passed)
if [ "${1:-}" = "--deep" ]; then
    log_warn "Deep clean: removing container images..."
    podman rmi abi-assistant:latest 2>/dev/null || true
    podman rmi abi-assistant-dev:latest 2>/dev/null || true
fi

log_info "✅ Cleanup complete!"