variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "app_name" {
  description = "Application name, used for resource naming"
  type        = string
}

variable "app_port" {
  description = "Application port for health check probes"
  type        = number
}

variable "environment" {
  description = "Deployment environment: debug or prod"
  type        = string
}

variable "network" {
  description = "VPC network name"
  type        = string
  default     = "default"
}
