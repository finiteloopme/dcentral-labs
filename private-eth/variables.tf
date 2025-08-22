# variables.tf

variable "gcp_project_id" {
  description = "The GCP project ID to deploy resources in."
  type        = string
  # IMPORTANT: You must provide your GCP Project ID here.
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "The GCP zone to deploy resources in."
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "The GCE machine type to use. Should have sufficient CPU and memory."
  type        = string
  default     = "n2-standard-8" # 8 vCPU, 32 GiB RAM
}

variable "image" {
  description = "The boot image for the GCE instance (Ubuntu 22.04 LTS)."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "private-eth"
}