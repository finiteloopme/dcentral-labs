# Terraform backend configuration for GCS
# This file will be configured dynamically by the setup script

terraform {
  backend "gcs" {
    # bucket  = "will-be-set-by-init-script"
    # prefix  = "terraform/state"
  }
}
