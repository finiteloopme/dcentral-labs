# Artifact Registry Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
