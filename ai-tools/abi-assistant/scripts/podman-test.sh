#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

# Test mode: quick or full
TEST_MODE=${1:-quick}

# Ensure dev container exists
if ! podman image exists abi-assistant-dev:latest; then
    log_info "Building development container..."
    "$SCRIPT_DIR/podman-build.sh" dev
fi

# Common podman run command
run_test() {
    podman run --rm \
        -v ./:/workspace:Z \
        -w /workspace \
        abi-assistant-dev:latest \
        "$@"
}

case "$TEST_MODE" in
    quick)
        log_info "Running quick tests..."
        run_test cargo test --lib
        ;;
        
    full)
        log_info "Running full test suite..."
        
        # Format check
        log_info "Checking code formatting..."
        if ! run_test cargo fmt -- --check; then
            log_error "Code needs formatting. Run 'make format'"
            exit 1
        fi
        
        # Lint
        log_info "Running clippy..."
        run_test cargo clippy -- -D warnings || true
        
        # Unit tests
        log_info "Running unit tests..."
        run_test cargo test --lib
        
        # Doc tests
        log_info "Running doc tests..."
        run_test cargo test --doc
        
        log_info "✅ All tests passed!"
        ;;
        
    *)
        log_error "Invalid test mode: $TEST_MODE (use 'quick' or 'full')"
        exit 1
        ;;
esac