# Cloud Workstations Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the workstation cluster"
  type        = string
}

variable "container_image" {
  description = "Container image for workstations"
  type        = string
}

variable "machine_type" {
  description = "Machine type for workstations"
  type        = string
  default     = "e2-standard-4"
}

variable "persistent_disk_size_gb" {
  description = "Size of persistent disk in GB"
  type        = number
  default     = 100
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "service_urls" {
  description = "Map of service names to URLs for environment injection"
  type        = map(string)
  default     = {}
}
