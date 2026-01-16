#!/usr/bin/env bash
# Common utilities for genai-chain-dev scripts
#
# Source this file in other scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHAINS_DIR="${REPO_ROOT}/chains"
CORE_DIR="${REPO_ROOT}/core"
TERRAFORM_DIR="${REPO_ROOT}/terraform"

# Default values
DEFAULT_REGION="${REGION:-us-central1}"
DEFAULT_TAG="${TAG:-latest}"
DEFAULT_STATE_PREFIX="${STATE_PREFIX:-terraform/state}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# =============================================================================
# Environment Loading
# =============================================================================

load_env() {
    local env_file="${REPO_ROOT}/.env"
    if [[ -f "$env_file" ]]; then
        # shellcheck disable=SC1090
        source "$env_file"
    fi
}

# =============================================================================
# Validation Functions
# =============================================================================

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
}

require_var() {
    local var_name="$1"
    if [[ -z "${!var_name:-}" ]]; then
        log_error "Required variable not set: $var_name"
        log_error "Set in .env or as environment variable"
        exit 1
    fi
}

require_chain() {
    local chain="$1"
    local chain_dir="${CHAINS_DIR}/${chain}"
    
    if [[ ! -d "$chain_dir" ]]; then
        log_error "Chain not found: $chain"
        log_error "Available chains:"
        list_chains | while read -r c; do
            log_error "  - $c"
        done
        exit 1
    fi
}

# =============================================================================
# Chain Discovery Functions
# =============================================================================

list_chains() {
    # List all chains (directories under chains/ with an Earthfile)
    for dir in "${CHAINS_DIR}"/*/; do
        if [[ -f "${dir}Earthfile" ]]; then
            basename "$dir"
        fi
    done
}

get_chain_type() {
    local chain="$1"
    local config_file="${CHAINS_DIR}/${chain}/chain.config.toml"
    
    if [[ -f "$config_file" ]]; then
        parse_toml "$config_file" "chain.type" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# =============================================================================
# TOML Parsing (uses core/build/parse-toml.ts)
# =============================================================================

parse_toml() {
    local file="$1"
    local key="$2"
    
    if [[ ! -f "$file" ]]; then
        log_error "TOML file not found: $file"
        return 1
    fi
    
    # Use the TypeScript TOML parser
    cd "${CORE_DIR}/build"
    npx ts-node parse-toml.ts "$file" "$key" 2>/dev/null
}

# Load chain configuration into environment variables
load_chain_config() {
    local chain="$1"
    local config_file="${CHAINS_DIR}/${chain}/chain.config.toml"
    
    require_chain "$chain"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Chain config not found: $config_file"
        exit 1
    fi
    
    # Parse chain.config.toml and export as environment variables
    export CHAIN_NAME=$(parse_toml "$config_file" "chain.name" || echo "$chain")
    export CLI_NAME=$(parse_toml "$config_file" "cli.name" || echo "${chain}ctl")
    
    # Network config (try testnet first, then mainnet, then first available)
    export CHAIN_ID=$(parse_toml "$config_file" "networks.testnet.chain_id" 2>/dev/null || \
                      parse_toml "$config_file" "networks.mainnet.chain_id" 2>/dev/null || echo "")
    export RPC_URL=$(parse_toml "$config_file" "networks.testnet.rpc_url" 2>/dev/null || \
                     parse_toml "$config_file" "networks.mainnet.rpc_url" 2>/dev/null || echo "")
    export EXPLORER_URL=$(parse_toml "$config_file" "networks.testnet.explorer_url" 2>/dev/null || \
                          parse_toml "$config_file" "networks.mainnet.explorer_url" 2>/dev/null || echo "")
    export FAUCET_URL=$(parse_toml "$config_file" "networks.testnet.faucet_url" 2>/dev/null || echo "")
    export NATIVE_CURRENCY=$(parse_toml "$config_file" "networks.testnet.native_currency" 2>/dev/null || \
                             parse_toml "$config_file" "networks.mainnet.native_currency" 2>/dev/null || echo "ETH")
    
    log_info "Loaded config for ${CHAIN_NAME} (${chain})"
}

# =============================================================================
# Container Runtime - Podman Only
# =============================================================================

require_podman() {
    if ! command -v podman &> /dev/null; then
        log_error "Podman is required but not installed."
        log_error "Install from: https://podman.io/getting-started/installation"
        exit 1
    fi
}

get_container_runtime() {
    require_podman
    echo "podman"
}

# =============================================================================
# GCS State Bucket
# =============================================================================

ensure_state_bucket() {
    local bucket="$1"
    local region="${2:-$DEFAULT_REGION}"
    
    require_command gsutil
    
    if gsutil ls "gs://${bucket}" &>/dev/null; then
        log_info "State bucket exists: gs://${bucket}"
        return 0
    fi
    
    log_warn "State bucket does not exist: gs://${bucket}"
    echo ""
    read -p "Create it in ${region}? [y/N] " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Creating gs://${bucket} in ${region}..."
        gsutil mb -l "${region}" "gs://${bucket}"
        
        log_info "Enabling versioning..."
        gsutil versioning set on "gs://${bucket}"
        
        log_success "State bucket created with versioning enabled"
        return 0
    else
        log_error "State bucket is required for Terraform state"
        return 1
    fi
}

# =============================================================================
# Build Functions
# =============================================================================

build_chain_image() {
    local chain="$1"
    local target="${2:-dev}"
    local chain_dir="${CHAINS_DIR}/${chain}"
    
    require_command earthly
    require_chain "$chain"
    
    log_info "Building ${chain} image (target: ${target})..."
    
    cd "$chain_dir"
    earthly "+${target}"
    
    log_success "Build complete: ${chain}"
}

push_chain_image() {
    local chain="$1"
    local project_id="$2"
    local region="${3:-$DEFAULT_REGION}"
    local tag="${4:-$DEFAULT_TAG}"
    
    require_command earthly
    require_chain "$chain"
    require_var project_id
    
    local chain_dir="${CHAINS_DIR}/${chain}"
    
    log_info "Pushing ${chain} image to ${region}-docker.pkg.dev/${project_id}/..."
    
    cd "$chain_dir"
    earthly +all \
        --REGISTRY="${region}-docker.pkg.dev" \
        --PROJECT_ID="$project_id" \
        --TAG="$tag"
    
    log_success "Push complete: ${chain}"
}

# =============================================================================
# Terraform Functions (using shared terraform/)
# =============================================================================

get_terraform_vars() {
    local chain="$1"
    local project_id="$2"
    local region="${3:-$DEFAULT_REGION}"
    local tag="${4:-$DEFAULT_TAG}"
    
    # Load chain config if not already loaded
    if [[ -z "${CHAIN_NAME:-}" ]]; then
        load_chain_config "$chain"
    fi
    
    # Build terraform variable arguments
    echo "-var=chain=${chain}"
    echo "-var=project_id=${project_id}"
    echo "-var=region=${region}"
    echo "-var=image_tag=${tag}"
    echo "-var=chain_name=${CHAIN_NAME}"
    echo "-var=cli_name=${CLI_NAME}"
    echo "-var=chain_id=${CHAIN_ID:-}"
    echo "-var=rpc_url=${RPC_URL:-}"
    echo "-var=explorer_url=${EXPLORER_URL:-}"
    echo "-var=faucet_url=${FAUCET_URL:-}"
    echo "-var=native_currency=${NATIVE_CURRENCY:-ETH}"
}

terraform_init() {
    local state_bucket="$1"
    local state_prefix="${2:-$DEFAULT_STATE_PREFIX}"
    
    require_command terraform
    
    cd "${TERRAFORM_DIR}"
    
    terraform init \
        -backend-config="bucket=${state_bucket}" \
        -backend-config="prefix=${state_prefix}" \
        -upgrade
}

terraform_apply() {
    local chain="$1"
    local project_id="$2"
    local region="${3:-$DEFAULT_REGION}"
    local tag="${4:-$DEFAULT_TAG}"
    local auto_approve="${5:-false}"
    
    require_command terraform
    require_chain "$chain"
    require_var project_id
    
    log_info "Applying Terraform for ${chain}..."
    
    cd "${TERRAFORM_DIR}"
    
    local approve_flag=""
    if [[ "$auto_approve" == "true" ]]; then
        approve_flag="-auto-approve"
    fi
    
    # shellcheck disable=SC2046
    terraform apply \
        $(get_terraform_vars "$chain" "$project_id" "$region" "$tag") \
        $approve_flag
    
    log_success "Terraform apply complete: ${chain}"
}

terraform_plan() {
    local chain="$1"
    local project_id="$2"
    local region="${3:-$DEFAULT_REGION}"
    local tag="${4:-$DEFAULT_TAG}"
    
    require_command terraform
    require_chain "$chain"
    require_var project_id
    
    log_info "Planning Terraform for ${chain}..."
    
    cd "${TERRAFORM_DIR}"
    
    # shellcheck disable=SC2046
    terraform plan \
        $(get_terraform_vars "$chain" "$project_id" "$region" "$tag")
}

terraform_destroy() {
    local chain="$1"
    local project_id="$2"
    local region="${3:-$DEFAULT_REGION}"
    local auto_approve="${4:-false}"
    
    require_command terraform
    require_chain "$chain"
    require_var project_id
    
    log_info "Destroying Terraform resources for ${chain}..."
    
    cd "${TERRAFORM_DIR}"
    
    local approve_flag=""
    if [[ "$auto_approve" == "true" ]]; then
        approve_flag="-auto-approve"
    fi
    
    # shellcheck disable=SC2046
    terraform destroy \
        $(get_terraform_vars "$chain" "$project_id" "$region") \
        $approve_flag
    
    log_success "Terraform destroy complete: ${chain}"
}

# =============================================================================
# Cloud Build Substitutions
# =============================================================================

get_cloudbuild_substitutions() {
    local chain="$1"
    local project_id="$2"
    local region="${3:-$DEFAULT_REGION}"
    local tag="${4:-$DEFAULT_TAG}"
    local state_bucket="${5:-}"
    local state_prefix="${6:-$DEFAULT_STATE_PREFIX}"
    
    # Load chain config if not already loaded
    if [[ -z "${CHAIN_NAME:-}" ]]; then
        load_chain_config "$chain"
    fi
    
    echo "_CHAIN=${chain},\
_REGION=${region},\
_TAG=${tag},\
_STATE_BUCKET=${state_bucket},\
_STATE_PREFIX=${state_prefix},\
_CHAIN_NAME=${CHAIN_NAME},\
_CLI_NAME=${CLI_NAME},\
_CHAIN_ID=${CHAIN_ID:-},\
_RPC_URL=${RPC_URL:-},\
_EXPLORER_URL=${EXPLORER_URL:-},\
_FAUCET_URL=${FAUCET_URL:-},\
_NATIVE_CURRENCY=${NATIVE_CURRENCY:-ETH}"
}

# =============================================================================
# Help Function
# =============================================================================

show_usage() {
    local script_name="$1"
    local description="$2"
    shift 2
    
    echo "Usage: $script_name $*"
    echo ""
    echo "$description"
    echo ""
}
