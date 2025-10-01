.PHONY: init plan apply destroy plan-upload plan-download helm-init helm-generate-key helm-install helm-upgrade helm-apply helm-delete check-iam check-quotas

# Include `PROJECT_ID` and `BUCKET_NAME` variables
include config.env

# Terraform targets
init:
	./run_in_container.sh --project-id $(PROJECT_ID) terraform -w /app/terraform init -upgrade -backend-config="bucket=$(shell echo $(BUCKET_NAME) | sed 's|gs://||')"

plan: plan-upload

plan-upload:
	./run_in_container.sh --project-id $(PROJECT_ID) terraform -w /app/terraform plan -out=terraform.plan
	./run_in_container.sh --project-id $(PROJECT_ID) gcloud -w /app/terraform storage cp terraform.plan gs://$(shell echo $(BUCKET_NAME) | sed 's|gs://||')/terraform.plan

plan-download:
	./run_in_container.sh --project-id $(PROJECT_ID) gcloud -w /app/terraform storage cp gs://$(shell echo $(BUCKET_NAME) | sed 's|gs://||')/terraform.plan terraform.plan

apply: plan-download
	./run_in_container.sh --project-id $(PROJECT_ID) terraform -w /app/terraform apply terraform.plan

destroy:
	./run_in_container.sh --project-id $(PROJECT_ID) terraform -w /app/terraform destroy -auto-approve

check-iam:
	./run_in_container.sh --project-id $(PROJECT_ID) gcloud projects get-iam-policy $(PROJECT_ID)

check-quotas:
	./run_in_container.sh --project-id $(PROJECT_ID) gcloud services quotas list --service=alloydb.googleapis.com --consumer=projects/$(PROJECT_ID)

# Helm targets
build-gke-tools:
	podman build -t midnight-gke-tools .

helm-init:
	./run_in_container.sh --project-id $(PROJECT_ID) gcloud container clusters get-credentials autopilot-cluster --region us-central1 --project $(PROJECT_ID)

helm-generate-key:
	./run_in_container.sh --project-id $(PROJECT_ID) helm-generate-key -w /app

helm-install: helm-apply

helm-upgrade: helm-apply

helm-apply: helm-generate-key
	./run_in_container.sh --project-id $(PROJECT_ID) helm-apply -w /app

helm-delete:
	./run_in_container.sh --project-id $(PROJECT_ID) helm delete midnight-duo