# Cloud Build configuration for CI/CD

# Cloud Build resources are created only if enabled
# APIs are managed in main.tf

# Create a Cloud Source Repository (optional - can use GitHub instead)
resource "google_sourcerepo_repository" "web3_workstation_repo" {
  count = var.enable_cloudbuild ? 1 : 0
  
  name = "web3-workstation"
  
  depends_on = [google_project_service.required_apis["source_repo"]]
}

# Grant Cloud Build service account necessary permissions
resource "google_project_iam_member" "cloudbuild_permissions" {
  for_each = var.enable_cloudbuild ? toset([
    "roles/artifactregistry.writer",
    "roles/storage.admin",
    "roles/compute.admin",
    "roles/workstations.admin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin"
  ]) : toset([])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  
  depends_on = [google_project_service.required_apis["cloudbuild"]]
}

# Cloud Build trigger for main branch
resource "google_cloudbuild_trigger" "deploy_on_push" {
  count = var.enable_cloudbuild ? 1 : 0
  
  name        = "deploy-web3-workstation"
  description = "Deploy Web3 workstation on push to main branch"
  
  # Trigger on push to main branch
  trigger_template {
    branch_name = "^main$|^master$"
    repo_name   = google_sourcerepo_repository.web3_workstation_repo[0].name
  }
  
  # Use the cloudbuild.yaml file from the repository
  filename = "cloudbuild.yaml"
  
  # Substitutions
  substitutions = {
    _REGION                 = var.region
    _ARTIFACT_REPO         = var.artifact_registry_repo
    _IMAGE_NAME            = "web3-workstation"
    _TERRAFORM_STATE_BUCKET = google_storage_bucket.terraform_state.name
    _ENVIRONMENT           = "production"
    _FORCE_APPLY           = "true"
  }
  
  depends_on = [
    google_project_iam_member.cloudbuild_permissions,
    google_sourcerepo_repository.web3_workstation_repo
  ]
}

# Cloud Build trigger for pull requests (plan only)
resource "google_cloudbuild_trigger" "plan_on_pr" {
  count = var.enable_cloudbuild ? 1 : 0
  
  name        = "plan-web3-workstation-pr"
  description = "Plan Terraform changes on pull request"
  
  # Trigger on pull request
  trigger_template {
    branch_name = "^PR-.*"
    repo_name   = google_sourcerepo_repository.web3_workstation_repo[0].name
  }
  
  # Use the cloudbuild.yaml file from the repository
  filename = "cloudbuild.yaml"
  
  # Substitutions (no apply on PR)
  substitutions = {
    _REGION                 = var.region
    _ARTIFACT_REPO         = var.artifact_registry_repo
    _IMAGE_NAME            = "web3-workstation"
    _TERRAFORM_STATE_BUCKET = google_storage_bucket.terraform_state.name
    _ENVIRONMENT           = "development"
    _FORCE_APPLY           = "false"
  }
  
  depends_on = [
    google_project_iam_member.cloudbuild_permissions,
    google_sourcerepo_repository.web3_workstation_repo
  ]
}

# Manual trigger for deployment
resource "google_cloudbuild_trigger" "manual_deploy" {
  count = var.enable_cloudbuild ? 1 : 0
  
  name        = "manual-deploy-web3-workstation"
  description = "Manually deploy Web3 workstation"
  
  # Manual trigger with no source
  trigger_template {
    branch_name = ".*"
    repo_name   = google_sourcerepo_repository.web3_workstation_repo[0].name
  }
  
  # Use the cloudbuild.yaml file from the repository
  filename = "cloudbuild.yaml"
  
  # Substitutions
  substitutions = {
    _REGION                 = var.region
    _ARTIFACT_REPO         = var.artifact_registry_repo
    _IMAGE_NAME            = "web3-workstation"
    _TERRAFORM_STATE_BUCKET = google_storage_bucket.terraform_state.name
    _ENVIRONMENT           = "production"
    _FORCE_APPLY           = "true"
  }
  
  # This trigger is disabled by default and can be run manually
  disabled = true
  
  depends_on = [
    google_project_iam_member.cloudbuild_permissions,
    google_sourcerepo_repository.web3_workstation_repo
  ]
}

# Get project data
data "google_project" "project" {
  project_id = var.project_id
}

# Outputs for Cloud Build
output "cloud_build_triggers" {
  value = var.enable_cloudbuild ? {
    deploy_trigger = google_cloudbuild_trigger.deploy_on_push[0].name
    pr_trigger     = google_cloudbuild_trigger.plan_on_pr[0].name
    manual_trigger = google_cloudbuild_trigger.manual_deploy[0].name
  } : {}
  description = "Cloud Build trigger names"
}

output "source_repository_url" {
  value       = var.enable_cloudbuild ? "https://source.developers.google.com/p/${var.project_id}/r/${google_sourcerepo_repository.web3_workstation_repo[0].name}" : ""
  description = "URL of the Cloud Source Repository"
}