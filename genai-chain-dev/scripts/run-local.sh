#!/usr/bin/env bash
# Run chain development image locally
#
# Usage:
#   ./scripts/run-local.sh <chain>
#   ./scripts/run-local.sh somnia --detach
#   ./scripts/run-local.sh somnia --port 8080

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

CHAIN=""
DETACH=false
PORT="8080"
NAME=""
VOLUMES=()
EXTRA_ARGS=()

# =============================================================================
# Parse Arguments
# =============================================================================

show_help() {
    cat << EOF
Run chain development image locally

Usage:
  $(basename "$0") <chain> [options]

Arguments:
  chain                     Chain to run (e.g., somnia)

Options:
  -d, --detach              Run in background
  -p, --port=PORT           Port to expose Code Server (default: 8080)
  -n, --name=NAME           Container name (default: <chain>-dev)
  -v, --volume=SRC:DST      Mount additional volume (can be repeated)
  --shell                   Start with interactive shell instead of Code Server
  -h, --help                Show this help message

Available chains:
$(list_chains | sed 's/^/  /')

Examples:
  $(basename "$0") somnia
  $(basename "$0") somnia --detach --port 9000
  $(basename "$0") somnia --shell
  $(basename "$0") somnia -v ./my-project:/workspace/my-project
EOF
}

SHELL_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--detach)
            DETACH=true
            shift
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        --port=*)
            PORT="${1#*=}"
            shift
            ;;
        -n|--name)
            NAME="$2"
            shift 2
            ;;
        --name=*)
            NAME="${1#*=}"
            shift
            ;;
        -v|--volume)
            VOLUMES+=("$2")
            shift 2
            ;;
        --volume=*)
            VOLUMES+=("${1#*=}")
            shift
            ;;
        --shell)
            SHELL_MODE=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$CHAIN" ]]; then
                CHAIN="$1"
            else
                EXTRA_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# =============================================================================
# Validate
# =============================================================================

if [[ -z "$CHAIN" ]]; then
    log_error "Chain argument required"
    show_help
    exit 1
fi

require_chain "$CHAIN"

# Load .env file if it exists (for GOOGLE_CLOUD_PROJECT, RPC_URL overrides, etc.)
load_env 2>/dev/null || true

# =============================================================================
# Run Container
# =============================================================================

RUNTIME=$(get_container_runtime)
IMAGE_NAME="${CHAIN}-dev:latest"
CONTAINER_NAME="${NAME:-${CHAIN}-dev}"

log_info "Starting ${CHAIN} development container..."
log_info "  Runtime: ${RUNTIME}"
log_info "  Image: ${IMAGE_NAME}"
log_info "  Container: ${CONTAINER_NAME}"

# Build command arguments
CMD_ARGS=("run")

if [[ "$SHELL_MODE" == "true" ]]; then
    CMD_ARGS+=("-it" "--rm")
else
    if [[ "$DETACH" == "true" ]]; then
        # --replace removes existing container with same name before starting
        CMD_ARGS+=("-d" "--replace")
    else
        CMD_ARGS+=("-it" "--rm")
    fi
fi

CMD_ARGS+=(
    "--name" "$CONTAINER_NAME"
    "-p" "${PORT}:8080"
    "-e" "HOME=/home/user"
)

# Mount gcloud ADC credentials if available (for OpenCode Vertex AI integration)
# Mount to neutral location to avoid interfering with /home/user created at runtime
GCLOUD_CONFIG_DIR="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}"
GCLOUD_ADC_FILE="${GCLOUD_CONFIG_DIR}/application_default_credentials.json"

if [[ -f "$GCLOUD_ADC_FILE" ]]; then
    log_info "  Mounting gcloud ADC for Vertex AI"
    # Copy to temp with readable permissions so container 'user' can access it
    TEMP_ADC_FILE=$(mktemp)
    cp "$GCLOUD_ADC_FILE" "$TEMP_ADC_FILE"
    chmod 644 "$TEMP_ADC_FILE"
    # shellcheck disable=SC2064
    trap "rm -f '$TEMP_ADC_FILE'" EXIT
    
    CMD_ARGS+=("-v" "${TEMP_ADC_FILE}:/etc/gcloud-adc/application_default_credentials.json:ro")
    CMD_ARGS+=("-e" "GOOGLE_APPLICATION_CREDENTIALS=/etc/gcloud-adc/application_default_credentials.json")
    
    # Auto-detect project from gcloud config if not already set
    if [[ -z "${GOOGLE_CLOUD_PROJECT:-}" ]]; then
        DETECTED_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
        if [[ -n "$DETECTED_PROJECT" ]]; then
            log_info "  Project: ${DETECTED_PROJECT}"
            CMD_ARGS+=("-e" "GOOGLE_CLOUD_PROJECT=$DETECTED_PROJECT")
        fi
    else
        log_info "  Project: ${GOOGLE_CLOUD_PROJECT}"
        CMD_ARGS+=("-e" "GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT")
    fi
else
    log_warning "gcloud ADC not found. OpenCode Vertex AI will not work."
    log_info "  Run: gcloud auth application-default login"
fi

# Pass chain-specific environment variable overrides from .env or shell
# These override the baked-in values from /etc/chain/config.env
if [[ -n "${RPC_URL:-}" ]]; then
    log_info "  RPC_URL override: ${RPC_URL}"
    CMD_ARGS+=("-e" "RPC_URL=$RPC_URL")
fi

if [[ -n "${CHAIN_ID:-}" ]]; then
    log_info "  CHAIN_ID override: ${CHAIN_ID}"
    CMD_ARGS+=("-e" "CHAIN_ID=$CHAIN_ID")
fi

if [[ -n "${EXPLORER_URL:-}" ]]; then
    log_info "  EXPLORER_URL override: ${EXPLORER_URL}"
    CMD_ARGS+=("-e" "EXPLORER_URL=$EXPLORER_URL")
fi

if [[ -n "${FAUCET_URL:-}" ]]; then
    log_info "  FAUCET_URL override: ${FAUCET_URL}"
    CMD_ARGS+=("-e" "FAUCET_URL=$FAUCET_URL")
fi

# Add volume mounts
for vol in "${VOLUMES[@]:-}"; do
    if [[ -n "$vol" ]]; then
        CMD_ARGS+=("-v" "$vol")
    fi
done

# Mount current directory as workspace
CMD_ARGS+=("-v" "$(pwd):/workspace")
CMD_ARGS+=("-w" "/workspace")

# Add image
CMD_ARGS+=("$IMAGE_NAME")

# Add entrypoint override for shell mode
if [[ "$SHELL_MODE" == "true" ]]; then
    CMD_ARGS+=("/bin/bash")
fi

# Add any extra args
CMD_ARGS+=("${EXTRA_ARGS[@]:-}")

# Run
log_info "Command: ${RUNTIME} ${CMD_ARGS[*]}"
"$RUNTIME" "${CMD_ARGS[@]}"

if [[ "$DETACH" == "true" && "$SHELL_MODE" != "true" ]]; then
    log_success "Container started in background"
    log_info "  Access Code Server at: http://localhost:${PORT}"
    log_info "  Stop with: make stop CHAIN=${CHAIN}"
    log_info "  Logs: ${RUNTIME} logs -f ${CONTAINER_NAME}"
fi
