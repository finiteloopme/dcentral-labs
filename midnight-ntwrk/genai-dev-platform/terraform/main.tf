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
    "storage.googleapis.com",
    "aiplatform.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
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

  workstation_config = var.workstation_config
  workstations       = var.workstations

  depends_on = [
    google_project_service.apis,
    module.networking,
    module.registry
  ]
}

# DNS module for custom domain
module "dns" {
  source = "./modules/dns"

  project_id     = var.project_id
  environment    = var.environment
  domain_name    = var.custom_domain
  enable_dns     = var.enable_custom_domain
  workstation_ip = var.custom_domain_ip != "" ? var.custom_domain_ip : module.networking.nat_ip

  dns_records = var.additional_dns_records

  depends_on = [
    google_project_service.apis,
    module.networking
  ]
}

# IAM bindings for Cloud Build service account
locals {
  cloudbuild_service_account = var.cloudbuild_service_account != "" ? var.cloudbuild_service_account : "midnight-cloudbuild-sa@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_binding" "cloudbuild_service_account_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountCreator"
  members = [
    "serviceAccount:${local.cloudbuild_service_account}"
  ]
}

resource "google_project_iam_binding" "cloudbuild_project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  members = [
    "serviceAccount:${local.cloudbuild_service_account}"
  ]
}

# Additional IAM roles needed for Cloud Build to manage workstation resources
resource "google_project_iam_binding" "cloudbuild_workstations_admin" {
  project = var.project_id
  role    = "roles/workstations.admin"
  members = [
    "serviceAccount:${local.cloudbuild_service_account}"
  ]
}

resource "google_project_iam_binding" "cloudbuild_service_account_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  members = [
    "serviceAccount:${local.cloudbuild_service_account}"
  ]
}
