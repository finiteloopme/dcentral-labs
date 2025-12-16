# Cloud Workstations Module
#
# Creates a workstation cluster, configuration, and optionally workstations.

# Workstation Cluster
resource "google_workstations_workstation_cluster" "cluster" {
  provider = google-beta

  project                = var.project_id
  location               = var.region
  workstation_cluster_id = var.cluster_name
  display_name           = "Midnight Dev Cluster - ${var.cluster_name}"
  labels                 = var.labels

  # Use default VPC
  network    = "projects/${var.project_id}/global/networks/default"
  subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/default"
}

# Workstation Configuration
resource "google_workstations_workstation_config" "config" {
  provider = google-beta

  project                = var.project_id
  location               = var.region
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  workstation_config_id  = "${var.cluster_name}-config"
  display_name           = "Midnight Dev Configuration"
  labels                 = var.labels

  # Machine configuration
  host {
    gce_instance {
      machine_type                 = var.machine_type
      boot_disk_size_gb            = 50
      disable_public_ip_addresses  = false
      
      # Confidential compute not needed for dev
      confidential_instance_config {
        enable_confidential_compute = false
      }
    }
  }

  # Persistent home directory
  persistent_directories {
    mount_path = "/home"
    gce_pd {
      size_gb         = var.persistent_disk_size_gb
      fs_type         = "ext4"
      disk_type       = "pd-balanced"
      reclaim_policy  = "DELETE"
    }
  }

  # Container configuration
  container {
    image = var.container_image

    # Inject Cloud Run service URLs
    env = merge(
      var.service_urls,
      {
        CLUSTER_NAME = var.cluster_name
      }
    )
  }

  # Idle timeout (4 hours)
  idle_timeout = "14400s"

  # Running timeout (12 hours)
  running_timeout = "43200s"
}

# Service account for workstations
data "google_compute_default_service_account" "default" {
  project = var.project_id
}
