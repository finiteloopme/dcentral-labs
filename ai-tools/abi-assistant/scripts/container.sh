#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/common.sh"

# Default values
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
COMMAND="${1:-help}"
shift || true

# Container names
DEV_IMAGE="abi-assistant-dev:latest"
PROD_IMAGE="abi-assistant:latest"
DEV_CONTAINER="abi-assistant-dev"
PROD_CONTAINER="abi-assistant-prod"

# Help message
show_help() {
    cat << EOF
Container Management Script

Usage: $0 <command> [options]

Commands:
    build [dev|prod]     Build container image (default: dev)
    run [dev|prod]       Run container (default: dev)
    shell                Enter dev container shell
    test [quick|full]    Run tests in container (default: quick)
    coverage             Run tests with coverage report
    lint                 Run linter in container
    format               Format code in container
    clean                Clean containers and build artifacts
    stop                 Stop all running containers
    setup                Initial setup and build
    help                 Show this help message

Environment Variables:
    CONTAINER_RUNTIME    Container runtime to use (default: podman)

Examples:
    $0 build prod        # Build production image
    $0 run dev          # Run development server
    $0 test full        # Run full test suite
    $0 shell            # Enter container shell
EOF
}

# Build container image
build() {
    local build_type="${1:-dev}"
    
    case "$build_type" in
        dev)
            log_info "Building development container..."
            $CONTAINER_RUNTIME build -f "$PROJECT_ROOT/oci/Dockerfile.dev" -t "$DEV_IMAGE" "$PROJECT_ROOT"
            ;;
        prod|release)
            log_info "Building production container..."
            $CONTAINER_RUNTIME build -f "$PROJECT_ROOT/oci/Dockerfile" -t "$PROD_IMAGE" "$PROJECT_ROOT"
            ;;
        *)
            log_error "Invalid build type: $build_type (use 'dev' or 'prod')"
            exit 1
            ;;
    esac
    
    log_success "Build complete!"
}

# Run container
run() {
    local run_type="${1:-dev}"
    
    case "$run_type" in
        dev)
            log_info "Starting development container..."
            
            # Stop existing container if running
            $CONTAINER_RUNTIME stop "$DEV_CONTAINER" 2>/dev/null || true
            $CONTAINER_RUNTIME rm "$DEV_CONTAINER" 2>/dev/null || true
            
            # Ensure image exists
            if ! $CONTAINER_RUNTIME image exists "$DEV_IMAGE"; then
                build dev
            fi
            
            # Run development container
            $CONTAINER_RUNTIME run -d \
                --name "$DEV_CONTAINER" \
                -p 3000:3000 \
                -v "$PROJECT_ROOT:/workspace:Z" \
                -v cargo-cache:/usr/local/cargo/registry \
                -e RUST_LOG=debug \
                "$DEV_IMAGE" \
                cargo watch -x 'run' -w src/
            
            log_success "Development container started!"
            log_info "View logs: $CONTAINER_RUNTIME logs -f $DEV_CONTAINER"
            ;;
            
        prod|release)
            log_info "Starting production container..."
            
            # Stop existing container if running
            $CONTAINER_RUNTIME stop "$PROD_CONTAINER" 2>/dev/null || true
            $CONTAINER_RUNTIME rm "$PROD_CONTAINER" 2>/dev/null || true
            
            # Ensure image exists
            if ! $CONTAINER_RUNTIME image exists "$PROD_IMAGE"; then
                build prod
            fi
            
            # Run production container
            $CONTAINER_RUNTIME run -d \
                --name "$PROD_CONTAINER" \
                -p 3000:3000 \
                -v "$PROJECT_ROOT/data:/data:Z" \
                -v "$PROJECT_ROOT/logs:/logs:Z" \
                -e RUST_LOG=info \
                "$PROD_IMAGE"
            
            log_success "Production container started!"
            log_info "View logs: $CONTAINER_RUNTIME logs -f $PROD_CONTAINER"
            ;;
            
        *)
            log_error "Invalid run type: $run_type (use 'dev' or 'prod')"
            exit 1
            ;;
    esac
}

# Enter container shell
shell() {
    # Ensure dev container is running
    if ! $CONTAINER_RUNTIME ps --format "{{.Names}}" | grep -q "^${DEV_CONTAINER}$"; then
        log_info "Starting dev container..."
        run dev
    fi
    
    log_info "Entering container shell..."
    $CONTAINER_RUNTIME exec -it "$DEV_CONTAINER" /bin/bash
}

# Run tests in container
test() {
    local test_mode="${1:-quick}"
    
    # Ensure dev image exists
    if ! $CONTAINER_RUNTIME image exists "$DEV_IMAGE"; then
        build dev
    fi
    
    case "$test_mode" in
        quick)
            log_info "Running quick tests..."
            $CONTAINER_RUNTIME run --rm \
                -v "$PROJECT_ROOT:/workspace:Z" \
                -v cargo-cache:/usr/local/cargo/registry \
                "$DEV_IMAGE" \
                cargo test
            ;;
            
        full)
            log_info "Running full test suite..."
            $CONTAINER_RUNTIME run --rm \
                -v "$PROJECT_ROOT:/workspace:Z" \
                -v cargo-cache:/usr/local/cargo/registry \
                "$DEV_IMAGE" \
                bash -c "cargo fmt --check && cargo clippy -- -D warnings && cargo test"
            ;;
            
        *)
            log_error "Invalid test mode: $test_mode (use 'quick' or 'full')"
            exit 1
            ;;
    esac
    
    log_success "Tests complete!"
}

# Run tests with coverage
coverage() {
    log_info "Running tests with coverage..."
    
    # Ensure dev image exists
    if ! $CONTAINER_RUNTIME image exists "$DEV_IMAGE"; then
        build dev
    fi
    
    $CONTAINER_RUNTIME run --rm \
        -v "$PROJECT_ROOT:/workspace:Z" \
        -v cargo-cache:/usr/local/cargo/registry \
        "$DEV_IMAGE" \
        bash -c "cargo install cargo-tarpaulin && cargo tarpaulin --out Html --output-dir coverage"
    
    log_success "Coverage report generated in coverage/tarpaulin-report.html"
}

# Run linter
lint() {
    log_info "Running linter..."
    
    # Ensure dev image exists
    if ! $CONTAINER_RUNTIME image exists "$DEV_IMAGE"; then
        build dev
    fi
    
    $CONTAINER_RUNTIME run --rm \
        -v "$PROJECT_ROOT:/workspace:Z" \
        -v cargo-cache:/usr/local/cargo/registry \
        "$DEV_IMAGE" \
        cargo clippy -- -D warnings
    
    log_success "Linting complete!"
}

# Format code
format() {
    log_info "Formatting code..."
    
    # Ensure dev image exists
    if ! $CONTAINER_RUNTIME image exists "$DEV_IMAGE"; then
        build dev
    fi
    
    $CONTAINER_RUNTIME run --rm \
        -v "$PROJECT_ROOT:/workspace:Z" \
        -v cargo-cache:/usr/local/cargo/registry \
        "$DEV_IMAGE" \
        cargo fmt
    
    log_success "Formatting complete!"
}

# Clean containers and artifacts
clean() {
    log_info "Cleaning containers and artifacts..."
    
    # Stop and remove containers
    $CONTAINER_RUNTIME stop "$DEV_CONTAINER" 2>/dev/null || true
    $CONTAINER_RUNTIME stop "$PROD_CONTAINER" 2>/dev/null || true
    $CONTAINER_RUNTIME rm "$DEV_CONTAINER" 2>/dev/null || true
    $CONTAINER_RUNTIME rm "$PROD_CONTAINER" 2>/dev/null || true
    
    # Remove images if requested
    if [[ "${1:-}" == "--all" ]]; then
        log_info "Removing container images..."
        $CONTAINER_RUNTIME rmi "$DEV_IMAGE" 2>/dev/null || true
        $CONTAINER_RUNTIME rmi "$PROD_IMAGE" 2>/dev/null || true
    fi
    
    # Clean build artifacts
    rm -rf "$PROJECT_ROOT/target"
    rm -rf "$PROJECT_ROOT/coverage"
    rm -rf "$PROJECT_ROOT/logs"
    
    log_success "Cleanup complete!"
}

# Stop all containers
stop() {
    log_info "Stopping all containers..."
    
    $CONTAINER_RUNTIME stop "$DEV_CONTAINER" 2>/dev/null || true
    $CONTAINER_RUNTIME stop "$PROD_CONTAINER" 2>/dev/null || true
    
    log_success "All containers stopped!"
}

# Initial setup
setup() {
    log_info "Setting up development environment..."
    
    # Check prerequisites
    if ! command -v "$CONTAINER_RUNTIME" &> /dev/null; then
        log_error "$CONTAINER_RUNTIME not found. Please install $CONTAINER_RUNTIME first."
        exit 1
    fi
    
    # Build development image
    build dev
    
    # Create necessary directories
    mkdir -p "$PROJECT_ROOT/data"
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/coverage"
    
    # Initialize database
    "$SCRIPT_DIR/db-setup.sh"
    
    log_success "Setup complete! Run '$0 run dev' to start the development server."
}

# Main command dispatcher
case "$COMMAND" in
    build)
        build "$@"
        ;;
    run)
        run "$@"
        ;;
    shell)
        shell
        ;;
    test)
        test "$@"
        ;;
    coverage)
        coverage
        ;;
    lint)
        lint
        ;;
    format)
        format
        ;;
    clean)
        clean "$@"
        ;;
    stop)
        stop
        ;;
    setup)
        setup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac