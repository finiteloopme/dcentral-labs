#!/usr/bin/env bash
set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

log_info "Setting up ABI Assistant MCP Server..."

# Check prerequisites
log_info "Checking prerequisites..."
require_cmd cargo
require_cmd rustc
require_cmd sqlite3

# Check Rust version
RUST_VERSION=$(rustc --version | awk '{print $2}')
log_info "Rust version: $RUST_VERSION"

# Install Rust dependencies
log_info "Installing Rust dependencies..."
cargo fetch

# Create necessary directories
log_info "Creating project directories..."
ensure_dir "$DATA_DIR"
ensure_dir "$DATA_DIR/abis"
ensure_dir "$DATA_DIR/cache"
ensure_dir "$LOGS_DIR"
ensure_dir "resources/abis"
ensure_dir "resources/protocols"
ensure_dir "resources/intent_patterns"

# Setup database
log_info "Setting up database..."
if [ -x "$SCRIPTS_DIR/db-setup.sh" ]; then
    "$SCRIPTS_DIR/db-setup.sh"
else
    log_warn "Database setup script not found, skipping..."
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    log_info "Creating .env file..."
    if [ -f .env.example ]; then
        cp .env.example .env
        log_warn "Please update .env with your configuration"
    else
        log_warn ".env.example not found, skipping .env creation"
    fi
fi

# Fetch common ABIs if script exists
if [ -x "$SCRIPTS_DIR/abi-fetch.sh" ]; then
    log_info "Fetching common protocol ABIs..."
    "$SCRIPTS_DIR/abi-fetch.sh"
else
    log_info "ABI fetch script not found, skipping..."
fi

# Build the project for the first time
log_info "Building project..."
cargo build

# Run tests to ensure everything is working
log_info "Running initial tests..."
cargo test --lib

log_info "✅ Setup complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Update .env with your RPC endpoints and API keys"
log_info "  2. Run 'make dev' to start the development server"
log_info "  3. Run 'make test' to run the test suite"