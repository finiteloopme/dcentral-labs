# Terraform outputs

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = module.artifact_registry.repository_url
}

output "container_image" {
  description = "Full container image path"
  value       = local.container_image
}

output "workstation_cluster_id" {
  description = "Workstation cluster ID"
  value       = module.workstations.cluster_id
}

output "workstation_config_id" {
  description = "Workstation configuration ID"
  value       = module.workstations.config_id
}

output "workstation_urls" {
  description = "URLs for each workstation"
  value       = module.workstations.workstation_urls
}

output "workstation_connect_info" {
  description = "Connection information for workstations"
  value = {
    cluster = local.cluster_name
    config  = local.config_name
    region  = var.region
    project = var.project_id
  }
}
