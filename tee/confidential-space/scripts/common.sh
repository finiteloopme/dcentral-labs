#!/usr/bin/env bash
#
# common.sh - Configuration loader for Confidential Space project.
# Parses config.toml via yq, then overlays values from .env if present.
#
# Usage: source this file from other scripts.
#   source "$(dirname "$0")/common.sh"
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config.toml"
ENV_FILE="$PROJECT_ROOT/.env"

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No colour

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------------------------------------------------------------------------
# Ensure go-yq (mikefarah/yq v4+) is available
# ---------------------------------------------------------------------------
require_yq() {
    # Prepend the install location used by setup.sh so it takes
    # precedence over any system-packaged yq (e.g. Python yq v3).
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v yq &>/dev/null; then
        log_error "yq is not installed. Run 'make setup' first."
        exit 1
    fi

    # Validate it is go-yq (mikefarah) which supports TOML, not the
    # older Python-based yq that only handles YAML.
    if ! yq --version 2>/dev/null | grep -q "mikefarah"; then
        log_error "Found $(command -v yq) but it is not go-yq (mikefarah/yq v4+)."
        log_error "Installed: $(yq --version 2>&1)"
        log_error "Run 'make setup' to install the correct version to ~/.local/bin."
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Load configuration: config.toml -> env vars -> .env overrides
# ---------------------------------------------------------------------------
load_config() {
    require_yq

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file not found: $CONFIG_FILE"
        exit 1
    fi

    # Parse config.toml into flat KEY=VALUE pairs.
    # yq with -p toml -o props produces lines like:
    #   gcp.project_id = kunal-scratch
    # We transform "section.key" -> "SECTION_KEY" and export.
    #
    # Precedence (highest wins): inline env vars > .env file > config.toml
    # We only set a variable here if it is not already in the environment,
    # so that inline overrides (e.g. DEPLOY_ENVIRONMENT=prod make deploy-prod)
    # are preserved.
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        local key value
        key="$(echo "$line" | cut -d'=' -f1 | xargs)"
        value="$(echo "$line" | cut -d'=' -f2- | xargs)"

        # Transform dotted key to uppercased underscore form:
        #   gcp.project_id -> GCP_PROJECT_ID
        local env_key
        env_key="$(echo "$key" | tr '.' '_' | tr '[:lower:]' '[:upper:]')"

        # Only set if not already present in the environment
        if [[ -z "${!env_key+x}" ]]; then
            export "$env_key=$value"
        fi
    done < <(yq -p toml -o props "$CONFIG_FILE")

    # Guard: verify parsing produced at least the core variables.
    if [[ -z "${GCP_PROJECT_ID:-}" ]]; then
        log_error "Failed to parse config.toml — no variables were loaded."
        log_error "Check that $CONFIG_FILE is valid TOML and yq can read it."
        exit 1
    fi

    # Overlay with .env file if it exists (values there win).
    if [[ -f "$ENV_FILE" ]]; then
        log_info "Loading overrides from .env"
        set -a
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        set +a
    fi

    # Also allow inline env-var overrides (e.g. DEPLOY_ENVIRONMENT=prod make deploy-prod).
    # Those are already in the environment and take precedence over both files.

    # ---------------------------------------------------------------------------
    # Derived / computed values
    # ---------------------------------------------------------------------------
    export DEPLOY_ENVIRONMENT="${DEPLOY_ENVIRONMENT:-debug}"

    # Confidential Space image family
    if [[ "$DEPLOY_ENVIRONMENT" == "prod" ]]; then
        export CS_IMAGE_FAMILY="confidential-space"
    else
        export CS_IMAGE_FAMILY="confidential-space-debug"
    fi

    # Full Docker image URI
    export DOCKER_IMAGE_URI="${DOCKER_REGISTRY}/${GCP_PROJECT_ID}/${DOCKER_REPOSITORY}/${APP_NAME}:latest"

    # Terraform state bucket
    export TF_STATE_BUCKET="${GCP_PROJECT_ID}-cs-tf-state"

    # Cloud Build service account (full email)
    export CB_SA_EMAIL="${CLOUDBUILD_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

    log_info "Config loaded: project=${GCP_PROJECT_ID} env=${DEPLOY_ENVIRONMENT} image_family=${CS_IMAGE_FAMILY}"
}

# ---------------------------------------------------------------------------
# Print current configuration (for debugging)
# ---------------------------------------------------------------------------
print_config() {
    echo "──────────────────────────────────────────"
    echo "  GCP_PROJECT_ID        = ${GCP_PROJECT_ID:-}"
    echo "  GCP_REGION            = ${GCP_REGION:-}"
    echo "  GCP_ZONE              = ${GCP_ZONE:-}"
    echo "  APP_NAME              = ${APP_NAME:-}"
    echo "  APP_PORT              = ${APP_PORT:-}"
    echo "  COMPUTE_MACHINE_TYPE  = ${COMPUTE_MACHINE_TYPE:-}"
    echo "  COMPUTE_CONFIDENTIAL_TYPE = ${COMPUTE_CONFIDENTIAL_TYPE:-}"
    echo "  COMPUTE_MIG_MIN_REPLICAS  = ${COMPUTE_MIG_MIN_REPLICAS:-}"
    echo "  COMPUTE_MIG_MAX_REPLICAS  = ${COMPUTE_MIG_MAX_REPLICAS:-}"
    echo "  DOCKER_IMAGE_URI      = ${DOCKER_IMAGE_URI:-}"
    echo "  DEPLOY_ENVIRONMENT    = ${DEPLOY_ENVIRONMENT:-}"
    echo "  CS_IMAGE_FAMILY       = ${CS_IMAGE_FAMILY:-}"
    echo "  TF_STATE_BUCKET       = ${TF_STATE_BUCKET:-}"
    echo "  CB_SA_EMAIL           = ${CB_SA_EMAIL:-}"
    echo "──────────────────────────────────────────"
}

# Auto-load config when sourced (unless SKIP_CONFIG_LOAD is set).
if [[ -z "${SKIP_CONFIG_LOAD:-}" ]]; then
    load_config
fi
