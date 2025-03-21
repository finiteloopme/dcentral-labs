data "google_compute_network" "default-network" {
    name = var.network_id
    project = var.project_id
}