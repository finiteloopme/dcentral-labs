variable "gcp_project" {
  description = "GCP project ID"
  type        = string
  default     = "privacy-defi-mvp"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "tee_image_digest" {
  description = "TEE container image digest"
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "mock_server_machine_type" {
  description = "Machine type for mock server"
  type        = string
  default     = "e2-standard-16"
}

variable "tee_service_machine_type" {
  description = "Machine type for TEE service"
  type        = string
  default     = "c3-standard-8"
}

variable "subnet_cidr" {
  description = "CIDR range for subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "mock_server_ip" {
  description = "Internal IP for mock server"
  type        = string
  default     = "10.0.0.10"
}

variable "tee_service_ip" {
  description = "Internal IP for TEE service"
  type        = string
  default     = "10.0.0.20"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "privacy-defi"
}