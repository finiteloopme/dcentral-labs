# GKE Cluster Module Outputs

output "cluster_name" {
  description = "Name of the GKE Autopilot cluster"
  value       = google_container_cluster.midnight_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for the GKE cluster"
  value       = google_container_cluster.midnight_cluster.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate for the GKE cluster (base64 encoded)"
  value       = google_container_cluster.midnight_cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.midnight_cluster.location
}

output "kubectl_config_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.midnight_cluster.name} --region ${var.region} --project ${var.project_id}"
}

output "nat_gateway_name" {
  description = "Name of the Cloud NAT gateway for internet egress"
  value       = google_compute_router_nat.midnight_nat.name
}
