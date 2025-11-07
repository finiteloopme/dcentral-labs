# Compute Module
# Creates virtual machines for mock server and TEE service

variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "mock_server_machine_type" {
  description = "Machine type for mock server"
  type        = string
}

variable "tee_service_machine_type" {
  description = "Machine type for TEE service"
  type        = string
}

variable "mock_server_ip" {
  description = "Internal IP for mock server"
  type        = string
}

variable "tee_service_ip" {
  description = "Internal IP for TEE service"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet to attach instances to"
  type        = string
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "google_compute_instance" "mock_server" {
  name         = "mock-server"
  machine_type = var.mock_server_machine_type
  zone         = "${var.gcp_region}-a"
  
  tags = [var.project_name]
  
  depends_on = [
    google_project_service.compute
  ]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    subnetwork = var.subnet_name
    network_ip = var.mock_server_ip
  }
  
  metadata = {
    ssh-keys = "user:${file(var.ssh_public_key_path)}"
  }
  
  metadata_startup_script = file("${path.root}/scripts/setup-mock-server.sh")
}

resource "google_compute_instance" "tee_service" {
  name         = "tee-service"
  machine_type = var.tee_service_machine_type
  zone         = "${var.gcp_region}-a"
  
  tags = [var.project_name]
  
  depends_on = [
    google_project_service.compute
  ]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    subnetwork = var.subnet_name
    network_ip = var.tee_service_ip
  }
  
  metadata = {
    ssh-keys = "user:${file(var.ssh_public_key_path)}"
    enable-confidential-computing = "true"
  }
  
  metadata_startup_script = file("${path.root}/scripts/setup-tee-service.sh")
}

# Outputs
output "mock_server_ip" {
  description = "Internal IP address of mock server"
  value       = google_compute_instance.mock_server.network_interface[0].network_ip
}

output "tee_service_ip" {
  description = "Internal IP address of TEE service"
  value       = google_compute_instance.tee_service.network_interface[0].network_ip
}

output "mock_server_name" {
  description = "Name of mock server instance"
  value       = google_compute_instance.mock_server.name
}

output "tee_service_name" {
  description = "Name of TEE service instance"
  value       = google_compute_instance.tee_service.name
}