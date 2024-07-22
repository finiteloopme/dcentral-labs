variable "project_id" {
  description = "ID for the project"
}

variable "gcp_region" {
  description = "GCP Region"
  default = "us-central1"
}

variable "app_name" {
  description = "Name of the application"
  default = "sample-gcp-app"
}

variable "cird_range" {
  default = "10.0.0.0/24"
}