output "mock_server_ip" {
  description = "Internal IP address of mock server"
  value       = module.compute.mock_server_ip
}

output "tee_service_ip" {
  description = "Internal IP address of TEE service"
  value       = module.compute.tee_service_ip
}

output "vpc_name" {
  description = "Name of VPC network"
  value       = module.networking.vpc_name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = module.networking.subnet_name
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository URL"
  value       = module.iam.artifact_registry_repository
}

output "tee_service_account_email" {
  description = "Email of TEE service account"
  value       = module.iam.tee_service_account_email
}