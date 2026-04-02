# -----------------------------------------------------------------------------
# Compute module
# - Service account for Confidential Space workload
# - Instance template (Confidential VM with CS image)
# - Managed Instance Group (MIG)
# - Autoscaler
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Service Account
# ---------------------------------------------------------------------------
resource "google_service_account" "workload" {
  account_id   = "${var.app_name}-sa"
  display_name = "Confidential Space workload SA for ${var.app_name}"
  project      = var.project_id
}

# Required roles for Confidential Space workloads
resource "google_project_iam_member" "workload_user" {
  project = var.project_id
  role    = "roles/confidentialcomputing.workloadUser"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

resource "google_project_iam_member" "ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

# ---------------------------------------------------------------------------
# Instance Template
# ---------------------------------------------------------------------------
resource "google_compute_instance_template" "cs_workload" {
  name_prefix  = "${var.app_name}-"
  project      = var.project_id
  region       = var.region
  machine_type = var.machine_type
  tags         = [var.network_tag]

  # Confidential Computing configuration
  confidential_instance_config {
    confidential_instance_type = var.confidential_type
  }

  scheduling {
    # N2D (SEV) supports MIGRATE; C3 (TDX) requires TERMINATE
    on_host_maintenance = var.confidential_type == "SEV" ? "MIGRATE" : "TERMINATE"
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  disk {
    source_image = "projects/confidential-space-images/global/images/family/${var.image_family}"
    auto_delete  = true
    boot         = true
    disk_type    = "pd-balanced"
    disk_size_gb = 20
  }

  network_interface {
    network = "default"

    access_config {
      # Ephemeral external IP for outbound connectivity (pulling container image)
    }
  }

  metadata = {
    "tee-image-reference"        = var.docker_image
    "tee-restart-policy"         = "Always"
    "tee-container-log-redirect" = "cloud_logging"
    "tee-env-ENVIRONMENT"        = var.environment
  }

  service_account {
    email  = google_service_account.workload.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Managed Instance Group (MIG)
# ---------------------------------------------------------------------------
resource "google_compute_instance_group_manager" "mig" {
  name               = "${var.app_name}-mig"
  project            = var.project_id
  zone               = var.zone
  base_instance_name = var.app_name

  version {
    instance_template = google_compute_instance_template.cs_workload.self_link_unique
  }

  target_size = var.mig_min_replicas

  named_port {
    name = "http"
    port = var.app_port
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 1
    max_unavailable_fixed          = 0
  }

  auto_healing_policies {
    health_check      = var.health_check_id
    initial_delay_sec = 300 # 5 min: CS image needs time to boot, pull, and start container
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Autoscaler
# ---------------------------------------------------------------------------
resource "google_compute_autoscaler" "mig" {
  name    = "${var.app_name}-autoscaler"
  project = var.project_id
  zone    = var.zone
  target  = google_compute_instance_group_manager.mig.id

  autoscaling_policy {
    min_replicas    = var.mig_min_replicas
    max_replicas    = var.mig_max_replicas
    cooldown_period = 120

    cpu_utilization {
      target = 0.6
    }
  }
}
