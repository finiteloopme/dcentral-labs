# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "workstation_images" {
  location      = var.region
  repository_id = "midnight-${var.environment}-workstation-images"
  description   = "Docker repository for Midnight workstation images"
  format        = "DOCKER"
  project       = var.project_id

  docker_config {
    immutable_tags = false
  }

  cleanup_policies {
    id     = "keep-recent-versions"
    action = "KEEP"

    condition {
      tag_state  = "TAGGED"
      older_than = "2419200s" # 28 days
    }
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "604800s" # 7 days
    }
  }
}

# IAM policy for the registry
resource "google_artifact_registry_repository_iam_member" "workstation_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.workstation_images.location
  repository = google_artifact_registry_repository.workstation_images.name
  role       = "roles/artifactregistry.reader"
  member     = "allUsers"
}
