---
description: Build and deploy containers or infrastructure with pre-flight checks
agent: devops
---

$ARGUMENTS

If $ARGUMENTS is empty, inspect the project to determine the deployment
target (look for Containerfile, Dockerfile, cloudbuild.yaml, Terraform
files) and ask the user to confirm before proceeding.

This is a deployment workflow. After pre-flight passes, check if a Makefile
exists:

**If Makefile exists with standard targets:**
Use `make` targets for the deployment:
- Container build: `make container-build`
- Container run: `make container-run`
- Cloud build: `make cloud-build`
- Cloud deploy: `make cloud-deploy`

**If no Makefile exists:**
Offer to scaffold one first using the scaffold tool, then use the targets.
If the user declines scaffolding, fall back to direct tool invocation:

If arguments mention containers, images, or Podman:
1. Build the container image using the podman tool.
2. Verify the image was created successfully.
3. If a registry is specified, push the image.
4. If deployment target is specified, deploy the container.

If arguments mention Terraform or infrastructure:
1. Run `terraform init` if needed.
2. Run `terraform plan` and show the output.
3. Wait for user confirmation before running `terraform apply`.

If arguments mention Cloud Build:
1. Verify gcloud auth status.
2. Submit the build using the cloudbuild tool.
3. Show build logs and status.

If arguments mention Google Cloud or GCP:
1. Verify gcloud auth status.
2. Execute the requested GCP operation.

Follow the standard post-work protocol after completing the deployment.
