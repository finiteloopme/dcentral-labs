variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

variable "workstation_cluster_name" {
  description = "Name of the Cloud Workstation cluster"
  type        = string
  default     = "web3-workstation-cluster"
}

variable "workstation_config_name" {
  description = "Name of the Cloud Workstation configuration"
  type        = string
  default     = "web3-dev-config"
}

variable "artifact_registry_repo" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "web3-workstation-images"
}

variable "terraform_state_bucket" {
  description = "Name of the GCS bucket for Terraform state"
  type        = string
  default     = "web3-workstation-terraform-state"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "workstation-network"
}

variable "subnet_name" {
  description = "Name of the VPC subnet"
  type        = string
  default     = "workstation-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "machine_type" {
  description = "Machine type for workstations"
  type        = string
  default     = "e2-standard-4"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "idle_timeout" {
  description = "Idle timeout for workstations in seconds"
  type        = number
  default     = 14400 # 4 hours
}

variable "running_timeout" {
  description = "Running timeout for workstations in seconds"
  type        = number
  default     = 43200 # 12 hours
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    environment = "development"
    purpose     = "web3-development"
    managed_by  = "terraform"
  }
}

variable "disable_apis_on_destroy" {
  description = "Whether to disable APIs when destroying infrastructure"
  type        = bool
  default     = false
}

variable "enable_cloudbuild" {
  description = "Whether to enable Cloud Build and create triggers"
  type        = bool
  default     = true
}