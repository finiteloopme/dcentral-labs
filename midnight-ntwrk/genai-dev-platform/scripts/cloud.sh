#!/bin/bash
#
# Cloud deployment script for GCP
#
# Usage:
#   ./scripts/cloud.sh deploy    # Deploy all infrastructure
#   ./scripts/cloud.sh plan      # Preview changes
#   ./scripts/cloud.sh destroy   # Destroy infrastructure
#   ./scripts/cloud.sh check     # Validate configuration
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."

# Load environment
if [[ -f "${PROJECT_DIR}/.env" ]]; then
    # shellcheck source=/dev/null
    source "${PROJECT_DIR}/.env"
fi

# ==============================================================================
# Configuration
# ==============================================================================

# Required
PROJECT_ID="${PROJECT_ID:-}"
STATE_BUCKET="${STATE_BUCKET:-}"

# Optional with defaults
REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-midnight-dev}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
IMAGE_NAME="${IMAGE_NAME:-midnight-dev-platform}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
MIN_INSTANCES="${MIN_INSTANCES:-1}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-4}"
PERSISTENT_DISK_SIZE_GB="${PERSISTENT_DISK_SIZE_GB:-100}"
MIDNIGHT_NODE_IMAGE="${MIDNIGHT_NODE_IMAGE:-midnightntwrk/midnight-node:latest-main}"
PROOF_SERVER_IMAGE="${PROOF_SERVER_IMAGE:-midnightnetwork/proof-server:latest}"
INDEXER_IMAGE="${INDEXER_IMAGE:-midnightntwrk/indexer-standalone:latest}"

# ==============================================================================
# Helpers
# ==============================================================================

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1" >&2; }
log_success() { echo "[OK] $1"; }

get_substitutions() {
    echo "_PROJECT_ID=${PROJECT_ID},\
_STATE_BUCKET=${STATE_BUCKET},\
_REGION=${REGION},\
_CLUSTER_NAME=${CLUSTER_NAME},\
_ENVIRONMENT=${ENVIRONMENT},\
_IMAGE_NAME=${IMAGE_NAME},\
_IMAGE_TAG=${IMAGE_TAG},\
_MIN_INSTANCES=${MIN_INSTANCES},\
_MACHINE_TYPE=${MACHINE_TYPE},\
_PERSISTENT_DISK_SIZE_GB=${PERSISTENT_DISK_SIZE_GB},\
_MIDNIGHT_NODE_IMAGE=${MIDNIGHT_NODE_IMAGE},\
_PROOF_SERVER_IMAGE=${PROOF_SERVER_IMAGE},\
_INDEXER_IMAGE=${INDEXER_IMAGE}"
}

# ==============================================================================
# Commands
# ==============================================================================

cmd_check() {
    log_info "Checking cloud deployment configuration..."
    
    local errors=0
    
    if [[ -z "$PROJECT_ID" ]]; then
        log_error "PROJECT_ID is required. Set in .env or environment"
        errors=$((errors + 1))
    fi
    
    if [[ -z "$STATE_BUCKET" ]]; then
        log_error "STATE_BUCKET is required. Set in .env or environment"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        exit 1
    fi
    
    echo ""
    echo "Configuration:"
    echo "  PROJECT_ID:    ${PROJECT_ID}"
    echo "  STATE_BUCKET:  ${STATE_BUCKET}"
    echo "  REGION:        ${REGION}"
    echo "  CLUSTER_NAME:  ${CLUSTER_NAME}"
    echo ""
    
    # Validate access
    if ! gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
        log_error "Cannot access project: $PROJECT_ID"
        exit 1
    fi
    
    if ! gsutil ls "gs://${STATE_BUCKET}" > /dev/null 2>&1; then
        log_error "Cannot access bucket: $STATE_BUCKET"
        exit 1
    fi
    
    log_success "Configuration OK"
}

cmd_deploy() {
    cmd_check
    
    echo ""
    log_info "Deploying Midnight Development Platform to GCP..."
    echo ""
    
    gcloud builds submit \
        --config="${PROJECT_DIR}/cicd-pipelines/cloudbuild.yaml" \
        --substitutions="$(get_substitutions)" \
        --project="$PROJECT_ID" \
        "$PROJECT_DIR"
}

cmd_plan() {
    cmd_check
    
    echo ""
    log_info "Planning deployment (dry run)..."
    echo ""
    
    gcloud builds submit \
        --config="${PROJECT_DIR}/cicd-pipelines/cloudbuild-plan.yaml" \
        --substitutions="$(get_substitutions)" \
        --project="$PROJECT_ID" \
        "$PROJECT_DIR"
}

cmd_destroy() {
    cmd_check
    
    echo ""
    echo "WARNING: This will destroy all cloud infrastructure!"
    echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
    sleep 10
    
    gcloud builds submit \
        --config="${PROJECT_DIR}/cicd-pipelines/cloudbuild-destroy.yaml" \
        --substitutions="$(get_substitutions)" \
        --project="$PROJECT_ID" \
        "$PROJECT_DIR"
}

cmd_help() {
    cat <<EOF
Midnight Cloud Deployment Script

Usage: $(basename "$0") <command>

Commands:
    deploy    Build container and deploy all infrastructure
    plan      Preview deployment changes (Terraform plan)
    destroy   Destroy all cloud infrastructure
    check     Validate configuration

Configuration:
    Set these in .env or as environment variables:
    
    Required:
      PROJECT_ID      GCP project ID
      STATE_BUCKET    GCS bucket for Terraform state
    
    Optional:
      REGION          GCP region (default: us-central1)
      CLUSTER_NAME    Workstation cluster name (default: midnight-dev)
      ENVIRONMENT     Environment label (default: dev)

Examples:
    $(basename "$0") check                    # Validate config
    $(basename "$0") deploy                   # Full deployment
    $(basename "$0") plan                     # Preview changes
    CLUSTER_NAME=team1 $(basename "$0") deploy  # Custom cluster
EOF
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local command="${1:-help}"
    
    case "$command" in
        deploy)  cmd_deploy ;;
        plan)    cmd_plan ;;
        destroy) cmd_destroy ;;
        check)   cmd_check ;;
        help|-h|--help) cmd_help ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
