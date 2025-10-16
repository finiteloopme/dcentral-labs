provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "workstations.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
  disable_dependent_services = false
}

# Networking module
module "networking" {
  source = "./modules/networking"
  
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  depends_on = [google_project_service.apis]
}

# Artifact Registry module
module "registry" {
  source = "./modules/registry"
  
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  depends_on = [google_project_service.apis]
}

# Cloud Workstations module
module "workstations" {
  source = "./modules/workstations"
  
  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  environment  = var.environment
  network_id   = module.networking.network_id
  subnet_id    = module.networking.subnet_id
  registry_url = module.registry.registry_url
  
  workstation_config    = var.workstation_config
  proof_service_url     = var.proof_service_url
  proof_service_config  = var.proof_service_config
  
  depends_on = [
    google_project_service.apis,
    module.networking,
    module.registry
  ]
}