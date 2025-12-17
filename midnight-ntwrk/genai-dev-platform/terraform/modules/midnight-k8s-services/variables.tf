# Midnight Kubernetes Services Module Variables

variable "midnight_node_image" {
  description = "Docker image for Midnight node"
  type        = string
  default     = "midnightntwrk/midnight-node:0.18.0-rc.9"
}

variable "proof_server_image" {
  description = "Docker image for proof server"
  type        = string
  default     = "midnightnetwork/proof-server:6.2.0-rc.1"
}

variable "indexer_image" {
  description = "Docker image for indexer-standalone"
  type        = string
  default     = "midnightntwrk/indexer-standalone:3.0.0-alpha.20"
}

variable "chain_environment" {
  description = "Chain environment: standalone (dev), testnet, mainnet"
  type        = string
  default     = "standalone"
}

variable "indexer_secret" {
  description = "32-byte hex secret for indexer encryption. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
  default     = ""
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "node_cpu" {
  description = "CPU request for midnight-node"
  type        = string
  default     = "2"
}

variable "node_memory" {
  description = "Memory request for midnight-node"
  type        = string
  default     = "4Gi"
}

variable "proof_server_cpu" {
  description = "CPU request for proof-server"
  type        = string
  default     = "4"
}

variable "proof_server_memory" {
  description = "Memory request for proof-server"
  type        = string
  default     = "8Gi"
}

variable "indexer_cpu" {
  description = "CPU request for indexer"
  type        = string
  default     = "2"
}

variable "indexer_memory" {
  description = "Memory request for indexer"
  type        = string
  default     = "4Gi"
}
