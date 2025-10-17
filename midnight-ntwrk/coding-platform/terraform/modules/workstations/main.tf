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
  
  # Note: private_cluster_config removed to match existing cluster
  # If you need private endpoint in the future, you'll need to recreate the cluster
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
      machine_type                 = var.workstation_config.machine_type
      boot_disk_size_gb            = var.workstation_config.boot_disk_size_gb
      disable_public_ip_addresses  = false
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
      MIDNIGHT_ENV             = var.environment
      MIDNIGHT_NETWORK         = "testnet"
      PROOF_SERVICE_MODE       = var.proof_service_config.mode
      PROOF_SERVICE_URL        = var.proof_service_config.external_url
      PROOF_SERVICE_PORT       = tostring(var.proof_service_config.port)
      PROOF_SERVICE_HOST       = var.proof_service_config.host
      PROOF_SERVICE_LOG_LEVEL  = var.proof_service_config.log_level
      PROOF_SERVICE_THREADS    = tostring(var.proof_service_config.threads)
      PROOF_SERVICE_CACHE_SIZE = tostring(var.proof_service_config.cache_size)
    }
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
