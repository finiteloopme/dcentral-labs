# Cloud Workstations module
# Creates a workstation cluster, configuration, and individual workstations

# Enable required APIs
resource "google_project_service" "workstations" {
  project            = var.project_id
  service            = "workstations.googleapis.com"
  disable_on_destroy = false
}

# Workstation Cluster
resource "google_workstations_workstation_cluster" "cluster" {
  provider               = google-beta
  project                = var.project_id
  workstation_cluster_id = var.cluster_name
  location               = var.region
  
  depends_on = [google_project_service.workstations]
}

# Workstation Configuration
resource "google_workstations_workstation_config" "config" {
  provider               = google-beta
  project                = var.project_id
  workstation_config_id  = var.config_name
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = var.region

  host {
    gce_instance {
      machine_type = var.machine_type
      boot_disk_size_gb = var.boot_disk_size_gb
      
      dynamic "accelerators" {
        for_each = var.gpu_type != null ? [1] : []
        content {
          type  = var.gpu_type
          count = var.gpu_count
        }
      }
    }
  }

  container {
    image = var.container_image
    
    dynamic "env" {
      for_each = var.env_vars
      content {
        name  = env.key
        value = env.value
      }
    }
  }

  persistent_directories {
    mount_path = "/home"
    gce_pd {
      size_gb        = var.home_disk_size_gb
      fs_type        = "ext4"
      reclaim_policy = "DELETE"
    }
  }

  idle_timeout    = var.idle_timeout
  running_timeout = var.running_timeout
}

# Individual Workstations
resource "google_workstations_workstation" "workstations" {
  for_each = var.workstations

  provider               = google-beta
  project                = var.project_id
  workstation_id         = "${var.cluster_name}-${each.key}"
  workstation_config_id  = google_workstations_workstation_config.config.workstation_config_id
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = var.region

  labels = {
    owner = replace(each.value, "@", "_at_")
  }
}

# IAM bindings for workstation users
resource "google_workstations_workstation_iam_member" "user_access" {
  for_each = var.workstations

  provider               = google-beta
  project                = var.project_id
  location               = var.region
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.config.workstation_config_id
  workstation_id         = google_workstations_workstation.workstations[each.key].workstation_id
  role                   = "roles/workstations.user"
  member                 = "user:${each.value}"
}

# Admin access to all workstations
resource "google_workstations_workstation_iam_member" "admin_access" {
  for_each = {
    for pair in setproduct(keys(var.workstations), var.workstation_admins) :
    "${pair[0]}-${pair[1]}" => {
      workstation = pair[0]
      admin       = pair[1]
    }
  }

  provider               = google-beta
  project                = var.project_id
  location               = var.region
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.config.workstation_config_id
  workstation_id         = google_workstations_workstation.workstations[each.value.workstation].workstation_id
  role                   = "roles/workstations.user"
  member                 = "user:${each.value.admin}"
}
