# -----------------------------------------------------------------------------
# Remote backend: GCS bucket for Terraform state.
# The bucket name is passed dynamically via -backend-config in Cloud Build.
# -----------------------------------------------------------------------------

terraform {
  backend "gcs" {
    # bucket is set dynamically via:
    #   terraform init -backend-config="bucket=<TF_STATE_BUCKET>"
    prefix = "confidential-space"
  }
}
