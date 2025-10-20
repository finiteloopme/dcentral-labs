# Midnight Development Platform
# Essential build and deployment commands

.PHONY: help setup deploy build test clean

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
	@echo "$(YELLOW)Essential Commands:$(NC)"
	@echo "  $(GREEN)setup$(NC)         - Complete platform setup (terraform + container)"
	@echo "  $(GREEN)deploy$(NC)        - Deploy infrastructure"
	@echo "  $(GREEN)build$(NC)         - Build container image"
	@echo "  $(GREEN)push$(NC)          - Push image to registry"
	@echo "  $(GREEN)test$(NC)          - Run tests"
	@echo ""
	@echo "$(YELLOW)Cloud Build:$(NC)"
	@echo "  $(GREEN)cloud-setup$(NC)   - Configure Cloud Build"
	@echo "  $(GREEN)cloud-deploy$(NC)  - Deploy via Cloud Build"
	@echo "  $(GREEN)cloud-status$(NC)  - Check build status"
	@echo ""
	@echo "$(YELLOW)Local Development:$(NC)"
	@echo "  $(GREEN)run-local$(NC)     - Run container locally"
	@echo "  $(GREEN)compose-up$(NC)    - Start Docker Compose services"
	@echo ""
	@echo "$(YELLOW)Workstations:$(NC)"
	@echo "  $(GREEN)ws-list$(NC)       - List workstations"
	@echo "  $(GREEN)ws-start$(NC)      - Start workstation"
	@echo "  $(GREEN)ws-ssh$(NC)        - SSH into workstation"
	@echo ""
	@echo "Current: PROJECT_ID=$(PROJECT_ID) ENV=$(ENV)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# CORE COMMANDS
# ============================================================================

# Complete setup
setup: check-project
	@./scripts/terraform-init.sh $(PROJECT_ID) $(REGION) $(ZONE) $(ENV)
	@./scripts/deploy.sh $(PROJECT_ID) $(REGION) $(ZONE) $(ENV)
	@./scripts/build.sh
	@./scripts/push.sh $(PROJECT_ID) $(REGION)
	@echo "$(GREEN)✅ Setup complete!$(NC)"

# Deploy infrastructure
deploy: check-project
	@./scripts/deploy.sh $(PROJECT_ID) $(REGION) $(ZONE) $(ENV)

# Build container
build:
	@./scripts/build.sh

# Push to registry
push: check-project
	@./scripts/push.sh $(PROJECT_ID) $(REGION)

# Run tests
test:
	@./scripts/test-integration.sh

# Clean artifacts
clean:
	@./scripts/clean.sh
	@rm -rf terraform/.terraform terraform/*.tfplan

# ============================================================================
# CLOUD BUILD
# ============================================================================

# Setup Cloud Build
cloud-setup: check-project
	@./scripts/setup-cloudbuild-simple.sh $(PROJECT_ID) $(REGION)

# Deploy via Cloud Build (moved to Cloud Build section below)

# Cloud Build status
cloud-status: check-project
	@echo "$(YELLOW)Recent builds:$(NC)"
	@gcloud builds list --limit=5 --project=$(PROJECT_ID) --format="table(id,status,createTime.date())"

# Diagnose Cloud Build
cloud-diagnose: check-project
	@./scripts/cloud-diagnostics.sh $(PROJECT_ID)

# Import existing resources into Terraform state
cloud-import: check-project
	@echo "$(YELLOW)Importing existing resources into Terraform state...$(NC)"
	@gcloud builds submit \
		--config=cicd/cloudbuild/cloudbuild-import.yaml \
		--substitutions="_ENVIRONMENT=$(ENV),_REGION=$(REGION),_ZONE=$(ZONE)" \
		--project=$(PROJECT_ID) .

# ============================================================================
# LOCAL DEVELOPMENT
# ============================================================================

# Run locally with full Cloud Workstations emulation
run-local:
	@./scripts/run-local.sh

# Run locally with simplified startup (recommended for development)
run-local-simple:
	@cd docker && ./run-local-simple.sh

# Docker Compose
compose-up:
	@cd docker && docker-compose up -d

compose-down:
	@cd docker && docker-compose down

compose-logs:
	@cd docker && docker-compose logs -f

# ============================================================================
# CLOUD BUILD
# ============================================================================

cloud-deploy:
	@echo "$(GREEN)[INFO]$(NC) Deploying to Cloud with detailed logging..."
	@gcloud beta builds submit \
		--config cicd/cloudbuild/cloudbuild.yaml \
		--substitutions=_SERVICE_ACCOUNT=midnight-cloudbuild-sa@$(PROJECT_ID).iam.gserviceaccount.com,_AUTO_APPROVE=true,_TERRAFORM_ACTION=apply \
		.

cloud-deploy-plan:
	@echo "$(GREEN)[INFO]$(NC) Planning Cloud deployment..."
	@gcloud beta builds submit \
		--config cicd/cloudbuild/cloudbuild.yaml \
		--substitutions=_SERVICE_ACCOUNT=midnight-cloudbuild-sa@$(PROJECT_ID).iam.gserviceaccount.com,_AUTO_APPROVE=false,_TERRAFORM_ACTION=plan \
		.

# ============================================================================
# WORKSTATION MANAGEMENT
# ============================================================================

ws-list:
	@./scripts/workstation.sh list

ws-start:
	@./scripts/workstation.sh start

ws-stop:
	@./scripts/workstation.sh stop

ws-ssh:
	@./scripts/workstation.sh ssh

ws-restart:
	@echo "$(GREEN)[INFO]$(NC) Restarting workstation to pick up new image..."
	@gcloud workstations stop midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=us-central1 \
		--quiet || true
	@echo "$(YELLOW)[INFO]$(NC) Waiting for workstation to stop..."
	@sleep 30
	@gcloud workstations start midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=us-central1
	@echo "$(GREEN)✅ Workstation restarted$(NC)"

ws-status:
	@gcloud workstations describe midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=us-central1 \
		--format="table(name.segment(-1):label=NAME,state,host)"

ws-url:
	@./scripts/workstation.sh url

# ============================================================================
# UTILITIES
# ============================================================================

# Check project
check-project:
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "$(RED)ERROR: PROJECT_ID not set$(NC)"; \
		echo "Usage: make <target> PROJECT_ID=your-project"; \
		exit 1; \
	fi

# Show status
status: check-project
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