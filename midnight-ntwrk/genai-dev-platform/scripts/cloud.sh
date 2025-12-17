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
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
STATE_PREFIX="${STATE_PREFIX:-terraform/state}"

# Optional with defaults
REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-midnight-dev}"
GKE_CLUSTER_NAME="${GKE_CLUSTER_NAME:-midnight-dev-gke}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
CHAIN_ENVIRONMENT="${CHAIN_ENVIRONMENT:-standalone}"
IMAGE_NAME="${IMAGE_NAME:-midnight-dev-platform}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-4}"
PERSISTENT_DISK_SIZE_GB="${PERSISTENT_DISK_SIZE_GB:-100}"
MIDNIGHT_NODE_IMAGE="${MIDNIGHT_NODE_IMAGE:-midnightntwrk/midnight-node:0.18.0-rc.9}"
PROOF_SERVER_IMAGE="${PROOF_SERVER_IMAGE:-midnightnetwork/proof-server:6.2.0-rc.1}"
INDEXER_IMAGE="${INDEXER_IMAGE:-midnightntwrk/indexer-standalone:3.0.0-alpha.20}"
INDEXER_SECRET="${INDEXER_SECRET:-}"
CLOUDBUILD_SA_EMAIL="${CLOUDBUILD_SA_EMAIL:-}"

# ==============================================================================
# Helpers
# ==============================================================================

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1" >&2; }
log_success() { echo "[OK] $1"; }

get_substitutions() {
    echo "_PROJECT_ID=${PROJECT_ID},\
_STATE_BUCKET=${STATE_BUCKET},\
_STATE_PREFIX=${STATE_PREFIX},\
_REGION=${REGION},\
_CLUSTER_NAME=${CLUSTER_NAME},\
_GKE_CLUSTER_NAME=${GKE_CLUSTER_NAME},\
_ENVIRONMENT=${ENVIRONMENT},\
_CHAIN_ENVIRONMENT=${CHAIN_ENVIRONMENT},\
_IMAGE_NAME=${IMAGE_NAME},\
_IMAGE_TAG=${IMAGE_TAG},\
_MACHINE_TYPE=${MACHINE_TYPE},\
_PERSISTENT_DISK_SIZE_GB=${PERSISTENT_DISK_SIZE_GB},\
_MIDNIGHT_NODE_IMAGE=${MIDNIGHT_NODE_IMAGE},\
_PROOF_SERVER_IMAGE=${PROOF_SERVER_IMAGE},\
_INDEXER_IMAGE=${INDEXER_IMAGE},\
_INDEXER_SECRET=${INDEXER_SECRET},\
_CLOUDBUILD_SA_EMAIL=${CLOUDBUILD_SA_EMAIL}"
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
    
    if [[ -z "$CLOUDBUILD_SA_EMAIL" ]]; then
        log_error "CLOUDBUILD_SA_EMAIL is required. Set in .env or environment"
        log_error "Example: midnight-cloudbuild-sa@your-project.iam.gserviceaccount.com"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        exit 1
    fi
    
    echo ""
    echo "Configuration:"
    echo "  PROJECT_ID:          ${PROJECT_ID}"
    echo "  STATE_BUCKET:        ${STATE_BUCKET}"
    echo "  STATE_PREFIX:        ${STATE_PREFIX}"
    echo "  REGION:              ${REGION}"
    echo "  CLUSTER_NAME:        ${CLUSTER_NAME}"
    echo "  GKE_CLUSTER_NAME:    ${GKE_CLUSTER_NAME}"
    echo "  CHAIN_ENVIRONMENT:   ${CHAIN_ENVIRONMENT}"
    echo "  CLOUDBUILD_SA_EMAIL: ${CLOUDBUILD_SA_EMAIL}"
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
    
    gcloud beta builds submit \
        --config="${PROJECT_DIR}/cicd-pipelines/cloudbuild.yaml" \
        --substitutions="$(get_substitutions)" \
        --service-account="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA_EMAIL}" \
        --project="$PROJECT_ID" \
        "$PROJECT_DIR"
}

cmd_plan() {
    cmd_check
    
    echo ""
    log_info "Planning deployment (dry run)..."
    echo ""
    
    gcloud beta builds submit \
        --config="${PROJECT_DIR}/cicd-pipelines/cloudbuild-plan.yaml" \
        --substitutions="$(get_substitutions)" \
        --service-account="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA_EMAIL}" \
        --project="$PROJECT_ID" \
        "$PROJECT_DIR"
}

cmd_destroy() {
    cmd_check
    
    echo ""
    echo "WARNING: This will destroy all cloud infrastructure!"
    echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
    sleep 10
    
    gcloud beta builds submit \
        --config="${PROJECT_DIR}/cicd-pipelines/cloudbuild-destroy.yaml" \
        --substitutions="$(get_substitutions)" \
        --service-account="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA_EMAIL}" \
        --project="$PROJECT_ID" \
        "$PROJECT_DIR"
}

cmd_state_cleanup() {
    cmd_check
    
    local pattern="${1:-}"
    local delete_flag="${2:-}"
    local dry_run="false"
    local delete="false"
    
    # Check for --list or --dry-run flag
    if [ "$pattern" = "--list" ] || [ "$pattern" = "-l" ]; then
        pattern=""
        dry_run="true"
    elif [ "$pattern" = "--dry-run" ] || [ "$pattern" = "-n" ]; then
        pattern="${2:-}"
        dry_run="true"
    fi
    
    # Check for DELETE=true flag
    if [ "$delete_flag" = "true" ] || [ "$delete_flag" = "TRUE" ]; then
        delete="true"
    fi
    
    echo ""
    if [ -z "$pattern" ]; then
        log_info "Listing Terraform state..."
    else
        if [ "$dry_run" = "true" ]; then
            if [ "$delete" = "true" ]; then
                log_info "Dry run: Would DESTROY resources matching '$pattern'..."
            else
                log_info "Dry run: Would remove resources matching '$pattern' from state..."
            fi
        else
            if [ "$delete" = "true" ]; then
                log_info "DESTROYING resources matching '$pattern' (and removing from state)..."
            else
                log_info "Removing resources matching '$pattern' from Terraform state..."
            fi
        fi
    fi
    echo ""
    
    gcloud beta builds submit \
        --config="${PROJECT_DIR}/cicd-pipelines/cloudbuild-state-cleanup.yaml" \
        --substitutions="$(get_substitutions),_STATE_BUCKET=${STATE_BUCKET},_STATE_PREFIX=${STATE_PREFIX},_RESOURCE_PATTERN=${pattern},_DRY_RUN=${dry_run},_DELETE=${delete}" \
        --service-account="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA_EMAIL}" \
        --project="$PROJECT_ID" \
        "$PROJECT_DIR"
}

cmd_help() {
    cat <<EOF
Midnight Cloud Deployment Script

Usage: $(basename "$0") <command>

Commands:
    deploy                    Build container and deploy all infrastructure
    plan                      Preview deployment changes (Terraform plan)
    destroy                   Destroy all cloud infrastructure
    state-cleanup [PATTERN]   Remove resources matching PATTERN from state
    check                     Validate configuration

State Cleanup Options:
    state-cleanup --list              List all resources in state
    state-cleanup <pattern>           Remove resources matching pattern from state only
    state-cleanup <pattern> DELETE    DESTROY resources AND remove from state
    state-cleanup --dry-run <pattern> Preview what would be removed/destroyed
    
    Examples:
      state-cleanup midnight_k8s_services         # Remove from state only
      state-cleanup midnight_k8s_services DELETE  # Destroy resources AND remove from state
      state-cleanup "google_cloud_run.*"          # Remove all Cloud Run resources from state
      state-cleanup --dry-run workstations        # Preview removal

Configuration:
    Set these in .env or as environment variables:
    
    Required:
      PROJECT_ID          GCP project ID
      STATE_BUCKET        GCS bucket for Terraform state
      CLOUDBUILD_SA_EMAIL Cloud Build service account email
    
    Optional:
      STATE_PREFIX      Prefix path in bucket (default: terraform/state)
      REGION            GCP region (default: us-central1)
      CLUSTER_NAME      Workstation cluster name (default: midnight-dev)
      GKE_CLUSTER_NAME  GKE Autopilot cluster name (default: midnight-dev-gke)
      CHAIN_ENVIRONMENT Chain environment (default: standalone)
      ENVIRONMENT       Environment label (default: dev)

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
        state-cleanup) shift; cmd_state_cleanup "$@" ;;
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
