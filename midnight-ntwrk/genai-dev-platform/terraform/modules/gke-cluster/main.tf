# GKE Cluster Module
#
# Creates a GKE Autopilot cluster for Midnight services.
# Includes Cloud NAT for internet egress (required for proof-server to download ZK keys).
# Kubernetes resources are created separately at the root level.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
  }
}

# ===========================================
# CLOUD NAT - Internet Egress for Private Cluster
# ===========================================
# Required for proof-server to download ZK key material from S3

# Cloud Router (required for Cloud NAT)
resource "google_compute_router" "midnight_router" {
  name    = "${var.cluster_name}-router"
  project = var.project_id
  region  = var.region
  network = var.network
}

# Cloud NAT gateway
resource "google_compute_router_nat" "midnight_nat" {
  name                               = "${var.cluster_name}-nat"
  project                            = var.project_id
  router                             = google_compute_router.midnight_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
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

  # Private cluster for security
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Note: We intentionally omit ip_allocation_policy here.
  # GKE Autopilot auto-allocates IP ranges, and an empty block causes
  # Terraform to detect a diff on every run (triggering cluster recreation).
  # The lifecycle block below ignores changes to this field.

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
