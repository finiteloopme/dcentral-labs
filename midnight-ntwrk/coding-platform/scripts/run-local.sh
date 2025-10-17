#!/bin/bash
# Run container locally for testing

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Load environment variables from .env file if it exists
if [ -f "${SCRIPT_DIR}/../.env" ]; then
    log_info "Loading configuration from .env file"
    set -a
    source "${SCRIPT_DIR}/../.env"
    set +a
fi

# Configuration
IMAGE_NAME="${1:-${IMAGE_NAME:-midnight-workstation}}"
IMAGE_TAG="${2:-${IMAGE_TAG:-latest}}"
CONTAINER_NAME="${CONTAINER_NAME:-midnight-local}"

# Port configuration
APP_PORT="${APP_PORT:-3000}"
PROOF_PORT="${PROOF_PORT:-8080}"
CODE_PORT="${CODE_PORT:-8443}"
TERMINAL_PORT="${TERMINAL_PORT:-7681}"

# External services
PROOF_SERVICE_URL="${PROOF_SERVICE_URL:-}"

# Google Cloud configuration
GCP_PROJECT_ID="${GCP_PROJECT_ID:-${PROJECT_ID:-}}"
MOUNT_GCLOUD_CREDS="${MOUNT_GCLOUD_CREDS:-true}"

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

# Prepare Google Cloud credential mounts
prepare_gcloud_mounts() {
    local mounts=""
    local vol_flags="$1"
    
    # Combine mount options properly (ro and Z need to be comma-separated)
    local mount_opts="ro"
    if [ -n "$vol_flags" ]; then
        # Remove leading colon from vol_flags if present
        vol_flags="${vol_flags#:}"
        if [ -n "$vol_flags" ]; then
            mount_opts="${mount_opts},${vol_flags}"
        fi
    fi
    
    if [ "$MOUNT_GCLOUD_CREDS" = "true" ]; then
        # Check for gcloud config directory
        if [ -d "$HOME/.config/gcloud" ]; then
            # Log to stderr so it doesn't get captured in the return value
            >&2 log_info "Found gcloud configuration, mounting credentials"
            mounts="${mounts} -v ${HOME}/.config/gcloud:/root/.config/gcloud:${mount_opts}"
            
            # Check for active account
            if command -v gcloud &>/dev/null; then
                local active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || true)
                if [ -n "$active_account" ]; then
                    >&2 log_info "Active GCP account: $active_account"
                fi
            fi
        else
            >&2 log_warn "No gcloud configuration found at ~/.config/gcloud"
            >&2 log_info "To use Vertex AI, run: gcloud auth login"
        fi
        
        # Also mount application default credentials if they exist
        if [ -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
            >&2 log_info "Found application default credentials"
        elif [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
            >&2 log_info "Using GOOGLE_APPLICATION_CREDENTIALS from: $GOOGLE_APPLICATION_CREDENTIALS"
            mounts="${mounts} -v ${GOOGLE_APPLICATION_CREDENTIALS}:/tmp/gcp-key.json:${mount_opts}"
            mounts="${mounts} -e GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-key.json"
        fi
    fi
    
    # Return only the mount arguments, no colored output
    echo "$mounts"
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
        # Add Z for SELinux if on Linux with podman (without colon, we'll add it later)
        if [ "$(uname)" = "Linux" ]; then
            vol_flags="Z"
        fi
    fi
    
    # Get gcloud credential mounts
    local gcloud_mounts=$(prepare_gcloud_mounts "$vol_flags")
    
    # Build the run command as an array to avoid eval issues
    local -a run_cmd=()
    run_cmd+=("$runtime" "run" "-it" "--rm")
    run_cmd+=("--name" "$CONTAINER_NAME")
    run_cmd+=("--network=host")
    
    # Add templates mount with proper flags
    local template_mount_opts=""
    if [ -n "$vol_flags" ]; then
        template_mount_opts=":${vol_flags}"
    fi
    run_cmd+=("-v" "${SCRIPT_DIR}/../docker/templates:/workspace/templates${template_mount_opts}")
    
    # Add gcloud mounts if available (parse the mount string)
    if [ -n "$gcloud_mounts" ]; then
        # Split the gcloud_mounts string into array elements
        while read -r mount_arg; do
            if [ -n "$mount_arg" ]; then
                run_cmd+=($mount_arg)
            fi
        done < <(echo "$gcloud_mounts" | xargs -n1)
    fi
    
    # Add environment variables
    run_cmd+=("-e" "MIDNIGHT_ENV=local")
    run_cmd+=("-e" "PROOF_SERVICE_URL=${PROOF_SERVICE_URL:-}")
    run_cmd+=("-e" "TERMINAL_PORT=${TERMINAL_PORT}")
    run_cmd+=("-e" "APP_PORT=${APP_PORT}")
    run_cmd+=("-e" "PROOF_PORT=${PROOF_PORT}")
    run_cmd+=("-e" "CODE_PORT=${CODE_PORT}")
    run_cmd+=("-e" "GCP_PROJECT_ID=${GCP_PROJECT_ID:-}")
    
    # Add the image
    run_cmd+=("${IMAGE_NAME}:${IMAGE_TAG}")
    
    # Execute the command (using array expansion for safety)
    "${run_cmd[@]}"
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
  APP_PORT           - Local port for DApp (default: 3000)
  PROOF_PORT         - Local port for proof service (default: 8080)
  CODE_PORT          - Local port for VS Code (default: 8443)
  TERMINAL_PORT      - Local port for web terminal (default: 7681)
  PROOF_SERVICE_URL  - External proof service URL (optional, uses local mock if not set)
  GCP_PROJECT_ID     - Google Cloud project ID for Vertex AI
  MOUNT_GCLOUD_CREDS - Mount local gcloud credentials (default: true)
  GOOGLE_APPLICATION_CREDENTIALS - Path to service account key (optional)

Examples:
  # Run with defaults (auto-mounts gcloud credentials)
  $0

  # Run specific image
  $0 my-image latest

  # Run with custom ports
  APP_PORT=3001 PROOF_PORT=8081 $0
  
  # Use external proof service
  PROOF_SERVICE_URL=https://proof-api.midnight.network $0
  
  # Run with GCP project for Vertex AI
  GCP_PROJECT_ID=my-project $0
  
  # Run without mounting gcloud credentials
  MOUNT_GCLOUD_CREDS=false $0
  
  # Use service account key
  GOOGLE_APPLICATION_CREDENTIALS=~/keys/gcp-key.json $0
EOF
    exit 0
fi

main "$@"