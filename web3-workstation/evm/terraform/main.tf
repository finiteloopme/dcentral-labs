terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Define all required APIs
locals {
  apis = {
    compute              = "compute.googleapis.com"
    workstations        = "workstations.googleapis.com"
    artifact_registry   = "artifactregistry.googleapis.com"
    container_registry  = "containerregistry.googleapis.com"
    storage             = "storage.googleapis.com"
    resource_manager    = "cloudresourcemanager.googleapis.com"
    iam                 = "iam.googleapis.com"
    cloudbuild          = "cloudbuild.googleapis.com"
    source_repo         = "sourcerepo.googleapis.com"
    logging             = "logging.googleapis.com"
    monitoring          = "monitoring.googleapis.com"
    service_usage       = "serviceusage.googleapis.com"
  }
}

# Enable required APIs with proper dependency management
resource "google_project_service" "required_apis" {
  for_each = local.apis
  
  project = var.project_id
  service = each.value
  
  # Prevent accidental disabling of APIs when destroying
  disable_on_destroy = var.disable_apis_on_destroy
  
  # Ensure APIs are enabled sequentially to avoid race conditions
  disable_dependent_services = false
  
  timeouts {
    create = "10m"
    update = "10m"
  }
}

# Create GCS bucket for Terraform state (if not exists)
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-${var.terraform_state_bucket}"
  location      = var.region
  force_destroy = false
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.labels
  
  depends_on = [google_project_service.required_apis["storage"]]
}

# Create Artifact Registry repository
resource "google_artifact_registry_repository" "workstation_images" {
  location      = var.region
  repository_id = var.artifact_registry_repo
  description   = "Docker repository for Web3 workstation images"
  format        = "DOCKER"
  
  labels = var.labels
  
  depends_on = [google_project_service.required_apis["artifact_registry"]]
}

# Create VPC network
resource "google_compute_network" "workstation_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  
  depends_on = [google_project_service.required_apis["compute"]]
}

# Create subnet
resource "google_compute_subnetwork" "workstation_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.workstation_network.id
  
  private_ip_google_access = true
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
  }
}

# Create firewall rules for workstation access
resource "google_compute_firewall" "workstation_allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.workstation_network.name
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [var.subnet_cidr]
  priority      = 1000
}

resource "google_compute_firewall" "workstation_allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.workstation_network.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["35.235.240.0/20"] # Google IAP range
  priority      = 1000
}

# Create Cloud Workstation cluster
resource "google_workstations_workstation_cluster" "main" {
  provider               = google-beta
  workstation_cluster_id = var.workstation_cluster_name
  network                = google_compute_network.workstation_network.id
  subnetwork             = google_compute_subnetwork.workstation_subnet.id
  location               = var.region
  
  labels = var.labels
  
  depends_on = [
    google_project_service.required_apis["workstations"],
    google_compute_firewall.workstation_allow_internal,
    google_compute_firewall.workstation_allow_ssh
  ]
}

# Create Cloud Workstation configuration
resource "google_workstations_workstation_config" "web3_dev" {
  provider               = google-beta
  workstation_config_id  = var.workstation_config_name
  workstation_cluster_id = google_workstations_workstation_cluster.main.workstation_cluster_id
  location               = var.region
  
  display_name = "Web3 Development Environment"
  
  labels = var.labels
  
  idle_timeout    = "${var.idle_timeout}s"
  running_timeout = "${var.running_timeout}s"
  
  host {
    gce_instance {
      machine_type                = var.machine_type
      boot_disk_size_gb           = var.boot_disk_size
      disable_public_ip_addresses = false
      enable_nested_virtualization = false
      
      shielded_instance_config {
        enable_secure_boot          = false
        enable_vtpm                 = true
        enable_integrity_monitoring = true
      }
      
      tags = ["web3-workstation"]
    }
  }
  
  container {
    # Reference the custom image from Artifact Registry
    image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/web3-workstation:latest"
    
    # Environment variables
    env = {
      FOUNDRY_PATH = "/usr/local/bin"
      NODE_ENV     = "development"
    }
    
    # Working directory
    working_dir = "/home/user"
  }
  
  # Persistent home directory
  persistent_directories {
    mount_path = "/home"
    gce_pd {
      size_gb        = 200
      fs_type        = "ext4"
      disk_type      = "pd-standard"
      reclaim_policy = "DELETE"
    }
  }
  
  # Disable encryption for simplicity (enable in production)
  encryption_key {
    service_account = "workstations-service-account@${var.project_id}.iam.gserviceaccount.com"
  }
  
  # Note: The workstation will use the default compute service account
  # which needs Vertex AI permissions
  
  depends_on = [
    google_workstations_workstation_cluster.main,
    google_artifact_registry_repository.workstation_images
  ]
}

# Create IAM binding for users to access workstations
resource "google_project_iam_member" "workstation_user" {
  project = var.project_id
  role    = "roles/workstations.user"
  member  = "user:${data.google_client_openid_userinfo.me.email}"
  
  depends_on = [google_project_service.required_apis["iam"]]
}

resource "google_project_iam_member" "workstation_admin" {
  project = var.project_id
  role    = "roles/workstations.admin"
  member  = "user:${data.google_client_openid_userinfo.me.email}"
  
  depends_on = [google_project_service.required_apis["iam"]]
}

# Grant Vertex AI permissions to the default compute service account
# (used by workstations)
resource "google_project_iam_member" "workstation_vertex_ai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  
  depends_on = [google_project_service.required_apis["iam"]]
}

# Get project data
data "google_project" "project" {
  project_id = var.project_id
}

# Get current user info
data "google_client_openid_userinfo" "me" {}

# Outputs
output "workstation_cluster_name" {
  value       = google_workstations_workstation_cluster.main.name
  description = "The name of the workstation cluster"
}

output "workstation_config_name" {
  value       = google_workstations_workstation_config.web3_dev.name
  description = "The name of the workstation configuration"
}

output "artifact_registry_repository" {
  value       = google_artifact_registry_repository.workstation_images.name
  description = "The name of the Artifact Registry repository"
}

output "artifact_registry_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}"
  description = "The URL of the Artifact Registry repository"
}

output "terraform_state_bucket" {
  value       = google_storage_bucket.terraform_state.name
  description = "The name of the Terraform state bucket"
}

output "workstation_url" {
  value       = "https://console.cloud.google.com/workstations/list?project=${var.project_id}"
  description = "URL to access workstations in the GCP Console"
}