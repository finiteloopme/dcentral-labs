# Note: The state bucket is created by the terraform-init.sh script
# before Terraform runs, so it can be used as the backend.
# This resource is commented out to avoid circular dependency.
#
# If you need to manage the state bucket with Terraform:
# 1. First run without backend
# 2. Create the bucket
# 3. Then migrate to GCS backend
#
# resource "google_storage_bucket" "terraform_state" {
#   name     = var.state_bucket_name != "" ? var.state_bucket_name : "${var.project_id}-terraform-state"
#   location = var.state_bucket_location
#   project  = var.project_id
#
#   uniform_bucket_level_access = true
#
#   versioning {
#     enabled = true
#   }
#
#   lifecycle_rule {
#     condition {
#       num_newer_versions = 5
#     }
#     action {
#       type = "Delete"
#     }
#   }
# }
