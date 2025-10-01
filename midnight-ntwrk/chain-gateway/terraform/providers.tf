
# It is recommended to use the latest versions of Terraform and the google provider
# to ensure that you have the latest features and bug fixes.
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
