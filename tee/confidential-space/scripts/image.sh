#!/usr/bin/env bash
#
# image.sh - Build and push the workload container image.
#
# Usage:
#   bash scripts/image.sh build     # local build with podman (for testing)
#   bash scripts/image.sh submit    # build + push via Cloud Build
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ---------------------------------------------------------------------------
# Build the container image locally with podman (for testing)
# ---------------------------------------------------------------------------
cmd_build() {
    log_info "Building image locally: $DOCKER_IMAGE_URI"
    podman build -t "$DOCKER_IMAGE_URI" "$PROJECT_ROOT"
    log_info "Local build complete."
}

# ---------------------------------------------------------------------------
# Build + push via Cloud Build (no local auth or push needed)
# ---------------------------------------------------------------------------
cmd_submit() {
    log_info "Submitting image build to Cloud Build: $DOCKER_IMAGE_URI"

    gcloud builds submit "$PROJECT_ROOT" \
        --project="$GCP_PROJECT_ID" \
        --region="$GCP_REGION" \
        --config="$PROJECT_ROOT/terraform/cloudbuild-image.yaml" \
        --service-account="projects/$GCP_PROJECT_ID/serviceAccounts/$CB_SA_EMAIL" \
        --substitutions="_IMAGE_URI=${DOCKER_IMAGE_URI}" \
        --quiet

    log_info "Image built and pushed via Cloud Build."
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "${1:-}" in
    build)  cmd_build ;;
    submit) cmd_submit ;;
    *)
        echo "Usage: $0 {build|submit}"
        exit 1
        ;;
esac
