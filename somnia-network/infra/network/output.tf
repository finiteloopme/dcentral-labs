output "network_link" {
  value = data.google_compute_network.default-network.self_link
}

output "subnetwork_link" {
  value = data.google_compute_subnetwork.gke-subnetwork.self_link
}