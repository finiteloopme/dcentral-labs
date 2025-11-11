-include .env

.PHONY: build run stop clean status logs help db restart exec deploy undeploy ws-start ws-stop ws-open ws-tunnel

# ============================================================================
# MAIN COMMANDS
# ============================================================================

# Local dev
build run stop clean status logs db restart exec:
	@./scripts/local.sh $(firstword $(MAKECMDGOALS)) $(filter-out $@,$(MAKECMDGOALS))

# Deploy to Google Cloud using configured environment variables
deploy:
	@./scripts/gcloud-commands.sh deploy

# Undeploy - Clean up all cloud resources
undeploy:
	@./scripts/gcloud-commands.sh undeploy

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
	@./scripts/gcloud-commands.sh ws-open $(WORKSTATION_ID)

# Create tunnel
ws-tunnel:
	@./scripts/gcloud-commands.sh ws-tunnel $(WORKSTATION_ID)

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
	@echo "Current: PROJECT=$(PROJECT_ID)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

.DEFAULT_GOAL := help