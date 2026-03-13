---
description: Manage infrastructure with Terraform and GCP (with pre-flight checks)
agent: devops
---

$ARGUMENTS

This is an infrastructure management workflow.

If no specific arguments are provided:
1. Check if Terraform is initialized (look for .terraform directory).
2. Run `terraform validate` to check configuration.
3. Show current `terraform state list` and `terraform output`.

If arguments mention "plan":
1. Run `terraform plan` and show the full output.

If arguments mention "apply":
1. Run `terraform plan` first to show what will change.
2. Ask for explicit confirmation before applying.
3. Run `terraform apply` only with confirmation.

If arguments mention "destroy":
1. Run `terraform plan -destroy` to show what will be destroyed.
2. Warn the user this is destructive and irreversible.
3. Run `terraform destroy` only with explicit confirmation.

If arguments mention GCP resources:
1. Check gcloud auth status.
2. Perform the requested infrastructure operation.
3. Show the results.

Follow the standard post-work protocol after making infrastructure changes.
