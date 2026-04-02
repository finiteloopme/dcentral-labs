#!/usr/bin/env bash
#
# cloud-build.sh - Execute Terraform operations via Cloud Build.
#
# Usage:
#   bash scripts/cloud-build.sh plan
#   bash scripts/cloud-build.sh apply
#   bash scripts/cloud-build.sh destroy
#   bash scripts/cloud-build.sh output
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TF_DIR="$PROJECT_ROOT/terraform"

# ---------------------------------------------------------------------------
# Generate terraform.tfvars from current config
# ---------------------------------------------------------------------------
generate_tfvars() {
    local tfvars_file="$TF_DIR/terraform.tfvars"

    log_info "Generating $tfvars_file"
    cat > "$tfvars_file" <<EOF
project_id        = "${GCP_PROJECT_ID}"
region            = "${GCP_REGION}"
zone              = "${GCP_ZONE}"
app_name          = "${APP_NAME}"
app_port          = ${APP_PORT}
machine_type      = "${COMPUTE_MACHINE_TYPE}"
confidential_type = "${COMPUTE_CONFIDENTIAL_TYPE}"
image_family      = "${CS_IMAGE_FAMILY}"
docker_image      = "${DOCKER_IMAGE_URI}"
mig_min_replicas  = ${COMPUTE_MIG_MIN_REPLICAS}
mig_max_replicas  = ${COMPUTE_MIG_MAX_REPLICAS}
environment       = "${DEPLOY_ENVIRONMENT}"
EOF
    log_info "tfvars written."
}

# ---------------------------------------------------------------------------
# Submit a Cloud Build job to run Terraform
# ---------------------------------------------------------------------------
submit_build() {
    local tf_command="$1"

    generate_tfvars

    log_info "Submitting Cloud Build: terraform $tf_command"

    gcloud builds submit "$TF_DIR" \
        --project="$GCP_PROJECT_ID" \
        --region="$GCP_REGION" \
        --config="$TF_DIR/cloudbuild.yaml" \
        --service-account="projects/$GCP_PROJECT_ID/serviceAccounts/$CB_SA_EMAIL" \
        --substitutions="_TF_COMMAND=${tf_command},_TF_STATE_BUCKET=${TF_STATE_BUCKET}" \
        --quiet

    log_info "Cloud Build complete: terraform $tf_command"
}

# ---------------------------------------------------------------------------
# Retrieve Terraform outputs via Cloud Build
# ---------------------------------------------------------------------------
cmd_output() {
    generate_tfvars

    log_info "Fetching Terraform outputs via Cloud Build..."

    gcloud builds submit "$TF_DIR" \
        --project="$GCP_PROJECT_ID" \
        --region="$GCP_REGION" \
        --config="$TF_DIR/cloudbuild.yaml" \
        --service-account="projects/$GCP_PROJECT_ID/serviceAccounts/$CB_SA_EMAIL" \
        --substitutions="_TF_COMMAND=output,_TF_STATE_BUCKET=${TF_STATE_BUCKET}" \
        --quiet
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "${1:-}" in
    plan)    submit_build "plan" ;;
    apply)   submit_build "apply" ;;
    destroy) submit_build "destroy" ;;
    output)  cmd_output ;;
    *)
        echo "Usage: $0 {plan|apply|destroy|output}"
        exit 1
        ;;
esac
