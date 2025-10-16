# Workstation cluster
resource "google_workstations_workstation_cluster" "cluster" {
  provider               = google-beta
  workstation_cluster_id = "midnight-${var.environment}-cluster"
  network                = var.network_id
  subnetwork             = var.subnet_id
  location               = var.region
  project                = var.project_id
  
  labels = {
    environment = var.environment
    project     = "midnight"
  }
  
  private_cluster_config {
    enable_private_endpoint = false
  }
}

# Workstation configuration
resource "google_workstations_workstation_config" "config" {
  provider               = google-beta
  workstation_config_id  = "midnight-${var.environment}-config"
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = var.region
  project                = var.project_id
  
  display_name = "Midnight Development Environment"
  
  labels = {
    environment = var.environment
    project     = "midnight"
  }
  
  idle_timeout    = var.workstation_config.idle_timeout
  running_timeout = var.workstation_config.running_timeout
  
  host {
    gce_instance {
      machine_type                = var.workstation_config.machine_type
      boot_disk_size_gb          = var.workstation_config.boot_disk_size_gb
      disable_public_ip_addresses = false
      enable_nested_virtualization = false
      
      shielded_instance_config {
        enable_secure_boot          = true
        enable_vtpm                 = true
        enable_integrity_monitoring = true
      }
    }
  }
  
  persistent_directories {
    mount_path = "/home"
    gce_pd {
      size_gb        = var.workstation_config.persistent_disk_size_gb
      fs_type        = "ext4"
      disk_type      = "pd-standard"
      reclaim_policy = "RETAIN"
    }
  }
  
  container {
    # Use the predefined Code OSS image for MVP
    # Will be replaced with custom image once built
    image = "us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest"
    
    env = {
      MIDNIGHT_ENV        = var.environment
      PROOF_SERVICE_URL   = "http://localhost:8080"
      MIDNIGHT_NETWORK    = "testnet"
    }
  }
  
  encryption_key {
    kms_key = ""
  }
}

# Create a sample workstation (optional for MVP)
resource "google_workstations_workstation" "developer" {
  provider               = google-beta
  workstation_id         = "midnight-developer-1"
  workstation_config_id  = google_workstations_workstation_config.config.workstation_config_id
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = var.region
  project                = var.project_id
  
  display_name = "Midnight Developer Workstation 1"
  
  labels = {
    environment = var.environment
    project     = "midnight"
    type        = "developer"
  }
  
  annotations = {
    created_by = "terraform"
    purpose    = "mvp-demo"
  }
}