variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "app_name" {
  description = "Application name, used for resource naming"
  type        = string
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "n2d-standard-2"
}

variable "confidential_type" {
  description = "Confidential Computing technology: SEV or TDX"
  type        = string
  default     = "SEV"
}

variable "image_family" {
  description = "Confidential Space image family"
  type        = string
  default     = "confidential-space-debug"
}

variable "docker_image" {
  description = "Full Docker image URI in Artifact Registry"
  type        = string
}

variable "mig_min_replicas" {
  description = "Minimum number of instances in the MIG"
  type        = number
  default     = 1
}

variable "mig_max_replicas" {
  description = "Maximum number of instances in the MIG"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Deployment environment: debug or prod"
  type        = string
  default     = "debug"
}
