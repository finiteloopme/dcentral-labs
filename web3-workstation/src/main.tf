// -----------------------------------------------------------------------------
// main.tf - Define the resources
// -----------------------------------------------------------------------------

provider "google" {
    project = var.project_id
    region  = var.region
}

// --- Enable Google Cloud APIs ---
resource "google_project_service" "enabled_apis" {
    count   = var.enable_apis ? length(var.apis_to_enable) : 0
    project = var.project_id
    service = var.apis_to_enable[count.index]

    // Disabling on destroy is generally not recommended for shared projects,
    // as other resources might depend on these APIs.
    // Set to true if you want Terraform to disable these APIs on destroy.
    disable_on_destroy = false
}

// --- Artifact Registry Repository ---
resource "google_artifact_registry_repository" "custom_images_repo" {
    project       = var.project_id
    location      = var.region // Artifact Registry locations can be multi-regional or regional
    repository_id = var.artifact_registry_repository_id
    description   = "Repository for custom Cloud Workstation images"
    format        = "DOCKER"
}

// Construct the full image URI
locals {
    custom_image_uri = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.custom_images_repo.repository_id}/${var.custom_image_name}:${var.custom_image_tag}"
}


// --- Workstation Cluster ---
resource "google_workstations_workstation_cluster" "default" {
    provider               = google-beta
    project                = var.project_id
    workstation_cluster_id = var.workstation_cluster_id
    network                = "projects/${var.project_id}/global/networks/${var.network_name}"
    subnetwork             = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.subnetwork_name}"
    location               = var.region // Cluster location must be a region

    // Optional: Configure private cluster settings if needed
    // private_cluster_config {
    //   enable_private_endpoint = true
    // }

    // Optional: Annotations and Labels
    // annotations = {
    //   "example-annotation" = "example-value"
    // }
    // labels = {
    //   "env" = "development"
    // }
}

// --- Workstation Configuration ---
resource "google_workstations_workstation_config" "custom_dev_env" {
    provider               = google-beta
    project                = var.project_id
    workstation_config_id  = var.workstation_config_id
    workstation_cluster_id = google_workstations_workstation_cluster.default.workstation_cluster_id
    location               = var.region

    // Machine Configuration
    host {
        gce_instance {
            machine_type = var.workstation_machine_type
            boot_disk_size_gb = 50
            # service_account = var.workstation_service_account_email 
        }
        # machine_type = var.workstation_machine_type
        // Optional: service_account, tags, confidential_compute, etc.
        # service_account = var.workstation_service_account_email
    }

    // Persistent Directories (for /home)
    persistent_directories {
        mount_path = "/home"
        gce_pd {
            size_gb  = var.workstation_disk_size_gb
            disk_type = var.workstation_disk_type
            // reclaim_policy = "DELETE" // or "RETAIN"
        }
    }

    // Container Configuration (using your custom image)
    container {
    image = local.custom_image_uri
    // Optional: command, args, env, working_dir, run_as_user
    }

    // Optional: Idle timeout and running timeout
    idle_timeout = "3600s" // 1 hour
    // running_timeout = "86400s" // 24 hours

    // Optional: Readiness checks
    // readiness_checks {
    //   path = "/_healthz" // Example path for a health check endpoint on port 80
    //   port = 80
    // }

    // Ensure cluster is created before the config
    depends_on = [google_workstations_workstation_cluster.default]
}


// --- Workstation Instance ---
// This will create a workstation instance when you run `terraform apply`.
// You might want to manage workstation instances manually or through other automation.
resource "google_workstations_workstation" "developer_workstation" {
    provider               = google-beta
    project                = var.project_id
    workstation_id         = var.workstation_id
    workstation_config_id  = google_workstations_workstation_config.custom_dev_env.workstation_config_id
    workstation_cluster_id = google_workstations_workstation_cluster.default.workstation_cluster_id
    location               = var.region

    // Optional: Labels and Annotations
    // labels = {
    //   "owner" = "developer-name"
    // }
    // annotations = {
    //   "purpose" = "ethereum-development"
    // }

    // Ensure configuration is created before the workstation instance
    depends_on = [google_workstations_workstation_config.custom_dev_env]
}

