
terraform {
  backend "gcs" {
      bucket = "gcda-apac-sc-tf-state" # This GCS bucket must exist
      prefix = "suave" # Application name used to identify the TF state
  }
  required_providers {
    google = {
      source = "hashicorp/google"
    } 
    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

# google-beta provider
provider "google-beta" {
  project     = var.project_id
  region      = var.gcp_region
}

# default google provider for most resources
provider "google" {
  project     = var.project_id
  region      = var.gcp_region
}

# used to get project number
data "google_project" "project" {
}
