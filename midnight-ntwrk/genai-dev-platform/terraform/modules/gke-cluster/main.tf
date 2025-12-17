# GKE Cluster Module
#
# Creates a GKE Autopilot cluster for Midnight services.
# Uses a public cluster for simplicity in dev environments.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
  }
}

# ===========================================
# GKE AUTOPILOT CLUSTER
# ===========================================

resource "google_container_cluster" "midnight_cluster" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.region

  # Enable Autopilot mode
  enable_autopilot = true

  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork

  # Resource labels
  resource_labels = var.labels

  # Deletion protection (disable for dev)
  deletion_protection = false

  # IMPORTANT: Lifecycle block to prevent unnecessary cluster recreation.
  # GKE Autopilot auto-populates several fields (ip_allocation_policy,
  # node_config, node_pool, etc.) which can cause Terraform to see diffs
  # on every run and attempt to recreate the cluster. This block tells
  # Terraform to ignore changes to these auto-managed fields.
  lifecycle {
    ignore_changes = [
      # GKE auto-allocates IP ranges for pods and services
      ip_allocation_policy,
      # Autopilot manages node configuration automatically
      node_config,
      node_pool,
      # Initial node count is managed by Autopilot
      initial_node_count,
    ]
  }
}
