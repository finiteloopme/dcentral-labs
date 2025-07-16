PLAN_FILE=tfplan.out
GCP_PROJECT_ID=kunal-scratch
GCP_REGION=us-central1
CODE_FOLDER=src

ARTIFACT_REGISTRY_REPOSITORY_ID=workstation-images
CUSTOM_IMAGE_NAME=remix-foundry-workstation
CUSTOM_IMAGE_TAG=latest
IMAGE_URI=${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REGISTRY_REPOSITORY_ID}/${CUSTOM_IMAGE_NAME}:${CUSTOM_IMAGE_TAG}

TF_ENV_VARS=-var=project_id=${GCP_PROJECT_ID} -var=region=${GCP_REGION} -var=artifact_registry_repository_id=${ARTIFACT_REGISTRY_REPOSITORY_ID}

.PHONY: auth
auth:
	gcloud auth application-default login
	gcloud config set project ${GCP_PROJECT_ID}
	gcloud config set compute/region ${GCP_REGION}
	# Authenticate Docker with Artifact Registry
	gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev

.PHONY: build
build:
	# Define image URI (matches what Terraform expects)
	# export IMAGE_URI="${GCP_REGION}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repository_id}/${var.custom_image_name}:${var.custom_image_tag}" # Update with your values, you can use the output of terraform
	# Build the image
	# cd ${CODE_FOLDER}; docker build -t ${IMAGE_URI} .
	# # Push the image
	# cd ${CODE_FOLDER}; docker push ${IMAGE_URI}
	gcloud builds submit ${CODE_FOLDER} --project=${GCP_PROJECT_ID} --region=${GCP_REGION} --tag=${IMAGE_URI}

.PHONY: init
init:
	cd ${CODE_FOLDER}; terraform init

.PHONY: plan
plan:
	cd ${CODE_FOLDER}; terraform plan -out=${PLAN_FILE} ${TF_ENV_VARS}

.PHONY: apply
apply:
	cd ${CODE_FOLDER}; terraform apply ${PLAN_FILE}

.PHONY: destroy
destroy:
	cd ${CODE_FOLDER}; terraform destroy ${TF_ENV_VARS}

.PHONY: output
output:
	cd ${CODE_FOLDER}; terraform output -json