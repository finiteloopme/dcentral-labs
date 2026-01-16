# genai-chain-dev Makefile
#
# Usage:
#   make build CHAIN=somnia           # Build locally
#   make run CHAIN=somnia             # Run locally with podman
#   make cloud-deploy CHAIN=somnia    # Deploy to GCP via Cloud Build
#
# Environment:
#   Set PROJECT_ID, STATE_BUCKET, CLOUDBUILD_SA_EMAIL in .env

CHAIN ?= somnia

# =============================================================================
# Local Development
# =============================================================================

.PHONY: build run stop shell test clean

## Build chain container image locally with Earthly
build:
	./scripts/build.sh $(CHAIN)

## Build using containerized Earthly (no local install required)
build-container:
	./scripts/earthly-container.sh chains/$(CHAIN) -P +dev

## Run chain container locally with podman
run:
	./scripts/run-local.sh $(CHAIN)

## Stop running container
stop:
	./scripts/clean.sh $(CHAIN) --stop-only

## Start interactive shell in container
shell:
	./scripts/run-local.sh $(CHAIN) --shell

## Run CLI tests
test:
	./scripts/test.sh $(CHAIN)

## Clean build artifacts (stops container first)
clean:
	./scripts/clean.sh $(CHAIN)

## Deep clean including node_modules and images
clean-all:
	./scripts/clean.sh --all

# =============================================================================
# Cloud Operations
# =============================================================================

.PHONY: check-env cloud-build cloud-deploy cloud-plan cloud-destroy

## Validate cloud configuration and create state bucket if needed
check-env:
	./scripts/cloud.sh $(CHAIN) check

## Build and push container image via Cloud Build
cloud-build:
	./scripts/cloud.sh $(CHAIN) build

## Full deployment: build image and apply Terraform
cloud-deploy:
	./scripts/cloud.sh $(CHAIN) deploy

## Preview Terraform changes without applying
cloud-plan:
	./scripts/cloud.sh $(CHAIN) plan

## Destroy cloud infrastructure
cloud-destroy:
	./scripts/cloud.sh $(CHAIN) destroy

# =============================================================================
# Local Terraform (alternative to Cloud Build)
# =============================================================================

.PHONY: deploy deploy-plan deploy-destroy

## Deploy infrastructure locally with Terraform
deploy:
	./scripts/deploy.sh $(CHAIN)

## Preview infrastructure changes
deploy-plan:
	./scripts/deploy.sh $(CHAIN) --plan

## Destroy infrastructure locally
deploy-destroy:
	./scripts/deploy.sh $(CHAIN) --destroy

# =============================================================================
# Chain Management
# =============================================================================

.PHONY: new-chain list-chains

## Scaffold a new chain (requires NAME and TYPE)
## Usage: make new-chain NAME=polygon TYPE=evm
new-chain:
ifndef NAME
	$(error NAME is required. Usage: make new-chain NAME=polygon TYPE=evm)
endif
ifndef TYPE
	$(error TYPE is required. Usage: make new-chain NAME=polygon TYPE=evm)
endif
	./scripts/new-chain.sh $(NAME) --type=$(TYPE)

## List available chains
list-chains:
	@echo "Available chains:"
	@for dir in chains/*/; do \
		if [ -f "$$dir/Earthfile" ]; then \
			echo "  - $$(basename $$dir)"; \
		fi \
	done

# =============================================================================
# Help
# =============================================================================

.PHONY: help

## Show this help message
help:
	@echo "genai-chain-dev - GenAI-enabled blockchain development platforms"
	@echo ""
	@echo "Usage: make <target> [CHAIN=<chain>]"
	@echo ""
	@echo "Local Development:"
	@echo "  build              Build container image locally"
	@echo "  build-container    Build using containerized Earthly"
	@echo "  run                Run container locally with podman"
	@echo "  stop               Stop running container"
	@echo "  shell              Start interactive shell in container"
	@echo "  test               Run CLI tests"
	@echo "  clean              Stop container + clean build artifacts"
	@echo "  clean-all          Deep clean including images"
	@echo ""
	@echo "Cloud Operations:"
	@echo "  check-env          Validate configuration, create state bucket"
	@echo "  cloud-build        Build image via Cloud Build"
	@echo "  cloud-deploy       Full deployment (build + terraform)"
	@echo "  cloud-plan         Preview Terraform changes"
	@echo "  cloud-destroy      Destroy cloud infrastructure"
	@echo ""
	@echo "Local Terraform:"
	@echo "  deploy             Apply Terraform locally"
	@echo "  deploy-plan        Preview Terraform changes"
	@echo "  deploy-destroy     Destroy infrastructure"
	@echo ""
	@echo "Chain Management:"
	@echo "  new-chain          Scaffold new chain (NAME=x TYPE=evm)"
	@echo "  list-chains        List available chains"
	@echo ""
	@echo "Environment Variables (set in .env):"
	@echo "  CHAIN              Chain to operate on (default: somnia)"
	@echo "  PROJECT_ID         GCP project ID"
	@echo "  STATE_BUCKET       Terraform state bucket"
	@echo "  CLOUDBUILD_SA_EMAIL Cloud Build service account"
	@echo ""
	@echo "Examples:"
	@echo "  make build CHAIN=somnia"
	@echo "  make cloud-deploy CHAIN=somnia"
	@echo "  make new-chain NAME=polygon TYPE=evm"

.DEFAULT_GOAL := help
