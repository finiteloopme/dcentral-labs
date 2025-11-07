# Networking Module
# Creates VPC, subnet, and firewall rules

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

variable "subnet_cidr" {
  description = "CIDR range for subnet"
  type        = string
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  
  depends_on = [
    google_project_service.compute
  ]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.vpc.id
  
  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "8545", "9944"]
  }
  
  source_tags = [var.project_name]
  target_tags = [var.project_name]
}

# Outputs
output "vpc_name" {
  description = "Name of VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}