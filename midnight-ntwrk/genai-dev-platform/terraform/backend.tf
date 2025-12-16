# Terraform Backend Configuration
#
# Uses Google Cloud Storage for state storage.
# The bucket is configured via Cloud Build substitutions.

terraform {
  backend "gcs" {
    # bucket and prefix are configured via -backend-config in Cloud Build
  }
}
