.PHONY: build run run-detach clean clean-all deploy plan destroy check-env help

# Load environment variables from .env if present
-include .env
export

# Defaults
IMAGE_NAME ?= midnight-dev-platform
IMAGE_TAG ?= latest
CONTAINER_NAME ?= midnight-dev

# ==============================================================================
# Help
# ==============================================================================

help:
	@echo "Midnight GenAI Development Platform"
	@echo ""
	@echo "Local Development:"
	@echo "  make build        Build container locally"
	@echo "  make run          Run container (interactive)"
	@echo "  make run-detach   Run container (detached)"
	@echo "  make clean        Stop and remove container"
	@echo ""
	@echo "Cloud Deployment (GCP):"
	@echo "  make deploy       Deploy to GCP via Cloud Build"
	@echo "  make plan         Preview deployment changes"
	@echo "  make destroy      Destroy cloud infrastructure"
	@echo "  make check-env    Validate GCP configuration"
	@echo ""
	@echo "See .env.example for configuration options."

# ==============================================================================
# Local Development
# ==============================================================================

build:
	@./scripts/build-local.sh -n $(IMAGE_NAME) -t $(IMAGE_TAG)

run:
	@./scripts/clean.sh -c $(CONTAINER_NAME) 2>/dev/null || true
	@./scripts/run-local.sh -n $(IMAGE_NAME) -t $(IMAGE_TAG) -c $(CONTAINER_NAME)

run-detach:
	@./scripts/clean.sh -c $(CONTAINER_NAME) 2>/dev/null || true
	@./scripts/run-local.sh -n $(IMAGE_NAME) -t $(IMAGE_TAG) -c $(CONTAINER_NAME) -d

clean:
	@./scripts/clean.sh -c $(CONTAINER_NAME)

clean-all:
	@./scripts/clean.sh -a

# ==============================================================================
# Cloud Deployment
# ==============================================================================

check-env:
	@./scripts/cloud.sh check

deploy:
	@./scripts/cloud.sh deploy

plan:
	@./scripts/cloud.sh plan

destroy:
	@./scripts/cloud.sh destroy
