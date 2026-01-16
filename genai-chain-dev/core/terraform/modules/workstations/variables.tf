# Workstations module variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Workstation cluster name"
  type        = string
}

variable "config_name" {
  description = "Workstation configuration name"
  type        = string
}

variable "container_image" {
  description = "Container image for workstations"
  type        = string
}

variable "machine_type" {
  description = "GCE machine type for workstations"
  type        = string
  default     = "e2-standard-4"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "home_disk_size_gb" {
  description = "Home directory persistent disk size in GB"
  type        = number
  default     = 50
}

variable "gpu_type" {
  description = "GPU type (null for no GPU)"
  type        = string
  default     = null
}

variable "gpu_count" {
  description = "Number of GPUs"
  type        = number
  default     = 1
}

variable "idle_timeout" {
  description = "Idle timeout before workstation stops (e.g., '43200s' for 12 hours)"
  type        = string
  default     = "43200s"
}

variable "running_timeout" {
  description = "Max running time before workstation stops (e.g., '86400s' for 24 hours)"
  type        = string
  default     = "86400s"
}

variable "workstations" {
  description = "Map of workstation name to owner email"
  type        = map(string)
  default     = {}
}

variable "workstation_admins" {
  description = "List of admin emails with access to all workstations"
  type        = list(string)
  default     = []
}

variable "env_vars" {
  description = "Environment variables to set in the container"
  type        = map(string)
  default     = {}
}
