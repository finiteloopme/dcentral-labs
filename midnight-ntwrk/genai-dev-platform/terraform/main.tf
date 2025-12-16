# Main Terraform Configuration
#
# This root module orchestrates:
# 1. Artifact Registry for container images
# 2. Cloud Workstations cluster and configuration
# 3. Cloud Run services for Midnight standalone network

locals {
  labels = {
    cluster     = var.cluster_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "workstations.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "compute.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Artifact Registry for dev container images
module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id = var.project_id
  region     = var.region
  labels     = local.labels

  depends_on = [google_project_service.apis]
}

# Cloud Workstations
module "workstations" {
  source = "./modules/workstations"

  project_id              = var.project_id
  region                  = var.region
  cluster_name            = var.cluster_name
  container_image         = var.container_image
  machine_type            = var.machine_type
  persistent_disk_size_gb = var.persistent_disk_size_gb
  labels                  = local.labels

  # Pass Cloud Run service URLs as environment variables
  service_urls = {
    MIDNIGHT_NODE_URL  = module.midnight_services.node_url
    PROOF_SERVER_URL   = module.midnight_services.proof_server_url
    INDEXER_URL        = module.midnight_services.indexer_url
  }

  depends_on = [
    google_project_service.apis,
    module.artifact_registry,
    module.midnight_services,
  ]
}

# Midnight Cloud Run Services
module "midnight_services" {
  source = "./modules/midnight-services"

  project_id          = var.project_id
  region              = var.region
  cluster_name        = var.cluster_name
  min_instances       = var.min_instances
  midnight_node_image = var.midnight_node_image
  proof_server_image  = var.proof_server_image
  indexer_image       = var.indexer_image
  labels              = local.labels

  # Grant workstation service account access to invoke services
  workstation_service_account = module.workstations.service_account_email

  depends_on = [google_project_service.apis]
}
