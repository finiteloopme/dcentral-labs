terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.7"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.7"
    }
  }
}
