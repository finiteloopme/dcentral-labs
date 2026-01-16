# Artifact Registry module
# Creates a Docker repository for container images

# Enable required APIs
resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Docker repository
resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.name
  description   = var.description
  format        = "DOCKER"

  cleanup_policy_dry_run = false
  
  dynamic "cleanup_policies" {
    for_each = var.cleanup_policy_enabled ? [1] : []
    content {
      id     = "delete-old-images"
      action = "DELETE"
      condition {
        older_than = var.cleanup_older_than
        tag_state  = "ANY"
      }
    }
  }

  depends_on = [google_project_service.artifactregistry]
}

# Grant Cloud Build service account access
resource "google_artifact_registry_repository_iam_member" "cloudbuild" {
  count = var.cloudbuild_sa_email != null ? 1 : 0

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.cloudbuild_sa_email}"
}

# Grant Workstations service account read access
resource "google_artifact_registry_repository_iam_member" "workstations" {
  count = var.workstations_sa_email != null ? 1 : 0

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.workstations_sa_email}"
}
