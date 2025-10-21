#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

# Operation to perform
OPERATION=${1:-run}

# Common podman run command
run_in_container() {
    podman run --rm \
        -v ./:/workspace:Z \
        -w /workspace \
        abi-assistant-dev:latest \
        "$@"
}

# Ensure dev container exists
ensure_container() {
    if ! podman image exists abi-assistant-dev:latest; then
        log_info "Building development container..."
        "$SCRIPT_DIR/podman-build.sh" dev
    fi
}

case "$OPERATION" in
    run)
        ensure_container
        load_env
        
        log_info "Starting development server..."
        log_info "Server will be available at http://localhost:${MCP_PORT:-3000}"
        
        podman run -it --rm \
            --name abi-assistant-dev \
            -v ./:/workspace:Z \
            -v cargo-cache:/usr/local/cargo/registry \
            -w /workspace \
            -p ${MCP_PORT:-3000}:${MCP_PORT:-3000} \
            --env-file .env \
            abi-assistant-dev:latest \
            cargo run
        ;;
        
    shell)
        ensure_container
        log_info "Entering development container shell..."
        podman run -it --rm \
            -v ./:/workspace:Z \
            -w /workspace \
            abi-assistant-dev:latest \
            /bin/bash
        ;;
        
    lint)
        ensure_container
        log_info "Running clippy..."
        run_in_container cargo clippy -- -D warnings
        ;;
        
    format)
        ensure_container
        log_info "Formatting code..."
        run_in_container cargo fmt
        ;;
        
    doc)
        ensure_container
        log_info "Generating documentation..."
        run_in_container cargo doc --no-deps
        log_info "Documentation generated in target/doc"
        ;;
        
    stop)
        log_info "Stopping containers..."
        podman stop abi-assistant-dev 2>/dev/null || true
        podman stop abi-assistant-server 2>/dev/null || true
        ;;
        
    *)
        log_error "Invalid operation: $OPERATION"
        log_info "Valid operations: run, shell, lint, format, doc, stop"
        exit 1
        ;;
esac