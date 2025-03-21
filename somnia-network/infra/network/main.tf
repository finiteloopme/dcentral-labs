data "google_compute_network" "default-network" {
    name = var.network_id
    project = var.project_id
}

data "google_compute_subnetwork" "gke-subnetwork" {
  name   = var.subnet_id
  project = var.project_id
  region = var.gcp_region
}