variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ip_cidr_range" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}
