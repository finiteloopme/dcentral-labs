# Main Terraform Configuration
#
# This root module orchestrates:
# 1. Artifact Registry for container images
# 2. GKE Autopilot cluster for Midnight services
# 3. Kubernetes resources (Midnight node, proof-server, indexer)
# 4. Cloud Workstations cluster and configuration

locals {
  labels = {
    cluster           = var.cluster_name
    environment       = var.environment
    chain_environment = var.chain_environment
    managed_by        = "terraform"
  }

  # Roles required by Cloud Build service account
  cloudbuild_sa_roles = var.cloudbuild_sa_email != "" ? toset([
    "roles/artifactregistry.admin",     # Push/pull container images, manage repository IAM
    "roles/compute.viewer",             # Read GKE cluster compute resources (instance groups)
    "roles/container.admin",            # GKE cluster management
    "roles/container.clusterAdmin",     # GKE cluster admin operations
    "roles/iam.serviceAccountCreator",  # Create service accounts for workloads
    "roles/iam.serviceAccountUser",     # Act as service accounts
    "roles/logging.logWriter",          # Write build logs
    "roles/storage.admin",              # Access Terraform state and build artifacts
    "roles/workstations.admin",         # Manage Cloud Workstations
  ]) : toset([])
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "workstations.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# ===========================================
# IAM BINDINGS FOR CLOUD BUILD SA
# ===========================================

# Get project info for service account references
data "google_project" "project" {
  project_id = var.project_id
}

# Grant all required roles to Cloud Build service account
resource "google_project_iam_member" "cloudbuild_sa" {
  for_each = local.cloudbuild_sa_roles

  project    = var.project_id
  role       = each.value
  member     = "serviceAccount:${var.cloudbuild_sa_email}"

  depends_on = [google_project_service.apis]
}

# ===========================================
# ARTIFACT REGISTRY
# ===========================================

module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id = var.project_id
  region     = var.region
  labels     = local.labels

  depends_on = [
    google_project_service.apis,
    google_project_iam_member.cloudbuild_sa,
  ]
}

# ===========================================
# GKE AUTOPILOT CLUSTER
# ===========================================

module "gke_cluster" {
  source = "./modules/gke-cluster"

  project_id   = var.project_id
  region       = var.region
  cluster_name = var.gke_cluster_name
  network      = "default"
  subnetwork   = "default"
  labels       = local.labels

  depends_on = [
    google_project_service.apis,
    google_project_iam_member.cloudbuild_sa,
  ]
}

# ===========================================
# MIDNIGHT KUBERNETES SERVICES
# ===========================================

module "midnight_k8s_services" {
  source = "./modules/midnight-k8s-services"

  midnight_node_image = var.midnight_node_image
  proof_server_image  = var.proof_server_image
  indexer_image       = var.indexer_image
  indexer_secret      = var.indexer_secret
  chain_environment   = var.chain_environment
  labels              = local.labels

  # This module depends on the GKE cluster being ready
  # The kubernetes provider is configured in versions.tf using the cluster outputs
  depends_on = [module.gke_cluster]
}

# ===========================================
# CLOUD WORKSTATIONS
# ===========================================

module "workstations" {
  source = "./modules/workstations"

  project_id              = var.project_id
  region                  = var.region
  cluster_name            = var.cluster_name
  container_image         = var.container_image
  machine_type            = var.machine_type
  persistent_disk_size_gb = var.persistent_disk_size_gb
  labels                  = local.labels

  # Pass GKE service URLs as environment variables
  service_urls = {
    MIDNIGHT_NODE_URL = module.midnight_k8s_services.node_url
    PROOF_SERVER_URL  = module.midnight_k8s_services.proof_server_url
    INDEXER_URL       = module.midnight_k8s_services.indexer_url
    CHAIN_ENVIRONMENT = var.chain_environment
  }

  depends_on = [
    google_project_service.apis,
    google_project_iam_member.cloudbuild_sa,
    module.artifact_registry,
    module.midnight_k8s_services,
  ]
}
