# Workstations module outputs

output "cluster_id" {
  description = "Workstation cluster ID"
  value       = google_workstations_workstation_cluster.cluster.workstation_cluster_id
}

output "config_id" {
  description = "Workstation configuration ID"
  value       = google_workstations_workstation_config.config.workstation_config_id
}

output "workstation_ids" {
  description = "Map of workstation name to workstation ID"
  value = {
    for name, ws in google_workstations_workstation.workstations :
    name => ws.workstation_id
  }
}

output "workstation_urls" {
  description = "Map of workstation name to access URL"
  value = {
    for name, ws in google_workstations_workstation.workstations :
    name => "https://${var.region}.cloudworkstations.dev/e/${var.project_id}/${var.region}/${var.cluster_name}/${var.config_name}/${ws.workstation_id}"
  }
}
