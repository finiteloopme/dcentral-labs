resource "google_project_service" "compute" {
  project = var.gcp_project
  service = "compute.googleapis.com"
}

resource "google_project_service" "artifact_registry" {
  project = var.gcp_project
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "secret_manager" {
  project = var.gcp_project
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "iam" {
  project = var.gcp_project
  service = "iam.googleapis.com"
}

resource "google_project_service" "cloud_resource_manager" {
  project = var.gcp_project
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "container" {
  project = var.gcp_project
  service = "container.googleapis.com"
}

resource "google_project_service" "logging" {
  project = var.gcp_project
  service = "logging.googleapis.com"
}