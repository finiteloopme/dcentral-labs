#!/usr/bin/env bash
# Quick development server for local development (no container)
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
USE_CONTAINER="${1:-}"

if [[ "$USE_CONTAINER" == "--container" ]]; then
    # Use container for development
    exec "$SCRIPT_DIR/container.sh" run dev
fi

log_info "Starting local development server..."

# Load environment
load_env

# Set development environment
export RUST_LOG=${RUST_LOG:-debug}
export RUST_BACKTRACE=1
export MCP_HOST=${MCP_HOST:-127.0.0.1}
export MCP_PORT=${MCP_PORT:-3000}

# Check if port is available
if ! check_port $MCP_PORT; then
    log_error "Port $MCP_PORT is already in use"
    exit 1
fi

# Watch for changes and rebuild
if command -v cargo-watch &> /dev/null; then
    log_info "Starting with auto-reload..."
    log_info "Server: http://$MCP_HOST:$MCP_PORT"
    cargo watch -x 'run' -w src/
else
    log_info "Starting without auto-reload..."
    log_info "Server: http://$MCP_HOST:$MCP_PORT"
    log_info "Tip: Install cargo-watch for auto-reload: cargo install cargo-watch"
    cargo run
fi