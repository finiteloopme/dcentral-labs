# Artifact Registry Module
#
# Creates a Docker repository for storing the dev container image.

resource "google_artifact_registry_repository" "dev_container" {
  provider = google-beta

  project       = var.project_id
  location      = var.region
  repository_id = "midnight-images"
  description   = "Docker repository for Midnight SDK and platform images"
  format        = "DOCKER"
  labels        = var.labels

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
}

# Allow Cloud Build to push images
resource "google_artifact_registry_repository_iam_member" "cloudbuild_writer" {
  provider = google-beta

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.dev_container.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Allow workstations to pull images
resource "google_artifact_registry_repository_iam_member" "workstations_reader" {
  provider = google-beta

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.dev_container.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-workstations.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}
