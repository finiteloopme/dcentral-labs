# Midnight Development Platform

.PHONY: help build deploy undeploy run-local config check-deploy-requirements proof-status proof-test

# Configuration
PROJECT_ID ?= $(shell gcloud config get-value project 2>/dev/null)
REGION ?= us-central1
ENV ?= dev
WORKSTATION_ID ?= midnight-developer-1

# Export for scripts
export PROJECT_ID REGION ENV WORKSTATION_ID

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# Default target
help:
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)     🌙 Midnight Development Platform$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC)"
	@echo "  $(GREEN)deploy$(NC)        - Deploy to Google Cloud (checks requirements first)"
	@echo "  $(GREEN)undeploy$(NC)      - Destroy all cloud resources"
	@echo "  $(GREEN)run-local$(NC)     - Run locally (secure mode)"
	@echo ""
	@echo "$(YELLOW)Workstation:$(NC)"
	@echo "  $(GREEN)ws-start$(NC)      - Start workstation (WORKSTATION_ID=name)"
	@echo "  $(GREEN)ws-stop$(NC)       - Stop workstation (WORKSTATION_ID=name)"
	@echo "  $(GREEN)ws-open$(NC)       - Open Code OSS in browser"
	@echo "  $(GREEN)ws-tunnel$(NC)     - Tunnel to localhost:8080"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  $(GREEN)build$(NC)         - Build container image"
	@echo "  $(GREEN)push$(NC)          - Push to registry"
	@echo "  $(GREEN)status$(NC)        - Show deployment status"
	@echo "  $(GREEN)config$(NC)        - Show current configuration"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  $(GREEN)proof-status$(NC)  - Check proof service status"
	@echo "  $(GREEN)proof-test$(NC)    - Test proof generation"
	@echo ""
	@echo "Current: PROJECT=$(PROJECT_ID)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# MAIN COMMANDS
# ============================================================================

# Deploy to Google Cloud using configured environment variables
deploy: check-deploy-requirements
	@echo "$(GREEN)Deploying to Google Cloud...$(NC)"
	@echo "  Project: $(PROJECT_ID)"
	@echo "  Environment: $(ENV)"
	@echo "  Region: $(REGION)"
	@echo ""
	@gcloud beta builds submit \
		--config=cicd/cloudbuild/cloudbuild.yaml \
		--substitutions="_ENVIRONMENT=$(ENV),_REGION=$(REGION),_ZONE=$(REGION)-a,_TERRAFORM_ACTION=apply,_AUTO_APPROVE=true" \
		--project=$(PROJECT_ID) .

# Check deployment requirements
check-deploy-requirements:
	@echo "$(YELLOW)Checking deployment requirements...$(NC)"
	@# Check if gcloud is installed
	@if ! command -v gcloud >/dev/null 2>&1; then \
		echo "$(RED)Error: gcloud CLI is not installed$(NC)"; \
		echo "Install from: https://cloud.google.com/sdk/docs/install"; \
		exit 1; \
	fi
	@# Check if PROJECT_ID is set
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "$(RED)Error: PROJECT_ID is not set$(NC)"; \
		echo "Run: gcloud config set project YOUR_PROJECT_ID"; \
		echo "Or: export PROJECT_ID=YOUR_PROJECT_ID"; \
		exit 1; \
	fi
	@# Check if authenticated
	@if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then \
		echo "$(RED)Error: Not authenticated with gcloud$(NC)"; \
		echo "Run: gcloud auth login"; \
		exit 1; \
	fi
	@# Check if Cloud Build API is enabled
	@if ! gcloud services list --enabled --filter="name:cloudbuild.googleapis.com" --format="value(name)" 2>/dev/null | grep -q cloudbuild; then \
		echo "$(YELLOW)Warning: Cloud Build API might not be enabled$(NC)"; \
		echo "Enable with: gcloud services enable cloudbuild.googleapis.com"; \
	fi
	@# Check if cloudbuild.yaml exists
	@if [ ! -f "cicd/cloudbuild/cloudbuild.yaml" ]; then \
		echo "$(RED)Error: Cloud Build configuration not found$(NC)"; \
		echo "Expected: cicd/cloudbuild/cloudbuild.yaml"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ All requirements met$(NC)"

# Undeploy - Clean up all cloud resources
undeploy:
	@./scripts/gcloud-commands.sh undeploy

# Run locally (following Cloud Workstations testing guidelines)
run-local:
	@echo "$(GREEN)Running locally...$(NC)"
	@echo "Using --privileged flag as per Cloud Workstations documentation"
	@cd docker && ./run-local.sh

# ============================================================================
# WORKSTATION COMMANDS
# ============================================================================

# Start workstation
ws-start:
	@./scripts/gcloud-commands.sh ws-start $(WORKSTATION_ID)

# Stop workstation
ws-stop:
	@./scripts/gcloud-commands.sh ws-stop $(WORKSTATION_ID)

# Open in browser
ws-open:
	@echo "$(GREEN)Opening Code OSS in browser...$(NC)"
	@./scripts/open-workstation.sh $(WORKSTATION_ID) midnight-dev-cluster midnight-dev-config $(REGION)

# Create tunnel
ws-tunnel:
	@./scripts/gcloud-commands.sh ws-tunnel $(WORKSTATION_ID)

# ============================================================================
# CONFIGURATION COMMANDS
# ============================================================================



# ============================================================================
# UTILITIES
# ============================================================================

# Build container using configured environment variables
build:
	@echo "$(GREEN)Building container...$(NC)"
	@echo "  Includes integrated mock proof server (port 8081)"
	@cd docker && ./build.sh

# ============================================================================
# DEPLOYMENT COMMANDS
# ============================================================================

# Push to registry
push: check-project
	@echo "$(GREEN)Pushing to registry...$(NC)"
	@./scripts/push.sh $(PROJECT_ID) $(REGION)

# Show deployment status
status:
	@./scripts/gcloud-commands.sh status $(WORKSTATION_ID)

# Show current configuration
config:
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)Current Configuration$(NC)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "$(YELLOW)Google Cloud:$(NC)"
	@echo "  PROJECT_ID: $(PROJECT_ID)"
	@echo "  REGION: $(REGION)"
	@echo "  WORKSTATION_ID: $(WORKSTATION_ID)"
	@echo ""
	@echo "$(YELLOW)Proof Service:$(NC)"
	@echo "  Internal mock server on port 8081 (container)"
	@echo "  Automatic for all projects"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Proof service targets
proof-status:
	@echo "$(GREEN)Checking proof service status...$(NC)"
	@if [ -f /docker/scripts/proof-service-manager.sh ]; then \
		/docker/scripts/proof-service-manager.sh status; \
	else \
		echo "Proof server runs automatically inside container on port 8081"; \
		echo "Check with: curl http://localhost:8081/health"; \
	fi

proof-test:
	@echo "$(GREEN)Testing proof service...$(NC)"
	@if [ -f /docker/scripts/proof-service-manager.sh ]; then \
		/docker/scripts/proof-service-manager.sh test; \
	else \
		echo "Creating test proof..."; \
		echo '{"test": "data"}' > test-circuit.json; \
		./docker/scripts/prove.sh test-circuit.json && \
		echo "$(GREEN)✓ Proof generation working$(NC)" && \
		rm -f test-circuit.json proof.json; \
	fi

