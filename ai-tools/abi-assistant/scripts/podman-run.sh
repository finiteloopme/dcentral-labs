#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

# Ensure production container exists
if ! podman image exists abi-assistant:latest; then
    log_info "Building production container..."
    "$SCRIPT_DIR/podman-build.sh" release
fi

load_env

log_info "Starting production server..."
log_info "Server running at http://localhost:${MCP_PORT:-3000}"

podman run --rm \
    --name abi-assistant-server \
    -p ${MCP_PORT:-3000}:3000 \
    -v ./data:/data:Z \
    -v ./logs:/logs:Z \
    --env-file .env \
    abi-assistant:latest