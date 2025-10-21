# ABI Assistant Makefile
# Minimal, clean, and purposeful

.PHONY: help setup dev test build run clean

# Default target
help: ## Show help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Development
setup: ## Initial project setup
	@scripts/podman-setup.sh

dev: ## Run development server
	@scripts/podman-dev.sh

test: ## Run tests
	@scripts/podman-test.sh

build: ## Build release binary
	@scripts/podman-build.sh release

run: ## Run production server
	@scripts/podman-run.sh

# Code Quality
lint: ## Run linter
	@scripts/podman-dev.sh lint

format: ## Format code
	@scripts/podman-dev.sh format

check: ## Run all checks
	@scripts/podman-test.sh full

# Database
db-setup: ## Initialize database
	@scripts/db-setup.sh

db-reset: ## Reset database
	@scripts/db-setup.sh reset

# Container Management
container-build: ## Build containers
	@scripts/podman-build.sh dev

container-shell: ## Enter dev container
	@scripts/podman-dev.sh shell

container-stop: ## Stop all containers
	@scripts/podman-dev.sh stop

# Cleanup
clean: ## Clean everything
	@scripts/podman-clean.sh

# Utilities
coverage: ## Generate test coverage
	@scripts/podman-coverage.sh

doc: ## Generate documentation
	@scripts/podman-dev.sh doc