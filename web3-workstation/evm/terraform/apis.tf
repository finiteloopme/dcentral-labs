# Separate file for API management outputs and monitoring

# Output the status of all APIs
output "enabled_apis" {
  value = {
    for k, v in google_project_service.required_apis : k => v.service
  }
  description = "List of enabled Google Cloud APIs"
}

# Check if all critical APIs are enabled
output "api_status" {
  value = {
    all_enabled = length(google_project_service.required_apis) == length(local.apis)
    count       = length(google_project_service.required_apis)
    expected    = length(local.apis)
  }
  description = "Status of API enablement"
}

# Data source to check current project APIs (for validation)
data "google_project_services" "current" {
  project = var.project_id
}

# Output currently enabled services (useful for debugging)
output "currently_enabled_services" {
  value       = data.google_project_services.current.services
  description = "All currently enabled services in the project"
  sensitive   = false
}

# Validation to ensure critical APIs are in the list
locals {
  apis = {
    compute              = "compute.googleapis.com"
    workstations        = "workstations.googleapis.com"
    artifact_registry   = "artifactregistry.googleapis.com"
    container_registry  = "containerregistry.googleapis.com"
    storage             = "storage.googleapis.com"
    resource_manager    = "cloudresourcemanager.googleapis.com"
    iam                 = "iam.googleapis.com"
    cloudbuild          = "cloudbuild.googleapis.com"
    source_repo         = "sourcerepo.googleapis.com"
    logging             = "logging.googleapis.com"
    monitoring          = "monitoring.googleapis.com"
    service_usage       = "serviceusage.googleapis.com"
    vertex_ai           = "aiplatform.googleapis.com"
  }

# Resource to ensure critical APIs are always included
resource "null_resource" "validate_apis" {
  count = length(local.missing_critical_apis) > 0 ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Missing critical APIs: ${join(", ", local.missing_critical_apis)}' && exit 1"
  }
}