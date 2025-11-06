output "mock_server_ip" {
  description = "Internal IP address of mock server"
  value       = google_compute_instance.mock_server.network_interface[0].network_ip
}

output "tee_service_ip" {
  description = "Internal IP address of TEE service"
  value       = google_compute_instance.tee_service.network_interface[0].network_ip
}

output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository URL"
  value       = "${google_artifact_registry_repository.tee_images.location}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.tee_images.repository_id}"
}

output "tee_service_account_email" {
  description = "Email of the TEE service account"
  value       = google_service_account.tee_service_account.email
}