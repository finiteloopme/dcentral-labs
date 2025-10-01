
variable "project_id" {
  description = "The project ID to host the GKE cluster in."
  type        = string
}

variable "region" {
  description = "The region to host the GKE cluster in."
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "autopilot-cluster"
}

variable "alloydb_admin_password" {
  description = "The password for the initial AlloyDB cluster administrator."
  type        = string
  sensitive   = true
  default     = null
}
