output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.default.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster."
  value       = google_container_cluster.default.endpoint
}

