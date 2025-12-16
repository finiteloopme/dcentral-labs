# Input Variables for Midnight GenAI Development Platform

# ===========================================
# REQUIRED VARIABLES
# ===========================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the workstation cluster (used for labeling and routing)"
  type        = string
  default     = "midnight-dev"
}

variable "environment" {
  description = "Environment label (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ===========================================
# CONTAINER IMAGE
# ===========================================

variable "container_image" {
  description = "Full path to the dev container image in Artifact Registry"
  type        = string
}

# ===========================================
# WORKSTATION CONFIGURATION
# ===========================================

variable "machine_type" {
  description = "Machine type for workstations"
  type        = string
  default     = "e2-standard-4"
}

variable "persistent_disk_size_gb" {
  description = "Size of the persistent disk in GB"
  type        = number
  default     = 100
}

# ===========================================
# MIDNIGHT SERVICES CONFIGURATION
# ===========================================

variable "min_instances" {
  description = "Minimum number of Cloud Run instances (1 for always-on)"
  type        = number
  default     = 1
}

variable "midnight_node_image" {
  description = "Docker image for Midnight node"
  type        = string
  default     = "midnightntwrk/midnight-node:latest-main"
}

variable "proof_server_image" {
  description = "Docker image for proof server"
  type        = string
  default     = "midnightnetwork/proof-server:latest"
}

variable "indexer_image" {
  description = "Docker image for indexer"
  type        = string
  default     = "midnightntwrk/indexer-standalone:latest"
}
