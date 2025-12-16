output "workstation_cluster_id" {
  description = "The ID of the workstation cluster"
  value       = module.workstations.cluster_id
}

output "workstation_config_id" {
  description = "The ID of the workstation configuration"
  value       = module.workstations.config_id
}

output "workstation_urls" {
  description = "URLs to access the workstations"
  value       = module.workstations.workstation_urls
}

output "registry_url" {
  description = "URL of the Artifact Registry"
  value       = module.registry.registry_url
}

output "network_name" {
  description = "Name of the VPC network"
  value       = module.networking.network_name
}

output "dns_name_servers" {
  description = "DNS name servers (update your domain registrar with these)"
  value       = var.enable_custom_domain ? module.dns.dns_name_servers : []
}

output "custom_domain_urls" {
  description = "URLs for accessing workstations via custom domain"
  value       = var.enable_custom_domain ? module.dns.workstation_urls : {}
}
