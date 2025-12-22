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

output "workstation_instances" {
  description = "Map of workstation names to their details"
  value = {
    for name, ws in google_workstations_workstation.instances : name => {
      id            = ws.workstation_id
      display_name  = ws.display_name
      owner         = var.workstations[name]
      ide_url       = "https://80-${ws.host}"
      console_url   = "https://console.cloud.google.com/workstations/workstation/${var.region}/${google_workstations_workstation_cluster.cluster.workstation_cluster_id}/${google_workstations_workstation_config.config.workstation_config_id}/${ws.workstation_id}?project=${var.project_id}"
      start_command = "gcloud workstations start ${ws.workstation_id} --cluster=${google_workstations_workstation_cluster.cluster.workstation_cluster_id} --config=${google_workstations_workstation_config.config.workstation_config_id} --region=${var.region} --project=${var.project_id}"
    }
  }
}

output "workstation_urls" {
  description = "Direct IDE URLs for all workstations"
  value = {
    for name, ws in google_workstations_workstation.instances : name => "https://80-${ws.host}"
  }
}

output "service_account_email" {
  description = "Service account used by workstation VMs"
  value       = google_service_account.workstation_sa.email
}
