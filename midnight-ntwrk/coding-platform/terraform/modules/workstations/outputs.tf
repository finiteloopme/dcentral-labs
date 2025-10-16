output "cluster_id" {
  description = "The ID of the workstation cluster"
  value       = google_workstations_workstation_cluster.cluster.id
}

output "config_id" {
  description = "The ID of the workstation configuration"
  value       = google_workstations_workstation_config.config.id
}

output "workstation_url" {
  description = "URL to access the workstation"
  value       = google_workstations_workstation.developer.host
}

output "cluster_name" {
  description = "The name of the workstation cluster"
  value       = google_workstations_workstation_cluster.cluster.name
}

output "config_name" {
  description = "The name of the workstation configuration"
  value       = google_workstations_workstation_config.config.name
}