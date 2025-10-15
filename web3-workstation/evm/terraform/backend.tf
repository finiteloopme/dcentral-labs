terraform {
  backend "gcs" {
    # The bucket name will be provided via backend-config during terraform init
    # Example: terraform init -backend-config="bucket=YOUR_BUCKET_NAME"
    prefix = "terraform/state"
  }
}