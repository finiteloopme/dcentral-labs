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
}

variable "machine_type" {
  description = "GCE machine type (must support Confidential Computing)"
  type        = string
}

variable "confidential_type" {
  description = "Confidential Computing technology: SEV or TDX"
  type        = string
}

variable "image_family" {
  description = "Confidential Space image family (confidential-space or confidential-space-debug)"
  type        = string
}

variable "docker_image" {
  description = "Full Docker image URI in Artifact Registry"
  type        = string
}

variable "environment" {
  description = "Deployment environment: debug or prod"
  type        = string
}

variable "mig_min_replicas" {
  description = "Minimum number of instances in the MIG"
  type        = number
}

variable "mig_max_replicas" {
  description = "Maximum number of instances in the MIG"
  type        = number
}

variable "network_tag" {
  description = "Network tag to apply to instances"
  type        = string
}

variable "health_check_id" {
  description = "Self link of the health check for auto-healing"
  type        = string
}
