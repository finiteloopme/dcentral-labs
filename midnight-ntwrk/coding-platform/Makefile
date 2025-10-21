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
	@echo "  $(GREEN)deploy$(NC)        - Deploy to Google Cloud"
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
deploy:
	@./scripts/gcloud-commands.sh deploy



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
