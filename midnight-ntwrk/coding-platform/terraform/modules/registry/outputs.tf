output "registry_id" {
  description = "The ID of the Artifact Registry repository"
  value       = google_artifact_registry_repository.workstation_images.id
}

output "registry_url" {
  description = "The URL of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.workstation_images.repository_id}"
}

output "registry_name" {
  description = "The name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.workstation_images.name
}