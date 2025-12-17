# GKE Cluster Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for GKE Autopilot cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE Autopilot cluster"
  type        = string
  default     = "midnight-dev-gke"
}

variable "network" {
  description = "VPC network name"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "VPC subnetwork name"
  type        = string
  default     = "default"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
