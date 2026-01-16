# Shared Terraform variables for all chains
#
# Chain-specific values are passed from chain.config.toml via scripts.
# Workstation users are configured in workstations.auto.tfvars.

# =============================================================================
# Chain Identification (from chain.config.toml)
# =============================================================================

variable "chain" {
  description = "Chain identifier (e.g., somnia, polygon)"
  type        = string
}

variable "chain_name" {
  description = "Human-readable chain name (e.g., Somnia)"
  type        = string
}

variable "cli_name" {
  description = "CLI binary name (e.g., somniactl)"
  type        = string
}

# =============================================================================
# Chain Network Config (from chain.config.toml)
# =============================================================================

variable "chain_id" {
  description = "Default blockchain chain ID"
  type        = string
  default     = ""
}

variable "rpc_url" {
  description = "Default RPC endpoint URL"
  type        = string
  default     = ""
}

variable "explorer_url" {
  description = "Block explorer URL"
  type        = string
  default     = ""
}

variable "faucet_url" {
  description = "Testnet faucet URL"
  type        = string
  default     = ""
}

variable "native_currency" {
  description = "Native token symbol (e.g., ETH, STT)"
  type        = string
  default     = "ETH"
}

# =============================================================================
# GCP Configuration
# =============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

# =============================================================================
# Container Image
# =============================================================================

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

# =============================================================================
# Workstation Configuration (sane defaults)
# =============================================================================

variable "machine_type" {
  description = "GCE machine type for workstations"
  type        = string
  default     = "e2-standard-4"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "home_disk_size_gb" {
  description = "Persistent home disk size in GB"
  type        = number
  default     = 100
}

variable "idle_timeout" {
  description = "Idle timeout before workstation stops (e.g., 43200s = 12 hours)"
  type        = string
  default     = "43200s"
}

variable "running_timeout" {
  description = "Maximum running time before workstation stops (e.g., 86400s = 24 hours)"
  type        = string
  default     = "86400s"
}

# =============================================================================
# Workstation Users (from workstations.auto.tfvars)
# =============================================================================

variable "workstations" {
  description = "Map of workstation name to owner email"
  type        = map(string)
  default     = {}
}

variable "workstation_admins" {
  description = "List of admin emails with access to all workstations"
  type        = list(string)
  default     = []
}

# =============================================================================
# Vertex AI (for OpenCode)
# =============================================================================

variable "vertex_ai_project" {
  description = "Project for Vertex AI access (defaults to project_id if empty)"
  type        = string
  default     = ""
}

variable "enable_vertex_ai" {
  description = "Enable Vertex AI access for workstations"
  type        = bool
  default     = true
}
