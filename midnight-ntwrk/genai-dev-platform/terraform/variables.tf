variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for deployment"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for deployment"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (mvp, dev, prod)"
  type        = string
  default     = "mvp"
}

variable "workstation_config" {
  description = "Workstation configuration"
  type = object({
    machine_type            = string
    boot_disk_size_gb       = number
    persistent_disk_size_gb = number
    idle_timeout            = string
    running_timeout         = string
  })
  default = {
    machine_type            = "n2-standard-8"
    boot_disk_size_gb       = 50
    persistent_disk_size_gb = 200
    idle_timeout            = "1200s"
    running_timeout         = "14400s"
  }
}

variable "state_bucket_name" {
  description = "GCS bucket name for Terraform state"
  type        = string
  default     = "kunal-scratch/terraform/midnight-vibe-coding-state"
}

variable "state_bucket_location" {
  description = "Location for the state bucket"
  type        = string
  default     = "US"
}

variable "enable_custom_domain" {
  description = "Enable custom domain for workstation access"
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "Custom domain for workstation access (e.g., 'midnight-dev.example.com')"
  type        = string
  default     = ""
}

variable "custom_domain_ip" {
  description = "IP address for custom domain (leave empty to use NAT IP)"
  type        = string
  default     = ""
}

variable "additional_dns_records" {
  description = "Additional DNS records to create"
  type = list(object({
    name = string
    type = string
    ttl  = number
    data = list(string)
  }))
  default = []
}

variable "workstations" {
  description = "Map of workstations to create with their associated users"
  type        = map(object({
    user = string
  }))
  default     = {}
}

variable "cloudbuild_service_account" {
  description = "Cloud Build service account email"
  type        = string
  default     = ""
}