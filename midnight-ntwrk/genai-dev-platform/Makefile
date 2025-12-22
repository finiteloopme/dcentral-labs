.PHONY: build build-sdk run run-detach clean clean-all deploy plan destroy state-cleanup check-env help test-integration helm-upgrade helm-status helm-rollback helm-logs

# Load environment variables from .env if present
-include .env
export

# Defaults
IMAGE_NAME ?= midnight-dev-platform
IMAGE_TAG ?= latest
CONTAINER_NAME ?= midnight-dev
SDK_IMAGE_NAME ?= midnight-sdk
SDK_IMAGE_TAG ?= latest
BUILD_SDK ?= true
BUILD_IMAGE ?= true

# ==============================================================================
# Help
# ==============================================================================

help:
	@echo "Midnight GenAI Development Platform"
	@echo ""
	@echo "Local Development:"
	@echo "  make build-sdk       Build SDK image (~30 min, one-time)"
	@echo "  make build           Build container (requires SDK image)"
	@echo "  make run             Run container (interactive)"
	@echo "  make run-detach      Run container (detached)"
	@echo "  make clean           Stop and remove container"
	@echo ""
	@echo "Workflow:"
	@echo "  1. make build-sdk    # Build SDK packages from source (first time)"
	@echo "  2. make build        # Build main container"
	@echo "  3. make run          # Run container"
	@echo ""
	@echo "Cloud Deployment (GCP):"
	@echo "  make deploy                              Deploy to GCP (full build)"
	@echo "  make deploy BUILD_SDK=false              Skip SDK build"
	@echo "  make deploy BUILD_IMAGE=false            Skip image build"
	@echo "  make deploy BUILD_SDK=false BUILD_IMAGE=false  Terraform only (fastest)"
	@echo "  make plan                                Preview deployment changes"
	@echo "  make destroy                             Destroy cloud infrastructure"
	@echo "  make check-env                           Validate GCP configuration"
	@echo ""
	@echo "Helm Operations (K8s services - fast iteration):"
	@echo "  make helm-upgrade            Upgrade K8s services via Helm"
	@echo "  make helm-status             Show Helm release status"
	@echo "  make helm-rollback           Rollback to previous release"
	@echo "  make helm-logs SERVICE=node  Show logs for a service"
	@echo ""
	@echo "Testing:"
	@echo "  make test-integration    Run CLI integration tests"
	@echo ""
	@echo "See .env.example for configuration options."

# ==============================================================================
# Local Development
# ==============================================================================

build-sdk:
	@./scripts/build-sdk.sh -n $(SDK_IMAGE_NAME) -t $(SDK_IMAGE_TAG)

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

clean-deploy:
	@./scripts/cloud.sh state-cleanup "module.midnight_k8s_services" "true"
	@./scripts/cloud.sh deploy

deploy:
	@BUILD_SDK=$(BUILD_SDK) BUILD_IMAGE=$(BUILD_IMAGE) ./scripts/cloud.sh deploy

plan:
	@./scripts/cloud.sh plan

destroy:
	@./scripts/cloud.sh destroy

state-cleanup:
	@./scripts/cloud.sh state-cleanup "$(PATTERN)" "$(DELETE)"

# ==============================================================================
# Helm Operations (K8s services)
# ==============================================================================

helm-upgrade:
	@./scripts/helm.sh upgrade

helm-status:
	@./scripts/helm.sh status

helm-rollback:
	@./scripts/helm.sh rollback

helm-logs:
	@./scripts/helm.sh logs $(SERVICE)

# ==============================================================================
# Testing
# ==============================================================================

test-integration:
	@echo "Running CLI integration tests..."
	@cd cli && npm run test:integration
