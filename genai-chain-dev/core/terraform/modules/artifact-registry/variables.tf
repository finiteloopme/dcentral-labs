# Artifact Registry module variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "name" {
  description = "Repository name"
  type        = string
}

variable "description" {
  description = "Repository description"
  type        = string
  default     = "Container images for development platform"
}

variable "cleanup_policy_enabled" {
  description = "Enable cleanup policy for old images"
  type        = bool
  default     = true
}

variable "cleanup_older_than" {
  description = "Delete images older than this duration (e.g., '2592000s' for 30 days)"
  type        = string
  default     = "2592000s"
}

variable "cloudbuild_sa_email" {
  description = "Cloud Build service account email (for write access)"
  type        = string
  default     = null
}

variable "workstations_sa_email" {
  description = "Workstations service account email (for read access)"
  type        = string
  default     = null
}
