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
    machine_type        = string
    boot_disk_size_gb   = number
    persistent_disk_size_gb = number
    idle_timeout        = string
    running_timeout     = string
  })
  default = {
    machine_type        = "e2-standard-4"
    boot_disk_size_gb   = 50
    persistent_disk_size_gb = 200
    idle_timeout        = "1200s"
    running_timeout     = "14400s"
  }
}

variable "state_bucket_name" {
  description = "GCS bucket name for Terraform state"
  type        = string
  default     = ""
}

variable "state_bucket_location" {
  description = "Location for the state bucket"
  type        = string
  default     = "US"
}

variable "proof_service_url" {
  description = "External proof service URL (optional, uses local mock if not set)"
  type        = string
  default     = ""
}

variable "proof_service_config" {
  description = "Proof service configuration"
  type = object({
    enabled      = bool
    url          = string
    port         = number
    api_key      = string
  })
  default = {
    enabled      = false
    url          = ""
    port         = 8080
    api_key      = ""
  }
}