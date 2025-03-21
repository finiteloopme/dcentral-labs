# Create a config cluster
resource "google_container_cluster" "gke_cluster" {
  name = var.cluster_name
  location = var.region
  project = var.project_id

  # Autopilot cluster
  enable_autopilot = true

  network = var.network
  subnetwork = data.google_compute_subnetwork.gke-subnetwork.self_link

  deletion_protection = false
}

data "google_compute_subnetwork" "gke-subnetwork" {
  name   = "default"
  region = var.region
}