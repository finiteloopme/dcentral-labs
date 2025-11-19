# Create a dedicated service account for workstations
resource "google_service_account" "workstation" {
  account_id   = "midnight-workstation-${var.environment}"
  display_name = "Midnight Workstation Service Account"
  description  = "Service account for Midnight development workstations with Vertex AI access"
  project      = var.project_id
}

# Grant necessary IAM roles to the service account
resource "google_project_iam_member" "workstation_vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.workstation.email}"
}

resource "google_project_iam_member" "workstation_service_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.workstation.email}"
}

resource "google_project_iam_member" "workstation_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workstation.email}"
}

resource "google_project_iam_member" "workstation_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.workstation.email}"
}

resource "google_project_iam_member" "workstation_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.workstation.email}"
}

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

      # Use the dedicated service account
      service_account = google_service_account.workstation.email

      # Add OAuth scopes for Vertex AI and other Google Cloud services
      service_account_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/cloud-platform.read-only",
        "https://www.googleapis.com/auth/compute",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring.write",
        "https://www.googleapis.com/auth/devstorage.read_write",
      ]

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
    # Use our custom Midnight workstation image
    image = "${var.region}-docker.pkg.dev/${var.project_id}/midnight-${var.environment}-workstation-images/midnight-workstation:latest"

    env = {
      MIDNIGHT_ENV             = var.environment
      MIDNIGHT_NETWORK         = "testnet"
      # Mock proof server runs automatically on port 8081
      CLOUD_WORKSTATIONS_CONFIG = "true"
      # Pass the project ID for gcloud configuration
      GCP_PROJECT_ID           = var.project_id
      GOOGLE_CLOUD_PROJECT     = var.project_id
      # Vertex AI configuration
      GOOGLE_VERTEX_PROJECT     = var.project_id
      GOOGLE_VERTEX_LOCATION    = var.region
      # Tell gcloud to use metadata service for credentials
      GCE_METADATA_HOST        = "metadata.google.internal"
    }
  }

  depends_on = [
    google_service_account.workstation,
    google_project_iam_member.workstation_vertex_ai_user,
    google_project_iam_member.workstation_service_usage,
    google_project_iam_member.workstation_log_writer,
    google_project_iam_member.workstation_monitoring_writer,
    google_project_iam_member.workstation_storage_viewer
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Create workstations
resource "google_workstations_workstation" "workstations" {
  for_each = var.workstations
  
  provider               = google-beta
  workstation_id         = "midnight-${each.key}"
  workstation_config_id  = google_workstations_workstation_config.config.workstation_config_id
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = var.region
  project                = var.project_id

  display_name = "Midnight Workstation - ${each.value.user}"

  labels = {
    environment = var.environment
    project     = "midnight"
    user        = replace(each.value.user, "@", "_")
    type        = "developer"
  }

  lifecycle {
    create_before_destroy = true
  }
}