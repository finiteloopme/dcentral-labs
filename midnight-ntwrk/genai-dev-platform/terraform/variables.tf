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
# GKE MIDNIGHT SERVICES CONFIGURATION
# ===========================================

variable "gke_cluster_name" {
  description = "Name of the GKE Autopilot cluster for Midnight services"
  type        = string
  default     = "midnight-dev-gke"
}

variable "chain_environment" {
  description = "Chain environment: standalone, testnet, mainnet"
  type        = string
  default     = "standalone"
}

variable "midnight_node_image" {
  description = "Docker image for Midnight node"
  type        = string
  default     = "midnightnetwork/midnight-node:0.12.1"
}

variable "proof_server_image" {
  description = "Docker image for proof server"
  type        = string
  default     = "midnightnetwork/proof-server:4.0.0"
}

variable "indexer_image" {
  description = "Docker image for indexer"
  type        = string
  default     = "midnightntwrk/indexer-standalone:2.1.4"
}

variable "indexer_secret" {
  description = "32-byte hex secret for indexer encryption. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
}

# ===========================================
# CLOUD BUILD CONFIGURATION
# ===========================================

variable "cloudbuild_sa_email" {
  description = "Email of the Cloud Build service account (user-managed)"
  type        = string
  default     = ""
}
