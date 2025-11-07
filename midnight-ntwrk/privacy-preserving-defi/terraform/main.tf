terraform {
  backend "gcs" {
    bucket = "privacy-defi-mvp-terraform-state"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Enable required GCP services
module "services" {
  source = "./modules/services"
  
  gcp_project = var.gcp_project
}

# Create VPC and networking resources
module "networking" {
  source = "./modules/networking"
  
  gcp_project   = var.gcp_project
  gcp_region    = var.gcp_region
  project_name  = var.project_name
  environment   = var.environment
  subnet_cidr   = var.subnet_cidr
  
  depends_on = [module.services]
}

# Create IAM and service account resources
module "iam" {
  source = "./modules/iam"
  
  gcp_project        = var.gcp_project
  gcp_region         = var.gcp_region
  project_name       = var.project_name
  tee_image_digest   = var.tee_image_digest
  
  depends_on = [module.services]
}

# Create compute instances
module "compute" {
  source = "./modules/compute"
  
  gcp_project                  = var.gcp_project
  gcp_region                   = var.gcp_region
  project_name                 = var.project_name
  environment                  = var.environment
  ssh_public_key_path           = var.ssh_public_key_path
  mock_server_machine_type      = var.mock_server_machine_type
  tee_service_machine_type      = var.tee_service_machine_type
  mock_server_ip               = var.mock_server_ip
  tee_service_ip               = var.tee_service_ip
  subnet_name                  = module.networking.subnet_name
  
  depends_on = [
    module.services,
    module.networking,
    module.iam
  ]
}