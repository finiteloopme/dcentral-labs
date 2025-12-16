# Midnight Services Module Outputs

output "node_url" {
  description = "URL of the Midnight node Cloud Run service"
  value       = google_cloud_run_v2_service.midnight_node.uri
}

output "proof_server_url" {
  description = "URL of the proof server Cloud Run service"
  value       = google_cloud_run_v2_service.proof_server.uri
}

output "indexer_url" {
  description = "URL of the indexer Cloud Run service"
  value       = google_cloud_run_v2_service.indexer.uri
}

output "node_name" {
  description = "Name of the Midnight node service"
  value       = google_cloud_run_v2_service.midnight_node.name
}

output "proof_server_name" {
  description = "Name of the proof server service"
  value       = google_cloud_run_v2_service.proof_server.name
}

output "indexer_name" {
  description = "Name of the indexer service"
  value       = google_cloud_run_v2_service.indexer.name
}
