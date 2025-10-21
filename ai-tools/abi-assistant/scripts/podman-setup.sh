#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

log_info "Setting up ABI Assistant..."

# Check prerequisites
require_cmd podman

# Build development container
"$SCRIPT_DIR/podman-build.sh" dev

# Create necessary directories
log_info "Creating project directories..."
ensure_dir "$DATA_DIR"
ensure_dir "$DATA_DIR/abis"
ensure_dir "$LOGS_DIR"
ensure_dir "resources/abis"
ensure_dir "resources/protocols"

# Setup database
if [ -x "$SCRIPTS_DIR/db-setup.sh" ]; then
    "$SCRIPTS_DIR/db-setup.sh"
fi

# Create .env if needed
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        log_warn "Created .env file. Please update with your settings."
    fi
fi

log_info "✅ Setup complete! Run 'make dev' to start."