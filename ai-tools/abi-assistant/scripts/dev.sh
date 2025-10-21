#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

log_info "Starting development server..."

# Load environment
load_env

# Set development environment
export RUST_LOG=${RUST_LOG:-debug}
export RUST_BACKTRACE=1
export MCP_HOST=${MCP_HOST:-127.0.0.1}
export MCP_PORT=${MCP_PORT:-3000}

# Check if port is available
if ! check_port $MCP_PORT; then
    log_error "Port $MCP_PORT is already in use. Please stop the existing process or change MCP_PORT in .env"
    exit 1
fi

# Watch for changes and rebuild
if command -v cargo-watch &> /dev/null; then
    log_info "Starting with auto-reload (cargo-watch detected)..."
    log_info "Server will run on http://$MCP_HOST:$MCP_PORT"
    cargo watch -x 'run' -w src/
else
    log_warn "cargo-watch not installed. Install with: cargo install cargo-watch"
    log_info "Running without auto-reload..."
    log_info "Server will run on http://$MCP_HOST:$MCP_PORT"
    cargo run
fi