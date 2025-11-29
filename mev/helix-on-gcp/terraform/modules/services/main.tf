resource "google_project_service" "apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "servicenetworking.googleapis.com",
  ])

  project = var.project_id
  service = each.key

  disable_on_destroy = false
}
