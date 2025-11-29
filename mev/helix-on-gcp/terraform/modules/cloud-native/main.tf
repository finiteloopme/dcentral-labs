variable "project_id" {}
variable "region" {}
variable "vpc_id" {}
variable "vpc_link" {}
variable "subnet_link" {}
variable "image_tag" {}

# --- 1. Cloud SQL Enterprise Plus ---
resource "google_sql_database_instance" "postgres" {
  name             = "helix-db-plus-${random_id.suffix.hex}"
  region           = var.region
  database_version = "POSTGRES_15"
  
  settings {
    tier              = "db-perf-optimized-N-4" # Enterprise Plus (4 vCPU)
    edition           = "ENTERPRISE_PLUS"
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    
    data_cache_config {
      data_cache_enabled = true
    }
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_link
    }
  }
  deletion_protection = false
}

resource "random_id" "suffix" { byte_length = 4 }

resource "google_sql_database" "helix_db" {
  name     = "helix_db"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "helix_user" {
  name     = "helix"
  instance = google_sql_database_instance.postgres.name
  password = "benchmark_password"
}

# --- 2. Memorystore Redis ---
resource "google_redis_instance" "cache" {
  name           = "helix-redis"
  tier           = "STANDARD_HA"
  memory_size_gb = 5
  region         = var.region
  
  authorized_network = var.vpc_id
  connect_mode       = "DIRECT_PEERING"
  redis_version      = "REDIS_7_0"
}

# --- 3. GKE Cluster (Compact Placement) ---
resource "google_compute_resource_policy" "compact" {
  name   = "helix-compact-policy"
  region = var.region
  group_placement_policy {
    collocation = "COLLOCATED"
  }
}

resource "google_container_cluster" "primary" {
  name     = "helix-cluster"
  location = "${var.region}-a"
  network  = var.vpc_link
  subnetwork = var.subnet_link
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Enable Managed Prometheus
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    managed_prometheus {
      enabled = true
    }
  }
}

resource "google_container_node_pool" "c2_nodes" {
  name       = "helix-c2-pool"
  cluster    = google_container_cluster.primary.id
  node_count = 2

  placement_policy {
    type = "COMPACT"
  }

  node_config {
    machine_type = "c2-standard-8"
    image_type   = "COS_CONTAINERD"
    
    # "Jailbreak" config for performance
    kubelet_config {
      cpu_manager_policy = "static"
      cpu_cfs_quota      = false
    }
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# Outputs for the Kubernetes Provider
output "cluster_endpoint" { value = google_container_cluster.primary.endpoint }
output "cluster_ca_certificate" { value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate }
