#!/bin/bash
# Run container locally for testing

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
IMAGE_NAME="${1:-midnight-workstation}"
IMAGE_TAG="${2:-latest}"
CONTAINER_NAME="midnight-local"

# Port configuration
APP_PORT="${APP_PORT:-3000}"
PROOF_PORT="${PROOF_PORT:-8080}"
CODE_PORT="${CODE_PORT:-8443}"
TERMINAL_PORT="${TERMINAL_PORT:-7681}"

# Check if container is already running
check_running() {
    local runtime=$(detect_container_runtime)
    if [ -n "$runtime" ]; then
        if $runtime ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            return 0
        fi
    fi
    return 1
}

# Stop running container
stop_container() {
    local runtime=$(detect_container_runtime)
    if check_running; then
        log_info "Stopping existing container..."
        $runtime stop "$CONTAINER_NAME" 2>/dev/null || true
        $runtime rm "$CONTAINER_NAME" 2>/dev/null || true
    fi
}

# Run container
run_container() {
    local runtime=$(detect_container_runtime)
    
    if [ -z "$runtime" ]; then
        log_error "No container runtime found (podman or docker)"
        exit 1
    fi
    
    # Check if image exists
    if ! $runtime image exists "${IMAGE_NAME}:${IMAGE_TAG}" 2>/dev/null; then
        log_error "Image ${IMAGE_NAME}:${IMAGE_TAG} not found"
        log_info "Run 'make build' to build the container first"
        exit 1
    fi
    
    # Stop any existing container
    stop_container
    
    log_info "Starting container locally with $runtime..."
    log_info "Container: ${IMAGE_NAME}:${IMAGE_TAG}"
    log_info "Network mode: host (for better accessibility)"
    echo ""
    log_success "Access points:"
    echo "  • Service Dashboard: http://localhost:${TERMINAL_PORT}/services"
    echo "  • Web Terminal: http://localhost:${TERMINAL_PORT}"
    echo "  • OpenCode AI: http://localhost:${TERMINAL_PORT}/opencode"
    echo "  • Proof Service: http://localhost:${PROOF_PORT}"
    echo "  • DApp Server: http://localhost:${APP_PORT}"
    echo ""
    log_warn "Note: Using host network mode. Services bind directly to localhost."
    log_info "Press Ctrl+C to stop"
    echo ""
    
    # Prepare volume mount flags based on runtime
    local vol_flags=""
    if [ "$runtime" = "podman" ]; then
        # Add :Z for SELinux if on Linux with podman
        if [ "$(uname)" = "Linux" ]; then
            vol_flags=":Z"
        fi
    fi
    
    # Run container with host network mode for better accessibility
    if [ "$runtime" = "podman" ]; then
        # Podman-specific flags with host network (simplified for compatibility)
        $runtime run -it --rm \
            --name "$CONTAINER_NAME" \
            --network=host \
            -v "${SCRIPT_DIR}/../docker/templates:/workspace/templates${vol_flags}" \
            -e "MIDNIGHT_ENV=local" \
            -e "PROOF_SERVICE_URL=http://localhost:8080" \
            -e "TERMINAL_PORT=${TERMINAL_PORT}" \
            -e "APP_PORT=${APP_PORT}" \
            -e "PROOF_PORT=${PROOF_PORT}" \
            -e "CODE_PORT=${CODE_PORT}" \
            "${IMAGE_NAME}:${IMAGE_TAG}"
    else
        # Docker flags with host network
        $runtime run -it --rm \
            --name "$CONTAINER_NAME" \
            --network=host \
            -v "${SCRIPT_DIR}/../docker/templates:/workspace/templates${vol_flags}" \
            -e "MIDNIGHT_ENV=local" \
            -e "PROOF_SERVICE_URL=http://localhost:8080" \
            -e "TERMINAL_PORT=${TERMINAL_PORT}" \
            -e "APP_PORT=${APP_PORT}" \
            -e "PROOF_PORT=${PROOF_PORT}" \
            -e "CODE_PORT=${CODE_PORT}" \
            "${IMAGE_NAME}:${IMAGE_TAG}"
    fi
}

# Handle cleanup on exit
cleanup() {
    echo ""
    log_info "Shutting down..."
    stop_container
    log_success "Container stopped"
}

# Main execution
main() {
    # Set trap for cleanup
    trap cleanup EXIT INT TERM
    
    # Check for container runtime
    if [ -z "$(detect_container_runtime)" ]; then
        log_error "No container runtime found"
        log_info "Please install podman or docker"
        exit 1
    fi
    
    # Run container
    run_container
}

# Show help if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat << EOF
Run container locally for testing

Usage: $0 [IMAGE_NAME] [IMAGE_TAG]

Environment Variables:
  APP_PORT    - Local port for DApp (default: 3000)
  PROOF_PORT  - Local port for proof service (default: 8080)
  CODE_PORT   - Local port for VS Code (default: 8443)

Examples:
  # Run with defaults
  $0

  # Run specific image
  $0 my-image latest

  # Run with custom ports
  APP_PORT=3001 PROOF_PORT=8081 $0
EOF
    exit 0
fi

main "$@"