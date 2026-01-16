#!/usr/bin/env bash
# Deploy chain workstation infrastructure locally with Terraform
#
# This script runs Terraform directly (without Cloud Build).
# For Cloud Build deployments, use: ./scripts/cloud.sh <chain> deploy
#
# Usage:
#   ./scripts/deploy.sh <chain> [options]
#
# Examples:
#   ./scripts/deploy.sh somnia
#   ./scripts/deploy.sh somnia --plan
#   ./scripts/deploy.sh somnia --auto-approve

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Load environment
load_env

# =============================================================================
# Configuration
# =============================================================================

CHAIN=""
AUTO_APPROVE=false
PLAN_ONLY=false
DESTROY=false

# From .env or environment
PROJECT_ID="${PROJECT_ID:-}"
STATE_BUCKET="${STATE_BUCKET:-}"
STATE_PREFIX="${STATE_PREFIX:-terraform/state}"
REGION="${REGION:-us-central1}"
TAG="${TAG:-latest}"

# =============================================================================
# Parse Arguments
# =============================================================================

show_help() {
    cat << EOF
Deploy chain workstation infrastructure with Terraform (local)

This script runs Terraform directly on your machine.
For Cloud Build deployments, use: ./scripts/cloud.sh <chain> deploy

Usage:
  $(basename "$0") <chain> [options]

Arguments:
  chain                     Chain to deploy (e.g., somnia)

Options:
  --plan                    Only show plan, don't apply
  --auto-approve            Skip interactive approval
  --destroy                 Destroy infrastructure instead of creating
  --tag=TAG                 Container image tag (default: latest)
  -h, --help                Show this help message

Environment Variables (set in .env):
  PROJECT_ID                GCP project ID (required)
  STATE_BUCKET              GCS bucket for Terraform state (required)
  REGION                    GCP region (default: us-central1)

Available chains:
$(list_chains | sed 's/^/  /')

Examples:
  $(basename "$0") somnia                    # Deploy with prompts
  $(basename "$0") somnia --plan             # Preview changes
  $(basename "$0") somnia --auto-approve     # Deploy without prompts
  $(basename "$0") somnia --destroy          # Tear down
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        --plan)
            PLAN_ONLY=true
            shift
            ;;
        --destroy)
            DESTROY=true
            shift
            ;;
        --tag=*)
            TAG="${1#*=}"
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
                log_error "Unexpected argument: $1"
                show_help
                exit 1
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

require_var PROJECT_ID
require_var STATE_BUCKET
require_command terraform
require_chain "$CHAIN"

# Load chain configuration
load_chain_config "$CHAIN"

# =============================================================================
# Deploy
# =============================================================================

log_info "Deploying ${CHAIN} infrastructure..."
log_info "  Project: ${PROJECT_ID}"
log_info "  Region: ${REGION}"
log_info "  Image Tag: ${TAG}"
log_info "  State: gs://${STATE_BUCKET}/${STATE_PREFIX}"

# Initialize Terraform with backend config
log_info "Initializing Terraform..."
terraform_init "$STATE_BUCKET" "$STATE_PREFIX"

if [[ "$DESTROY" == "true" ]]; then
    # Destroy
    log_warn "Destroying ${CHAIN} infrastructure..."
    
    if [[ "$AUTO_APPROVE" == "false" ]]; then
        echo ""
        echo "WARNING: This will destroy all ${CHAIN} cloud infrastructure!"
        echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
        sleep 10
    fi
    
    terraform_destroy "$CHAIN" "$PROJECT_ID" "$REGION" "$AUTO_APPROVE"
    
elif [[ "$PLAN_ONLY" == "true" ]]; then
    # Plan only
    log_info "Planning infrastructure changes..."
    terraform_plan "$CHAIN" "$PROJECT_ID" "$REGION" "$TAG"
    
else
    # Apply
    log_info "Applying infrastructure changes..."
    terraform_apply "$CHAIN" "$PROJECT_ID" "$REGION" "$TAG" "$AUTO_APPROVE"
    
    # Show outputs
    echo ""
    log_info "Terraform outputs:"
    cd "${TERRAFORM_DIR}"
    terraform output
fi
