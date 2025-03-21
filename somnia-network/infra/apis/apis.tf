# Disable requires shielded VM org policy 
module "disable-requiresShieldedVm" {
  source            = "terraform-google-modules/org-policy/google"
  policy_for        = "project"
  project_id        = var.project_id
  constraint        = "constraints/compute.requireShieldedVm"
  policy_type       = "boolean"
  enforce           = false
}

# Allow list, creation of an external IP address
module "enable-vmExternalIpAccess" {
  source            = "terraform-google-modules/org-policy/google"
  policy_for        = "project"
  project_id        = var.project_id
  constraint        = "constraints/compute.vmExternalIpAccess"
  policy_type       = "list"
  enforce           = false
}

# Manage Project APIs
module "manage-project-apis" {
    source = "github.com/finiteloopme/demos//modules/manage-gcp-apis"
    project_id = var.project_id
    project_apis = var.project_apis
}
