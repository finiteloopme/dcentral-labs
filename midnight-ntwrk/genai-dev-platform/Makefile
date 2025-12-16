.PHONY: build run clean deploy plan destroy help check-env

# Load environment variables from .env if present
-include .env
export

# ==============================================================================
# Local Development Configuration
# ==============================================================================

IMAGE_NAME ?= midnight-dev-platform
IMAGE_TAG ?= latest
CONTAINER_NAME ?= midnight-dev

# ==============================================================================
# Cloud Deployment Configuration
# ==============================================================================

REGION ?= us-central1
CLUSTER_NAME ?= midnight-dev
ENVIRONMENT ?= dev
MIN_INSTANCES ?= 1
MACHINE_TYPE ?= e2-standard-4
PERSISTENT_DISK_SIZE_GB ?= 100
MIDNIGHT_NODE_IMAGE ?= midnightntwrk/midnight-node:latest-main
PROOF_SERVER_IMAGE ?= midnightnetwork/proof-server:latest
INDEXER_IMAGE ?= midnightntwrk/indexer-standalone:latest

# Cloud Build substitutions
SUBSTITUTIONS = \
	_PROJECT_ID=$(PROJECT_ID),\
	_STATE_BUCKET=$(STATE_BUCKET),\
	_REGION=$(REGION),\
	_CLUSTER_NAME=$(CLUSTER_NAME),\
	_ENVIRONMENT=$(ENVIRONMENT),\
	_IMAGE_NAME=$(IMAGE_NAME),\
	_IMAGE_TAG=$(IMAGE_TAG),\
	_MIN_INSTANCES=$(MIN_INSTANCES),\
	_MACHINE_TYPE=$(MACHINE_TYPE),\
	_PERSISTENT_DISK_SIZE_GB=$(PERSISTENT_DISK_SIZE_GB),\
	_MIDNIGHT_NODE_IMAGE=$(MIDNIGHT_NODE_IMAGE),\
	_PROOF_SERVER_IMAGE=$(PROOF_SERVER_IMAGE),\
	_INDEXER_IMAGE=$(INDEXER_IMAGE)

# ==============================================================================
# Help
# ==============================================================================

## help: Show this help message
help:
	@echo "Midnight GenAI Development Platform"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Local Development:"
	@echo "  build       Build container locally using Podman"
	@echo "  run         Run container locally (interactive)"
	@echo "  run-detach  Run container locally (detached)"
	@echo "  clean       Stop and remove local containers"
	@echo ""
	@echo "Cloud Deployment (GCP):"
	@echo "  deploy      Build and deploy all infrastructure via Cloud Build"
	@echo "  plan        Preview deployment changes (dry run)"
	@echo "  destroy     Destroy all cloud infrastructure"
	@echo "  check-env   Validate cloud deployment configuration"
	@echo ""
	@echo "Configuration:"
	@echo "  Copy .env.example to .env and customize as needed."
	@echo ""
	@echo "  Local development requires:"
	@echo "    - Podman installed"
	@echo ""
	@echo "  Cloud deployment requires:"
	@echo "    - PROJECT_ID:   GCP project ID"
	@echo "    - STATE_BUCKET: GCS bucket for Terraform state"
	@echo ""
	@echo "Examples:"
	@echo "  make build                      # Build locally"
	@echo "  make run                        # Run locally"
	@echo "  make deploy                     # Deploy to GCP"
	@echo "  make deploy CLUSTER_NAME=team1  # Deploy with custom cluster"

# ==============================================================================
# Local Development Targets
# ==============================================================================

## build: Build the container locally using Podman
build:
	@./scripts/build-local.sh -n $(IMAGE_NAME) -t $(IMAGE_TAG)

## run: Run the container locally (interactive mode)
run:
	@./scripts/clean.sh -c $(CONTAINER_NAME) 2>/dev/null || true
	@./scripts/run-local.sh -n $(IMAGE_NAME) -t $(IMAGE_TAG) -c $(CONTAINER_NAME)

## run-detach: Run the container locally in detached mode
run-detach:
	@./scripts/clean.sh -c $(CONTAINER_NAME) 2>/dev/null || true
	@./scripts/run-local.sh -n $(IMAGE_NAME) -t $(IMAGE_TAG) -c $(CONTAINER_NAME) -d

## clean: Stop and remove local containers
clean:
	@./scripts/clean.sh -c $(CONTAINER_NAME)

## clean-all: Remove all midnight containers
clean-all:
	@./scripts/clean.sh -a

# ==============================================================================
# Cloud Deployment Targets
# ==============================================================================

## check-env: Validate cloud deployment configuration
check-env:
	@echo "Checking cloud deployment configuration..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "ERROR: PROJECT_ID is required. Set in .env or environment"; \
		exit 1; \
	fi
	@if [ -z "$(STATE_BUCKET)" ]; then \
		echo "ERROR: STATE_BUCKET is required. Set in .env or environment"; \
		exit 1; \
	fi
	@echo "  PROJECT_ID:    $(PROJECT_ID)"
	@echo "  STATE_BUCKET:  $(STATE_BUCKET)"
	@echo "  REGION:        $(REGION)"
	@echo "  CLUSTER_NAME:  $(CLUSTER_NAME)"
	@echo ""
	@gcloud projects describe $(PROJECT_ID) > /dev/null 2>&1 || \
		(echo "ERROR: Cannot access project $(PROJECT_ID)" && exit 1)
	@gsutil ls gs://$(STATE_BUCKET) > /dev/null 2>&1 || \
		(echo "ERROR: Cannot access bucket $(STATE_BUCKET)" && exit 1)
	@echo "Configuration OK"

## deploy: Build container and deploy all infrastructure via Cloud Build
deploy: check-env
	@echo ""
	@echo "Deploying Midnight Development Platform to GCP..."
	@echo ""
	gcloud builds submit \
		--config=cloudbuild.yaml \
		--substitutions=$(SUBSTITUTIONS) \
		--project=$(PROJECT_ID)

## plan: Preview deployment (Terraform plan only)
plan: check-env
	@echo ""
	@echo "Planning deployment..."
	@echo ""
	gcloud builds submit \
		--config=cloudbuild-plan.yaml \
		--substitutions=$(SUBSTITUTIONS) \
		--project=$(PROJECT_ID)

## destroy: Destroy all cloud infrastructure
destroy: check-env
	@echo ""
	@echo "WARNING: This will destroy all cloud infrastructure!"
	@echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
	@sleep 10
	gcloud builds submit \
		--config=cloudbuild-destroy.yaml \
		--substitutions=$(SUBSTITUTIONS) \
		--project=$(PROJECT_ID)
