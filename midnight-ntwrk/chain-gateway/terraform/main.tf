terraform {
  backend "gcs" {
    bucket  = "your-gcs-bucket-name"
    prefix  = "terraform/state"
  }
}

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  # Don't disable the service on destroy
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"

  # Don't disable the service on destroy
  disable_on_destroy = false
}

resource "google_container_cluster" "default" {
  depends_on = [google_project_service.container]

  name     = var.cluster_name
  location = var.region

  # Autopilot configuration
  enable_autopilot = true
  deletion_protection = false

  lifecycle {
    ignore_changes = [
      node_pool,
      node_config,
    ]
  }
}
