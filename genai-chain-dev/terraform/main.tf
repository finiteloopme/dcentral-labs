# Shared Terraform configuration for all chains
#
# This creates:
# - Artifact Registry for container images
# - Cloud Workstation cluster and configuration
# - Individual workstations for developers

locals {
  # Container image path
  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/dev-images/${var.chain}-dev:${var.image_tag}"

  # Workstation naming
  cluster_name = "${var.chain}-dev"
  config_name  = "${var.chain}-dev-config"

  # Environment variables passed to workstation container
  workstation_env_vars = {
    CHAIN_NAME      = var.chain_name
    CLI_NAME        = var.cli_name
    CHAIN_ID        = var.chain_id
    RPC_URL         = var.rpc_url
    EXPLORER_URL    = var.explorer_url
    FAUCET_URL      = var.faucet_url
    NATIVE_CURRENCY = var.native_currency
  }

  # Vertex AI project (defaults to main project)
  vertex_project = var.vertex_ai_project != "" ? var.vertex_ai_project : var.project_id
}

# =============================================================================
# Artifact Registry
# =============================================================================

module "artifact_registry" {
  source = "../core/terraform/modules/artifact-registry"

  project_id      = var.project_id
  region          = var.region
  name            = "dev-images"
  description     = "Chain development container images"
}

# =============================================================================
# Cloud Workstations
# =============================================================================

module "workstations" {
  source = "../core/terraform/modules/workstations"

  project_id        = var.project_id
  region            = var.region
  cluster_name      = local.cluster_name
  config_name       = local.config_name
  container_image   = local.container_image
  machine_type      = var.machine_type
  boot_disk_size_gb = var.boot_disk_size_gb
  home_disk_size_gb = var.home_disk_size_gb
  idle_timeout      = var.idle_timeout
  running_timeout   = var.running_timeout
  workstations      = var.workstations
  workstation_admins = var.workstation_admins
  env_vars          = local.workstation_env_vars

  depends_on = [module.artifact_registry]
}
