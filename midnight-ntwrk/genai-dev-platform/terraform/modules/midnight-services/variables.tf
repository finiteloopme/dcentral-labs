# Midnight Services Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name for service naming and labeling"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 1
}

variable "midnight_node_image" {
  description = "Docker image for Midnight node"
  type        = string
}

variable "proof_server_image" {
  description = "Docker image for proof server"
  type        = string
}

variable "indexer_image" {
  description = "Docker image for indexer"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "workstation_service_account" {
  description = "Service account email for workstations (for IAM)"
  type        = string
}
