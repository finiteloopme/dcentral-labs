output "lb_ip_address" {
  description = "External IP address of the load balancer"
  value       = module.networking.lb_ip_address
}

output "service_account_email" {
  description = "Workload service account email"
  value       = module.compute.service_account_email
}

output "mig_name" {
  description = "Name of the managed instance group"
  value       = module.compute.mig_name
}
