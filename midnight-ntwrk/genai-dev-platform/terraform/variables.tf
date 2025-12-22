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
  default     = "n2-standard-8"
}

variable "persistent_disk_size_gb" {
  description = "Size of the persistent disk in GB"
  type        = number
  default     = 100
}

variable "workstations" {
  description = "Map of workstation name to user email. Creates midnight-workstation-<name> for each entry."
  type        = map(string)
  default     = {}
}

variable "workstation_admins" {
  description = "List of admin emails with access to all workstations"
  type        = list(string)
  default     = []
}

variable "vertex_ai_project" {
  description = "Project ID for Vertex AI access (leave empty to use main project_id)"
  type        = string
  default     = ""
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
  default     = "midnightntwrk/midnight-node:0.18.0"
}

variable "proof_server_image" {
  description = "Docker image for proof server"
  type        = string
  default     = "midnightnetwork/proof-server:6.1.0-alpha.6"
}

variable "indexer_image" {
  description = "Docker image for indexer"
  type        = string
  default     = "midnightntwrk/indexer-standalone:3.0.0-alpha.20"
}

variable "indexer_secret" {
  description = "32-byte hex secret for indexer encryption. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
}

# ===========================================
# WORKSTATION SERVICE ACCOUNT ROLES
# ===========================================

variable "workstation_sa_roles" {
  description = "IAM roles to grant to the workstation service account"
  type        = list(string)
  default = [
    "roles/artifactregistry.reader",  # Pull container images
    "roles/container.developer",      # kubectl access to GKE
    "roles/logging.viewer",           # View logs
    "roles/monitoring.viewer",        # View metrics
  ]
}

variable "workstation_sa_vertex_role" {
  description = "IAM role for Vertex AI access (applied to vertex_ai_project or project_id)"
  type        = string
  default     = "roles/aiplatform.user"
}

# ===========================================
# CLOUD BUILD CONFIGURATION
# ===========================================

variable "cloudbuild_sa_email" {
  description = "Email of the Cloud Build service account (user-managed)"
  type        = string
  default     = ""
}

variable "cloudbuild_sa_roles" {
  description = "IAM roles to grant to the Cloud Build service account"
  type        = list(string)
  default = [
    "roles/artifactregistry.admin",     # Push/pull container images, manage repository IAM
    "roles/compute.viewer",             # Read GKE cluster compute resources (instance groups)
    "roles/container.admin",            # GKE cluster management
    "roles/container.clusterAdmin",     # GKE cluster admin operations
    "roles/iam.serviceAccountCreator",  # Create service accounts for workloads
    "roles/iam.serviceAccountUser",     # Act as service accounts
    "roles/logging.logWriter",          # Write build logs
    "roles/storage.admin",              # Access Terraform state and build artifacts
    "roles/workstations.admin",         # Manage Cloud Workstations
  ]
}
