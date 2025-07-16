// -----------------------------------------------------------------------------
// variables.tf - Define input variables
// -----------------------------------------------------------------------------
variable "project_id" {
    description = "The Google Cloud project ID."
    type        = string
}

variable "region" {
    description = "The Google Cloud region for resources."
    type        = string
    default     = "us-central1"
}

variable "network_name" {
    description = "The name of the VPC network to use for the workstation cluster."
    type        = string
    default     = "default"
    # Example: "default" or your custom VPC network name
}

variable "subnetwork_name" {
    description = "The name of the subnetwork to use for the workstation cluster."
    type        = string
    default     = "default"
    # Example: "default" or your custom subnetwork name in the specified region
}

variable "artifact_registry_repository_id" {
    description = "The ID for the Artifact Registry repository."
    type        = string
    default     = "workstation-images"
}

variable "custom_image_name" {
    description = "The name of your custom Docker image."
    type        = string
    default     = "remix-foundry-workstation"
}

variable "custom_image_tag" {
    description = "The tag for your custom Docker image."
    type        = string
    default     = "latest"
}

variable "workstation_cluster_id" {
    description = "The ID for the Workstation Cluster."
    type        = string
    default     = "dev-cluster"
}

variable "workstation_config_id" {
    description = "The ID for the Workstation Configuration."
    type        = string
    default     = "remix-foundry-config"
}

variable "workstation_id" {
    description = "The ID for the Workstation instance."
    type        = string
    default     = "my-dev-workstation"
}

variable "workstation_machine_type" {
    description = "The machine type for the workstation."
    type        = string
    default     = "n2d-highmem-16" // Requires a largish machine type. Example: 16 vCPU, 128 GB RAM
}

variable "workstation_disk_size_gb" {
    description = "The size of the persistent disk for the workstation in GB."
    type        = number
    default     = 500
}

variable "workstation_disk_type" {
    description = "The type of the persistent disk (e.g., pd-standard, pd-balanced, pd-ssd)."
    type        = string
    default     = "pd-balanced"
}

variable "workstation_service_account_email" {
    description = "Optional: Service account email for the workstation. Defaults to Compute Engine default SA."
    type        = string
    default     = null // Uses Compute Engine default SA if null
}

    variable "apis_to_enable" {
      description = "A list of Google Cloud APIs to enable for the project."
      type        = list(string)
      default = [
        "serviceusage.googleapis.com",       // Required for managing services
        "workstations.googleapis.com",       // Cloud Workstations API
        "artifactregistry.googleapis.com",   // Artifact Registry API
        "cloudbuild.googleapis.com",         // Cloud Build API (recommended)
        "compute.googleapis.com"             // Compute Engine API (dependency)
      ]
    }

variable "enable_apis" {
    description = "Whether to enable the specified APIs."
    type        = bool
    default     = true
}