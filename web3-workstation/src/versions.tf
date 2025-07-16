// -----------------------------------------------------------------------------
// versions.tf - Define provider versions
// -----------------------------------------------------------------------------
terraform {
    required_providers {
        google = {
            source  = "hashicorp/google"
            version = ">= 6.34.0" // Use a recent version
        }
        google-beta = {
            source  = "hashicorp/google-beta"
            version = ">= 6.34.0" // Use a recent version
        }
    }
    # Configuration for the Google Cloud Storage backend
    # backend "gcs" {
    #     bucket  = "kunal-scratch"  # Replace with your bucket name
    #     prefix  = "terraform/workstations"                # Optional prefix
    # }
}
