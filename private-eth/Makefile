# Makefile to simplify interaction with Google Cloud Build for Terraform deployment.

# Automatically get the configured GCP Project ID.
GCP_PROJECT_ID := $(shell gcloud config get-value project)
# Define the GCS bucket name for Terraform state. It's best practice to include the project ID.
TF_STATE_BUCKET := "${GCP_PROJECT_ID}"

# Phony targets are not associated with files.
.PHONY: help init plan apply destroy

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  init      - Creates the GCS bucket for storing Terraform state."
	@echo "  plan      - Triggers a Cloud Build job to run 'terraform plan'."
	@echo "  apply     - Triggers a Cloud Build job to run 'terraform apply'."
	@echo "  destroy   - Triggers a Cloud Build job to run 'terraform destroy'."

# Target to create and configure the GCS bucket for Terraform state.
init:
	@echo "Creating GCS bucket for Terraform state: gs://${TF_STATE_BUCKET}"
	# Create the bucket if it doesn't already exist.
	@gsutil mb -p ${GCP_PROJECT_ID} gs://${TF_STATE_BUCKET} || echo "Bucket already exists."
	# Enable versioning on the bucket to keep a history of state files.
	@gsutil versioning set on gs://${TF_STATE_BUCKET}

# Target to trigger Cloud Build to run 'terraform plan'.
plan:
	@echo "Running 'terraform plan' via Cloud Build..."
	@gcloud builds submit . --config=cloudbuild.yaml --substitutions=_TF_COMMAND=plan,_TF_STATE_BUCKET=${TF_STATE_BUCKET}

# Target to trigger Cloud Build to run 'terraform apply'.
apply:
	@echo "Running 'terraform apply' via Cloud Build..."
	@gcloud builds submit . --config=cloudbuild.yaml --substitutions=_TF_COMMAND=apply,_TF_STATE_BUCKET=${TF_STATE_BUCKET}

# Target to trigger Cloud Build to run 'terraform destroy'.
destroy:
	@echo "Running 'terraform destroy' via Cloud Build..."
	@gcloud builds submit . --config=cloudbuild.yaml --substitutions=_TF_COMMAND=destroy,_TF_STATE_BUCKET=${TF_STATE_BUCKET}
