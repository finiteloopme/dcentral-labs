output "workstation_cluster_id" {
  description = "The ID of the workstation cluster"
  value       = module.workstations.cluster_id
}

output "workstation_config_id" {
  description = "The ID of the workstation configuration"
  value       = module.workstations.config_id
}

output "workstation_url" {
  description = "URL to access the workstation"
  value       = module.workstations.workstation_url
}

output "registry_url" {
  description = "URL of the Artifact Registry"
  value       = module.registry.registry_url
}

output "network_name" {
  description = "Name of the VPC network"
  value       = module.networking.network_name
}

output "proof_service_url" {
  description = "URL of the proof service"
  value       = "http://${module.networking.nat_ip}:8080"
}
