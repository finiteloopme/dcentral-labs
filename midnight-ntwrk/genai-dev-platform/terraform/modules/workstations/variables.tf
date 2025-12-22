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

variable "workstations" {
  description = "Map of workstation name to user email"
  type        = map(string)
  default     = {}
}

variable "workstation_admins" {
  description = "List of admin emails with access to all workstations"
  type        = list(string)
  default     = []
}

variable "vertex_ai_project" {
  description = "Project ID for Vertex AI access (defaults to project_id if empty)"
  type        = string
  default     = ""
}

variable "sa_roles" {
  description = "IAM roles to grant to the workstation service account (on main project)"
  type        = list(string)
  default = [
    "roles/artifactregistry.reader",
    "roles/container.developer",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
  ]
}

variable "sa_vertex_role" {
  description = "IAM role for Vertex AI access (applied to vertex_ai_project or project_id)"
  type        = string
  default     = "roles/aiplatform.user"
}
