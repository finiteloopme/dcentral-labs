variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for workstations (e.g., 'midnight-dev.example.com')"
  type        = string
}

variable "dns_zone_name" {
  description = "Name for the Cloud DNS zone"
  type        = string
  default     = ""
}

variable "workstation_ip" {
  description = "IP address of the workstation (if using external IP)"
  type        = string
  default     = ""
}

variable "enable_dns" {
  description = "Whether to create DNS resources"
  type        = bool
  default     = false
}

variable "dns_records" {
  description = "Additional DNS records to create"
  type = list(object({
    name = string
    type = string
    ttl  = number
    data = list(string)
  }))
  default = []
}