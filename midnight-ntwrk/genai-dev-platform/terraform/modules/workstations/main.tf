# Cloud Workstations Module
#
# Creates a workstation cluster, configuration, and optionally workstations.

# ==============================================================================
# WORKSTATION SERVICE ACCOUNT
# ==============================================================================

locals {
  vertex_project = var.vertex_ai_project != "" ? var.vertex_ai_project : var.project_id

  # All users who need to act as the workstation service account
  all_workstation_users = concat(
    [for email in values(var.workstations) : "user:${email}"],
    [for email in var.workstation_admins : "user:${email}"]
  )
}

# Service account for workstation VMs
resource "google_service_account" "workstation_sa" {
  project      = var.project_id
  account_id   = "${var.cluster_name}-dev-sa"
  display_name = "Workstation Dev SA for ${var.cluster_name}"
  description  = "Service account used by Cloud Workstation VMs to access GCP services"
}

# Grant roles to workstation SA (main project)
resource "google_project_iam_member" "ws_sa_roles" {
  for_each = toset(var.sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.workstation_sa.email}"
}

# Vertex AI - User access (may be in different project)
resource "google_project_iam_member" "ws_sa_vertex" {
  project = local.vertex_project
  role    = var.sa_vertex_role
  member  = "serviceAccount:${google_service_account.workstation_sa.email}"
}

# ==============================================================================
# SERVICE ACCOUNT USER ACCESS
# ==============================================================================
# Allow workstation users to act as the workstation service account.
# Required for generating access tokens when connecting to workstations.

resource "google_service_account_iam_binding" "workstation_users" {
  service_account_id = google_service_account.workstation_sa.name
  role               = "roles/iam.serviceAccountUser"
  members            = local.all_workstation_users
}

# ==============================================================================
# WORKSTATION CLUSTER
# ==============================================================================

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
      service_account              = google_service_account.workstation_sa.email
      service_account_scopes       = ["https://www.googleapis.com/auth/cloud-platform"]
      
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

  # Idle timeout (12 hours)
  idle_timeout = "43200s"

  # Running timeout (24 hours)
  running_timeout = "86400s"
}

# ==============================================================================
# WORKSTATION INSTANCES
# ==============================================================================

resource "google_workstations_workstation" "instances" {
  for_each = var.workstations

  provider               = google-beta
  project                = var.project_id
  location               = var.region
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.config.workstation_config_id
  workstation_id         = "midnight-workstation-${each.key}"
  display_name           = "${title(each.key)}'s Midnight Workstation"

  labels = merge(var.labels, {
    owner = each.key
  })

  # Auto-start when user connects via browser/gcloud
  annotations = {
    "workstations.googleapis.com/start-on-connect" = "true"
  }

  depends_on = [google_workstations_workstation_config.config]
}

# ==============================================================================
# WORKSTATION IAM - OWNER ACCESS
# ==============================================================================

resource "google_workstations_workstation_iam_member" "owner_access" {
  for_each = var.workstations

  provider               = google-beta
  project                = var.project_id
  location               = var.region
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.config.workstation_config_id
  workstation_id         = google_workstations_workstation.instances[each.key].workstation_id

  role   = "roles/workstations.user"
  member = "user:${each.value}"
}

# ==============================================================================
# WORKSTATION IAM - ADMIN ACCESS
# ==============================================================================

resource "google_workstations_workstation_iam_member" "admin_access" {
  for_each = {
    for pair in setproduct(keys(var.workstations), var.workstation_admins) :
    "${pair[0]}-${replace(pair[1], "@", "_at_")}" => {
      workstation = pair[0]
      admin       = pair[1]
    }
    if length(var.workstation_admins) > 0 && length(var.workstations) > 0
  }

  provider               = google-beta
  project                = var.project_id
  location               = var.region
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.config.workstation_config_id
  workstation_id         = google_workstations_workstation.instances[each.value.workstation].workstation_id

  role   = "roles/workstations.user"
  member = "user:${each.value.admin}"
}
