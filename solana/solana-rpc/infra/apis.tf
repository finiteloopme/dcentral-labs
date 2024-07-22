# Disable requires shielded VM org policy 
module "disable-requiresShieldedVm" {
  source            = "terraform-google-modules/org-policy/google"
  policy_for        = "project"
  project_id        = data.google_project.project.project_id
  constraint        = "constraints/compute.requireShieldedVm"
  policy_type       = "boolean"
  enforce           = false
}

# Allow list, creation of an external IP address
module "enable-vmExternalIpAccess" {
  source            = "terraform-google-modules/org-policy/google"
  policy_for        = "project"
  project_id        = data.google_project.project.project_id
  constraint        = "constraints/compute.vmExternalIpAccess"
  policy_type       = "list"
  enforce           = false
}

# Manage Project APIs
module "manage-project-apis" {
  source = "github.com/finiteloopme/demos//modules/manage-gcp-apis"
  project_id = data.google_project.project.project_id
  project_apis = local.project_apis
}
