# Web3 Cloud Workstation - Makefile
# Run 'make help' to see all available commands

# Color codes for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Configuration (can be overridden)
PROJECT_ID ?= $(shell gcloud config get-value project 2>/dev/null)
REGION ?= us-central1
REPO_NAME ?= web3-workstation-images
IMAGE_NAME ?= web3-workstation
IMAGE_TAG ?= latest

# Derived variables
REGISTRY_URL := $(REGION)-docker.pkg.dev
FULL_IMAGE_URL := $(REGISTRY_URL)/$(PROJECT_ID)/$(REPO_NAME)/$(IMAGE_NAME):$(IMAGE_TAG)
STATE_BUCKET := $(PROJECT_ID)-web3-workstation-terraform-state
TERRAFORM_DIR := terraform
DOCKER_DIR := docker
SCRIPTS_DIR := scripts

# Auto-detect container runtime
CONTAINER_RUNTIME := $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)
RUNTIME_NAME := $(shell basename $(CONTAINER_RUNTIME) 2>/dev/null || echo "none")

# Default target
.DEFAULT_GOAL := help

# Main targets
.PHONY: help quick-start deploy local clean

##@ Quick Start

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\n${BLUE}Web3 Cloud Workstation${NC}\n\n"} \
	      /^[a-zA-Z_0-9-]+:.*?##/ { printf "  ${GREEN}%-15s${NC} %s\n", $$1, $$2 } \
	      /^##@/ { printf "\n${YELLOW}%s${NC}\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "Configuration: PROJECT_ID=$(PROJECT_ID) REGION=$(REGION)"
	@echo "Container: $(RUNTIME_NAME) | Full docs: make docs"

quick-start: ## Complete setup and deployment (recommended)
	@$(SCRIPTS_DIR)/quick-start.sh

local: ## Run locally without cloud (builds if needed)
	@$(SCRIPTS_DIR)/local-dev.sh run

local-build: ## Build local container image only
	@$(SCRIPTS_DIR)/local-dev.sh build

##@ Core Operations

deploy: ## Deploy to Google Cloud
	@$(SCRIPTS_DIR)/deploy.sh

build: ## Build container image
	@cd $(DOCKER_DIR) && \
	$(CONTAINER_RUNTIME) build -t $(FULL_IMAGE_URL) .

push: ## Push image to registry
	@$(CONTAINER_RUNTIME) push $(FULL_IMAGE_URL)

status: ## Show deployment status
	@$(SCRIPTS_DIR)/status.sh

clean: ## Clean local resources
	@$(SCRIPTS_DIR)/cleanup.sh --local

destroy: ## Destroy cloud infrastructure
	@$(SCRIPTS_DIR)/cleanup.sh --destroy

##@ Development

local-dev: local ## Alias for local development
local-stop: ## Stop local container
	@$(SCRIPTS_DIR)/local-dev.sh stop
local-clean: ## Clean local container
	@$(SCRIPTS_DIR)/local-dev.sh clean
local-debug: ## Debug local networking issues
	@$(SCRIPTS_DIR)/local-dev.sh debug
fix-podman: ## Fix Podman port issues on macOS
	@$(SCRIPTS_DIR)/fix-podman-ports.sh

test: ## Test container image
	@$(SCRIPTS_DIR)/test.sh

##@ Documentation

docs: ## Show all documentation
	@echo "$(BLUE)Available Documentation:$(NC)"
	@echo "  • README.md                - Getting started"
	@echo "  • LOCAL_DEVELOPMENT.md     - Local development guide"  
	@echo "  • MAKEFILE_TARGETS.md      - All Makefile targets"
	@echo "  • CLOUD_BUILD.md           - CI/CD setup"

targets: ## Show all available targets
	@cat MAKEFILE_TARGETS.md

##@ Advanced

terraform-init: ## Initialize Terraform
	@cd $(TERRAFORM_DIR) && \
	terraform init -backend-config="bucket=$(STATE_BUCKET)"

terraform-plan: ## Plan infrastructure changes
	@cd $(TERRAFORM_DIR) && \
	terraform plan

terraform-apply: ## Apply infrastructure changes
	@cd $(TERRAFORM_DIR) && \
	terraform apply

install-deps: ## Install missing dependencies
	@$(SCRIPTS_DIR)/install-dependencies.sh

# Include advanced targets if needed
-include Makefile.advanced