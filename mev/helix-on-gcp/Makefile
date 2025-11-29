PROJECT_ID ?= $(shell gcloud config get-value project)
REGION ?= us-east4
TF_STATE_BUCKET ?= $(PROJECT_ID)-tf-state-helix

.PHONY: setup deploy destroy help

help:
	@echo "Helix Benchmark Operations"
	@echo "--------------------------"
	@echo "make setup       : Creates State Bucket & grants Cloud Build permissions"
	@echo "make build-image : Builds Helix Docker image using Cloud Build"
	@echo "make deploy      : Runs Terraform Apply (assumes image exists)"
	@echo "make destroy     : Destroys all infrastructure"

setup:
	@echo "Creating Terraform State Bucket..."
	@if ! gcloud storage buckets describe gs://$(TF_STATE_BUCKET) > /dev/null 2>&1; then \
		gcloud storage buckets create gs://$(TF_STATE_BUCKET) --location=$(REGION); \
	fi
	@echo "Granting Cloud Build permissions..."
	@PROJECT_NUMBER=$$(gcloud projects describe $(PROJECT_ID) --format='value(projectNumber)'); \
	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member=serviceAccount:$$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
		--role=roles/editor

build-image:
	@echo "Submitting Cloud Build job for Image Build..."
	gcloud builds submit . --config=cloudbuild-image.yaml

deploy:
	@echo "Submitting Cloud Build job for Infrastructure..."
	gcloud builds submit . --config=cloudbuild.yaml \
		--substitutions=_REGION=$(REGION),_TF_STATE_BUCKET=$(TF_STATE_BUCKET)

destroy:
	@echo "WARNING: This will destroy all resources."
	cd terraform && terraform init -backend-config="bucket=$(TF_STATE_BUCKET)"
	cd terraform && terraform destroy -auto-approve -var="project_id=$(PROJECT_ID)" -var="region=$(REGION)"
