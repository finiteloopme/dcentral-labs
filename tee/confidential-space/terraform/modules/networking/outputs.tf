output "lb_ip_address" {
  description = "Reserved external IP address for the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "lb_ip_self_link" {
  description = "Self link of the reserved IP"
  value       = google_compute_global_address.lb_ip.self_link
}

output "network_tag" {
  description = "Network tag applied to instances"
  value       = var.app_name
}
