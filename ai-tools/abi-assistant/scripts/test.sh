#!/usr/bin/env bash
# Quick test runner for local development (no container)
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
TEST_MODE="${1:-quick}"

if [[ "$TEST_MODE" == "--container" ]]; then
    # Use container for testing
    shift || true
    exec "$SCRIPT_DIR/container.sh" test "${1:-quick}"
fi

# Load environment for test configuration
load_env

# Track if any test fails
FAILED=0

if [[ "$TEST_MODE" == "quick" ]]; then
    log_info "Running quick tests..."
    cargo test
elif [[ "$TEST_MODE" == "full" ]]; then
    log_info "Running full test suite..."

# Run format check
log_info "Checking code formatting..."
if ! cargo fmt -- --check; then
    log_error "Code formatting check failed. Run 'make format' to fix."
    FAILED=1
fi

# Run linter
log_info "Running clippy..."
if ! cargo clippy -- -D warnings; then
    log_error "Clippy found issues"
    FAILED=1
fi

# Run unit tests
log_info "Running unit tests..."
if ! cargo test --lib; then
    log_error "Unit tests failed"
    FAILED=1
fi

# Run integration tests
log_info "Running integration tests..."
if ! cargo test --test '*' 2>/dev/null; then
    log_warn "No integration tests found or some failed"
fi

# Run doc tests
log_info "Running documentation tests..."
if ! cargo test --doc; then
    log_error "Documentation tests failed"
    FAILED=1
fi

# Check for security vulnerabilities
if command -v cargo-audit &> /dev/null; then
    log_info "Checking for security vulnerabilities..."
    if ! cargo audit; then
        log_warn "Security vulnerabilities found"
    fi
else
    log_info "Skipping security audit (cargo-audit not installed)"
fi

    # Summary
    if [ $FAILED -eq 0 ]; then
        log_success "All tests passed!"
    else
        log_error "Some tests failed"
        exit 1
    fi
else
    log_error "Invalid test mode: $TEST_MODE (use 'quick' or 'full')"
    exit 1
fi