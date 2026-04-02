output "service_account_email" {
  description = "Email of the workload service account"
  value       = google_service_account.workload.email
}

output "instance_group" {
  description = "Self link of the managed instance group"
  value       = google_compute_instance_group_manager.mig.instance_group
}

output "mig_name" {
  description = "Name of the managed instance group"
  value       = google_compute_instance_group_manager.mig.name
}
