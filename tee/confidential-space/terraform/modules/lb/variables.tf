variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "app_name" {
  description = "Application name, used for resource naming"
  type        = string
}

variable "health_check_id" {
  description = "ID of the health check resource (defined at root level)"
  type        = string
}

variable "instance_group" {
  description = "Self link of the MIG instance group"
  type        = string
}

variable "lb_ip_address" {
  description = "Self link of the reserved global IP"
  type        = string
}
