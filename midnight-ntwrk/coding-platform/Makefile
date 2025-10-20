# Midnight Development Platform

.PHONY: help build deploy run-local

# Configuration
PROJECT_ID ?= $(shell gcloud config get-value project 2>/dev/null)
REGION ?= us-central1
ENV ?= dev

# Export for scripts
export PROJECT_ID REGION ENV

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
	@echo "  $(GREEN)deploy$(NC)        - Deploy to Google Cloud"
	@echo "  $(GREEN)run-local$(NC)     - Run locally (secure mode)"
	@echo ""
	@echo "$(YELLOW)Workstation:$(NC)"
	@echo "  $(GREEN)ws-start$(NC)      - Start workstation"
	@echo "  $(GREEN)ws-stop$(NC)       - Stop workstation"
	@echo "  $(GREEN)ws-open$(NC)       - Open Code OSS in browser"
	@echo "  $(GREEN)ws-tunnel$(NC)     - Tunnel to localhost:8080"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  $(GREEN)build$(NC)         - Build container image"
	@echo "  $(GREEN)push$(NC)          - Push to registry"
	@echo "  $(GREEN)status$(NC)        - Show deployment status"
	@echo ""
	@echo "Project: $(PROJECT_ID)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# MAIN COMMANDS
# ============================================================================

# Deploy everything to Google Cloud
deploy: check-project
	@echo "$(GREEN)Deploying to Google Cloud...$(NC)"
	@gcloud beta builds submit \
		--config=cicd/cloudbuild/cloudbuild.yaml \
		--substitutions="_ENVIRONMENT=$(ENV),_REGION=$(REGION),_ZONE=$(REGION)-a,_TERRAFORM_ACTION=apply,_AUTO_APPROVE=true" \
		--project=$(PROJECT_ID) .

# Run locally (following Cloud Workstations testing guidelines)
run-local:
	@echo "$(GREEN)Running locally...$(NC)"
	@echo "Using --privileged flag as per Cloud Workstations documentation"
	@cd docker && ./run-local.sh

# ============================================================================
# WORKSTATION COMMANDS
# ============================================================================

# Start workstation
ws-start: check-project
	@echo "$(GREEN)Starting workstation...$(NC)"
	@gcloud workstations start midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=$(REGION) \
		--project=$(PROJECT_ID)

# Stop workstation
ws-stop: check-project
	@echo "$(YELLOW)Stopping workstation...$(NC)"
	@gcloud workstations stop midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=$(REGION) \
		--project=$(PROJECT_ID) \
		--quiet

# Open in browser
ws-open: check-project
	@echo "$(GREEN)Opening Code OSS in browser...$(NC)"
	@./scripts/open-workstation.sh midnight-developer-1 midnight-dev-cluster midnight-dev-config $(REGION)

# Create tunnel
ws-tunnel: check-project
	@echo "$(GREEN)Creating tunnel to Code OSS...$(NC)"
	@echo "Access at: http://localhost:8080"
	@gcloud workstations start-tcp-tunnel midnight-developer-1 80 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=$(REGION) \
		--project=$(PROJECT_ID) \
		--local-host-port=localhost:8080

# ============================================================================
# DEVELOPMENT COMMANDS
# ============================================================================

# Build container
build:
	@echo "$(GREEN)Building container...$(NC)"
	@cd docker && ./build.sh

# Push to registry
push: check-project
	@echo "$(GREEN)Pushing to registry...$(NC)"
	@./scripts/push.sh $(PROJECT_ID) $(REGION)

# Show status
status: check-project
	@echo "$(GREEN)Deployment status:$(NC)"
	@gcloud workstations describe midnight-developer-1 \
		--cluster=midnight-dev-cluster \
		--config=midnight-dev-config \
		--region=$(REGION) \
		--project=$(PROJECT_ID) \
		--format="table(name.segment(-1):label=WORKSTATION,state,host)" 2>/dev/null || echo "Workstation not found"
	@echo ""
	@echo "$(GREEN)Recent builds:$(NC)"
	@gcloud builds list --limit=3 --project=$(PROJECT_ID) \
		--format="table(id,status,createTime.date())"

# ============================================================================
# UTILITIES
# ============================================================================

# Check project is set
check-project:
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "ERROR: Set PROJECT_ID or run: gcloud config set project YOUR_PROJECT"; \
		exit 1; \
	fi