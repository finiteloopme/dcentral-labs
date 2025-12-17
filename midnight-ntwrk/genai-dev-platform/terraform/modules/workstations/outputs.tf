# Cloud Workstations Module Outputs

output "cluster_name" {
  description = "Name of the workstation cluster"
  value       = google_workstations_workstation_cluster.cluster.workstation_cluster_id
}

output "config_name" {
  description = "Name of the workstation configuration"
  value       = google_workstations_workstation_config.config.workstation_config_id
}

output "cluster_id" {
  description = "Full resource ID of the workstation cluster"
  value       = google_workstations_workstation_cluster.cluster.id
}

output "config_id" {
  description = "Full resource ID of the workstation configuration"
  value       = google_workstations_workstation_config.config.id
}


