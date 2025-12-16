# Terraform Outputs

output "artifact_registry_url" {
  description = "URL of the Artifact Registry repository"
  value       = module.artifact_registry.repository_url
}

output "workstation_cluster_name" {
  description = "Name of the Cloud Workstation cluster"
  value       = module.workstations.cluster_name
}

output "workstation_config_name" {
  description = "Name of the Cloud Workstation configuration"
  value       = module.workstations.config_name
}

output "midnight_node_url" {
  description = "URL of the Midnight node Cloud Run service"
  value       = module.midnight_services.node_url
}

output "proof_server_url" {
  description = "URL of the proof server Cloud Run service"
  value       = module.midnight_services.proof_server_url
}

output "indexer_url" {
  description = "URL of the indexer Cloud Run service"
  value       = module.midnight_services.indexer_url
}

output "service_urls" {
  description = "All service URLs for environment configuration"
  value = {
    midnight_node = module.midnight_services.node_url
    proof_server  = module.midnight_services.proof_server_url
    indexer       = module.midnight_services.indexer_url
  }
}
