#!/usr/bin/env bash
#
# Cloud deployment script for genai-chain-dev
#
# Usage:
#   ./scripts/cloud.sh <chain> deploy    # Build image and deploy infrastructure
#   ./scripts/cloud.sh <chain> build     # Build and push image only
#   ./scripts/cloud.sh <chain> plan      # Preview Terraform changes
#   ./scripts/cloud.sh <chain> destroy   # Destroy infrastructure
#   ./scripts/cloud.sh <chain> check     # Validate configuration
#
# Examples:
#   ./scripts/cloud.sh somnia check
#   ./scripts/cloud.sh somnia deploy
#   ./scripts/cloud.sh polygon build

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Load environment
load_env

# =============================================================================
# Configuration
# =============================================================================

# Required (from .env or environment)
PROJECT_ID="${PROJECT_ID:-}"
STATE_BUCKET="${STATE_BUCKET:-}"
CLOUDBUILD_SA_EMAIL="${CLOUDBUILD_SA_EMAIL:-}"

# Optional with defaults
REGION="${REGION:-us-central1}"
TAG="${TAG:-latest}"
STATE_PREFIX="${STATE_PREFIX:-terraform/state}"

# Chain (set from first argument)
CHAIN=""

# =============================================================================
# Commands
# =============================================================================

cmd_check() {
    log_info "Checking cloud deployment configuration..."
    
    local errors=0
    
    # Check required variables
    if [[ -z "$PROJECT_ID" ]]; then
        log_error "PROJECT_ID is required. Set in .env or environment"
        errors=$((errors + 1))
    fi
    
    if [[ -z "$STATE_BUCKET" ]]; then
        log_error "STATE_BUCKET is required. Set in .env or environment"
        errors=$((errors + 1))
    fi
    
    if [[ -z "$CLOUDBUILD_SA_EMAIL" ]]; then
        log_error "CLOUDBUILD_SA_EMAIL is required. Set in .env or environment"
        log_error "Example: chain-dev-cloudbuild-sa@your-project.iam.gserviceaccount.com"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo ""
        log_error "Fix the above errors and try again"
        log_error "See .env.example for configuration template"
        exit 1
    fi
    
    # Validate chain
    require_chain "$CHAIN"
    
    # Load chain config
    load_chain_config "$CHAIN"
    
    # Check gcloud access
    require_command gcloud
    
    if ! gcloud projects describe "$PROJECT_ID" &>/dev/null; then
        log_error "Cannot access project: $PROJECT_ID"
        log_error "Run: gcloud auth login"
        exit 1
    fi
    
    # Check/create state bucket
    require_command gsutil
    ensure_state_bucket "$STATE_BUCKET" "$REGION" || exit 1
    
    # Show configuration
    echo ""
    echo "Configuration:"
    echo "  PROJECT_ID:          ${PROJECT_ID}"
    echo "  STATE_BUCKET:        ${STATE_BUCKET}"
    echo "  STATE_PREFIX:        ${STATE_PREFIX}"
    echo "  REGION:              ${REGION}"
    echo "  CLOUDBUILD_SA_EMAIL: ${CLOUDBUILD_SA_EMAIL}"
    echo ""
    echo "Chain:"
    echo "  CHAIN:               ${CHAIN}"
    echo "  CHAIN_NAME:          ${CHAIN_NAME}"
    echo "  CLI_NAME:            ${CLI_NAME}"
    echo "  CHAIN_ID:            ${CHAIN_ID:-<not set>}"
    echo "  RPC_URL:             ${RPC_URL:-<not set>}"
    echo ""
    
    log_success "Configuration OK"
}

cmd_build() {
    cmd_check
    
    echo ""
    log_info "Building ${CHAIN} container image in Cloud Build..."
    echo ""
    
    local substitutions
    substitutions=$(get_cloudbuild_substitutions "$CHAIN" "$PROJECT_ID" "$REGION" "$TAG" "$STATE_BUCKET" "$STATE_PREFIX")
    
    gcloud builds submit \
        --config="${REPO_ROOT}/cloudbuild.yaml" \
        --substitutions="${substitutions}" \
        --service-account="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA_EMAIL}" \
        --project="$PROJECT_ID" \
        "$REPO_ROOT"
    
    log_success "Build complete"
}

cmd_deploy() {
    cmd_check
    
    echo ""
    log_info "Deploying ${CHAIN} to GCP..."
    echo ""
    
    local substitutions
    substitutions=$(get_cloudbuild_substitutions "$CHAIN" "$PROJECT_ID" "$REGION" "$TAG" "$STATE_BUCKET" "$STATE_PREFIX")
    
    gcloud builds submit \
        --config="${REPO_ROOT}/cloudbuild.yaml" \
        --substitutions="${substitutions}" \
        --service-account="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA_EMAIL}" \
        --project="$PROJECT_ID" \
        "$REPO_ROOT"
    
    log_success "Deployment complete"
}

cmd_plan() {
    cmd_check
    
    echo ""
    log_info "Planning deployment for ${CHAIN} (dry run)..."
    echo ""
    
    local substitutions
    substitutions=$(get_cloudbuild_substitutions "$CHAIN" "$PROJECT_ID" "$REGION" "$TAG" "$STATE_BUCKET" "$STATE_PREFIX")
    
    gcloud builds submit \
        --config="${REPO_ROOT}/cloudbuild-plan.yaml" \
        --substitutions="${substitutions}" \
        --service-account="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA_EMAIL}" \
        --project="$PROJECT_ID" \
        "$REPO_ROOT"
}

cmd_destroy() {
    cmd_check
    
    echo ""
    echo "WARNING: This will destroy all ${CHAIN} cloud infrastructure!"
    echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
    sleep 10
    
    local substitutions
    substitutions=$(get_cloudbuild_substitutions "$CHAIN" "$PROJECT_ID" "$REGION" "$TAG" "$STATE_BUCKET" "$STATE_PREFIX")
    
    gcloud builds submit \
        --config="${REPO_ROOT}/cloudbuild-destroy.yaml" \
        --substitutions="${substitutions}" \
        --service-account="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA_EMAIL}" \
        --project="$PROJECT_ID" \
        "$REPO_ROOT"
    
    log_success "Infrastructure destroyed"
}

cmd_help() {
    cat <<EOF
genai-chain-dev Cloud Deployment Script

Usage: $(basename "$0") <chain> <command>

Arguments:
    chain               Chain to operate on (e.g., somnia, polygon)

Commands:
    check               Validate configuration and create state bucket if needed
    build               Build and push container image via Cloud Build
    deploy              Build image and deploy infrastructure (full deployment)
    plan                Preview Terraform changes without applying
    destroy             Destroy all cloud infrastructure

Configuration:
    Set these in .env or as environment variables:
    
    Required:
      PROJECT_ID              GCP project ID
      STATE_BUCKET            GCS bucket for Terraform state
      CLOUDBUILD_SA_EMAIL     Cloud Build service account email
    
    Optional:
      REGION                  GCP region (default: us-central1)
      TAG                     Container image tag (default: latest)
      STATE_PREFIX            Terraform state prefix (default: terraform/state)

Available chains:
$(list_chains | sed 's/^/    /')

Examples:
    $(basename "$0") somnia check           # Validate configuration
    $(basename "$0") somnia deploy          # Full deployment
    $(basename "$0") somnia plan            # Preview changes
    $(basename "$0") polygon build          # Build image only
    $(basename "$0") somnia destroy         # Tear down infrastructure
EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    local chain="${1:-}"
    local command="${2:-help}"
    
    # Handle help
    if [[ -z "$chain" || "$chain" == "help" || "$chain" == "-h" || "$chain" == "--help" ]]; then
        cmd_help
        exit 0
    fi
    
    CHAIN="$chain"
    
    case "$command" in
        check)   cmd_check ;;
        build)   cmd_build ;;
        deploy)  cmd_deploy ;;
        plan)    cmd_plan ;;
        destroy) cmd_destroy ;;
        help|-h|--help) cmd_help ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
