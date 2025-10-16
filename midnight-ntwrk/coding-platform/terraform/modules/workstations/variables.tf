variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "registry_url" {
  description = "Artifact Registry URL"
  type        = string
}

variable "workstation_config" {
  description = "Workstation configuration"
  type = object({
    machine_type            = string
    boot_disk_size_gb      = number
    persistent_disk_size_gb = number
    idle_timeout           = string
    running_timeout        = string
  })
}