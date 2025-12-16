output "cluster_id" {
  description = "The ID of the workstation cluster"
  value       = google_workstations_workstation_cluster.cluster.id
}

output "config_id" {
  description = "The ID of the workstation configuration"
  value       = google_workstations_workstation_config.config.id
}

output "workstation_urls" {
  description = "URLs to access the workstations"
  value       = {
    for k, v in google_workstations_workstation.workstations : k => v.host
  }
}

output "cluster_name" {
  description = "The name of the workstation cluster"
  value       = google_workstations_workstation_cluster.cluster.name
}

output "config_name" {
  description = "The name of the workstation configuration"
  value       = google_workstations_workstation_config.config.name
}
