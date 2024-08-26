# module "agent_policy" {
#   source     = "terraform-google-modules/cloud-operations/google//modules/agent-policy"
#   version    = "~> 0.2.3"

#   project_id = google_compute_instance.eth-rbuilder.project
#   policy_id  = "ops-agents"
#   agent_rules = [
#     {
#       type               = "logging"
#       version            = "current-major"
#       package_state      = "installed"
#       enable_autoupgrade = true
#     },
#     {
#       type               = "metrics"
#       version            = "current-major"
#       package_state      = "installed"
#       enable_autoupgrade = true
#     },
#   ]
#   group_labels = [
#     {
#       wl-domain = "eth"
#       wl-env = "test"
#     }
#   ]
#   os_types = [
#     {
#       short_name = "ubuntu"
#       version    = "24"
#     },
#   ]
# }