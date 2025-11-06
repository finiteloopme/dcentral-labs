resource "google_artifact_registry_repository" "tee_images" {
  location      = var.gcp_region
  repository_id = "${var.project_name}-tee-images"
  description   = "TEE container images"
  format        = "DOCKER"
  
  depends_on = [
    google_project_service.artifact_registry
  ]
}

resource "google_iam_workload_identity_pool" "tee_pool" {
  workload_identity_pool_id = "${var.project_name}-tee-pool"
  display_name              = "TEE Workload Identity Pool"
}

resource "google_iam_workload_identity_pool_provider" "tee_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.tee_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.project_name}-tee-provider"
  display_name                       = "TEE Provider"
  
  attribute_condition = var.tee_image_digest != "" ? "attribute.repository/uri == '${google_artifact_registry_repository.tee_images.location}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.tee_images.repository_id}/tee-service@${var.tee_image_digest}'" : ""
  oidc {
    issuer_uri = "https://container.googleapis.com/v1/projects/${var.gcp_project}/locations/${var.gcp_region}/repositories/${google_artifact_registry_repository.tee_images.repository_id}"
  }
}

resource "google_service_account" "tee_service_account" {
  account_id   = "${var.project_name}-tee-service"
  display_name = "TEE Service Account"
}

resource "google_service_account_iam_binding" "tee_wi_binding" {
  service_account_id = google_service_account.tee_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tee_pool.name}/attribute.repository/uri/*"
  ]
}

resource "google_project_iam_member" "tee_secret_access" {
  project = var.gcp_project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.tee_service_account.email}"
  
  depends_on = [
    google_project_service.secret_manager
  ]
}

resource "google_project_iam_member" "tee_logging" {
  project = var.gcp_project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.tee_service_account.email}"
  
  depends_on = [
    google_project_service.logging
  ]
}