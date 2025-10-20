# Midnight Development Platform
# Build and deployment commands for Google Cloud Workstations

.PHONY: help build push deploy clean status

# Configuration
PROJECT_ID ?= $(shell gcloud config get-value project 2>/dev/null)
REGION ?= us-central1
ZONE ?= us-central1-a
ENV ?= dev

# Export for scripts
export PROJECT_ID REGION ZONE ENV

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# Default target
help:
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)     🌙 Midnight Development Platform$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(YELLOW)Container Commands (Docker/Podman):$(NC)"
	@echo "  $(GREEN)build$(NC)         - Build container image"
	@echo "  $(GREEN)push$(NC)          - Push image to registry"
	@echo "  $(GREEN)run-local$(NC)     - Run container locally"
	@echo ""
	@echo "$(YELLOW)Infrastructure:$(NC)"
	@echo "  $(GREEN)deploy$(NC)        - Deploy infrastructure via Terraform"
	@echo "  $(GREEN)destroy$(NC)       - Destroy infrastructure (requires confirmation)"
	@echo "  $(GREEN)status$(NC)        - Show deployment status"
	@echo ""
	@echo "$(YELLOW)Cloud Build:$(NC)"
	@echo "  $(GREEN)cloud-deploy$(NC)  - Deploy via Cloud Build"
	@echo "  $(GREEN)cloud-status$(NC)  - Check build status"
	@echo ""
	@echo "$(YELLOW)Workstations:$(NC)"
	@echo "  $(GREEN)ws-list$(NC)       - List workstations"
	@echo "  $(GREEN)ws-start$(NC)      - Start workstation"
	@echo "  $(GREEN)ws-stop$(NC)       - Stop workstation"
	@echo "  $(GREEN)ws-status$(NC)     - Show workstation status"
	@echo ""
	@echo "Current: PROJECT_ID=$(PROJECT_ID) ENV=$(ENV)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# CONTAINER COMMANDS (Docker/Podman)
# ============================================================================

# Build container (supports both Docker and Podman)
build:
	@echo "$(GREEN)Building container image...$(NC)"
	@cd docker && ./build.sh

# Push to registry
push: check-project
	@echo "$(GREEN)Pushing to Artifact Registry...$(NC)"
	@./scripts/push.sh $(PROJECT_ID) $(REGION)

# Run locally
run-local:
	@echo "$(GREEN)Running container locally...$(NC)"
	@cd docker && ./run-local-simple.sh

# ============================================================================
# INFRASTRUCTURE
# ============================================================================

# Deploy infrastructure
deploy: check-project
	@echo "$(GREEN)Deploying infrastructure...$(NC)"
	@./scripts/terraform-init.sh $(PROJECT_ID) $(REGION) $(ZONE) $(ENV)
	@./scripts/deploy.sh $(PROJECT_ID) $(REGION) $(ZONE) $(ENV)

# Show status
status: check-project
	@echo "$(GREEN)Checking deployment status...$(NC)"
	@./scripts/status.sh $(PROJECT_ID) $(REGION) $(ZONE) $(ENV)

# Destroy infrastructure (careful!)
destroy: check-project
	@echo "$(RED)⚠️  WARNING: Destroying $(ENV) environment!$(NC)"
	@read -p "Type 'DESTROY' to confirm: " confirm && [ "$$confirm" = "DESTROY" ] || exit 1
	@cd terraform && terraform destroy \
		-var="project_id=$(PROJECT_ID)" \
		-var="environment=$(ENV)" \
		-var="region=$(REGION)" \
		-var="zone=$(ZONE)"

# Clean artifacts
clean:
	@echo "$(GREEN)Cleaning up artifacts...$(NC)"
	@./scripts/clean.sh
	@rm -rf terraform/.terraform terraform/*.tfplan

# ============================================================================
# CLOUD BUILD
# ============================================================================

# Deploy via Cloud Build
cloud-deploy: check-project
	@echo "$(GREEN)Deploying via Cloud Build...$(NC)"
	@gcloud builds submit \
		--config=cicd/cloudbuild/cloudbuild.yaml \
		--substitutions="_ENVIRONMENT=$(ENV),_REGION=$(REGION),_ZONE=$(ZONE)" \
		--project=$(PROJECT_ID) .

# Cloud Build status
cloud-status: check-project
	@echo "$(YELLOW)Recent builds:$(NC)"
	@gcloud builds list --limit=5 --project=$(PROJECT_ID) \
		--format="table(id,status,createTime.date())"

# ============================================================================
# WORKSTATION MANAGEMENT
# ============================================================================

# List workstations
ws-list: check-project
	@gcloud workstations list \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=$(REGION) \
		--format="table(name.segment(-1):label=NAME,state,createTime.date())"

# Start workstation
ws-start: check-project
	@echo "$(GREEN)Starting workstation...$(NC)"
	@gcloud workstations start midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=$(REGION)

# Stop workstation
ws-stop: check-project
	@echo "$(YELLOW)Stopping workstation...$(NC)"
	@gcloud workstations stop midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=$(REGION) \
		--quiet

# Show workstation status
ws-status: check-project
	@gcloud workstations describe midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=$(REGION) \
		--format="table(name.segment(-1):label=NAME,state,host)"

# ============================================================================
# UTILITIES
# ============================================================================

# Check project is set
check-project:
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "$(RED)ERROR: PROJECT_ID not set$(NC)"; \
		echo "Usage: make <target> PROJECT_ID=your-project"; \
		exit 1; \
	fi