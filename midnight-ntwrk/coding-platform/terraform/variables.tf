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
  default     = ""
}

variable "state_bucket_location" {
  description = "Location for the state bucket"
  type        = string
  default     = "US"
}

variable "proof_service_config" {
  description = "Proof service configuration"
  type = object({
    mode         = string # "local" or "external"
    external_url = string # URL for external service
    port         = number # Port for local service
    host         = string # Host for local service
    log_level    = string # Logging level
    threads      = number # Number of threads for local service
    cache_size   = number # Cache size for local service
    api_key      = string # API key for external service (if required)
  })
  default = {
    mode         = "local"
    external_url = ""
    port         = 8080
    host         = "0.0.0.0"
    log_level    = "info"
    threads      = 4
    cache_size   = 1000
    api_key      = ""
  }
}

variable "proof_service_mode" {
  description = "Proof service mode override (local or external)"
  type        = string
  default     = ""
}

variable "proof_service_url" {
  description = "Proof service URL override"
  type        = string
  default     = ""
}

variable "proof_service_api_key" {
  description = "Proof service API key override"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_real_proof_server" {
  description = "Use real Midnight proof server instead of mock"
  type        = bool
  default     = true
}
