.PHONY: all help setup init deploy build push status clean destroy

# Configuration
PROJECT_ID ?= $(shell gcloud config get-value project 2>/dev/null)
REGION ?= us-central1
ZONE ?= us-central1-a
ENV ?= mvp

# Export for scripts
export PROJECT_ID REGION ZONE ENV

# Default target
all: help

# Help
help:
	@echo "Midnight Development Platform - MVP"
	@echo "===================================="
	@echo ""
	@echo "Quick Start:"
	@echo "  make setup PROJECT_ID=your-project-id"
	@echo ""
	@echo "Core Commands:"
	@echo "  help       - Show this help message"
	@echo "  setup      - Complete setup (init, deploy, build, push)"
	@echo "  init       - Initialize Terraform with GCS backend"
	@echo "  deploy     - Deploy infrastructure"
	@echo "  build      - Build container image"
	@echo "  push       - Push image to registry"
	@echo "  run-local  - Run container locally for testing"
	@echo "  status     - Check deployment status"
	@echo "  clean      - Clean local artifacts"
	@echo "  destroy    - Destroy infrastructure"
	@echo ""
	@echo "Workstation Commands:"
	@echo "  workstation    - Show workstation management help"
	@echo "  list           - List all workstations"
	@echo "  start          - Start default workstation"
	@echo "  stop           - Stop default workstation"
	@echo "  ssh            - SSH into workstation"
	@echo "  logs           - View workstation logs"
	@echo "  port-forward   - Set up port forwarding"
	@echo ""
	@echo "For advanced workstation management:"
	@echo "  ./scripts/workstation.sh --help"
	@echo ""
	@echo "Current Settings:"
	@echo "  PROJECT_ID: $(PROJECT_ID)"
	@echo "  REGION: $(REGION)"
	@echo "  ENV: $(ENV)"

# Complete setup
setup: init deploy build push status
	@echo "✅ Setup complete!"

# Initialize Terraform
init:
	@./scripts/terraform-init.sh "$(PROJECT_ID)"

# Deploy infrastructure
deploy:
	@./scripts/terraform-deploy.sh "$(PROJECT_ID)" "$(REGION)" "$(ZONE)" "$(ENV)"

# Build container
build:
	@./scripts/build.sh

# Push to registry
push:
	@./scripts/push.sh

# Check status
status:
	@./scripts/status.sh "$(PROJECT_ID)" "$(ENV)" "$(REGION)"

# Run container locally for testing
run-local:
	@./scripts/run-local.sh

# Clean artifacts
clean:
	@./scripts/clean.sh

# Show container runtime info
runtime-info:
	@echo "Container Runtime Detection:"
	@./scripts/container-runtime.sh || echo "No container runtime found"
	@echo ""
	@if command -v podman >/dev/null 2>&1; then \
		echo "Podman Version:"; \
		podman --version; \
	elif command -v docker >/dev/null 2>&1; then \
		echo "Docker Version:"; \
		docker --version; \
	fi

# Destroy infrastructure
destroy:
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	@cd terraform && terraform destroy \
		-var="project_id=$(PROJECT_ID)" \
		-var="region=$(REGION)" \
		-var="zone=$(ZONE)" \
		-var="environment=$(ENV)" \
		-auto-approve

# Workstation management (using workstation.sh script)
workstation:
	@./scripts/workstation.sh --help

list:
	@./scripts/workstation.sh list

start:
	@./scripts/workstation.sh start

stop:
	@./scripts/workstation.sh stop

ssh:
	@./scripts/workstation.sh ssh

logs:
	@./scripts/workstation.sh logs

port-forward:
	@./scripts/workstation.sh port-forward