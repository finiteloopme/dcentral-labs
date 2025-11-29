variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for deployment"
  type        = string
  default     = "us-east4"
}
