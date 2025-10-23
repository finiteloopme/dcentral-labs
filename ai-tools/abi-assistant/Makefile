# ABI Assistant Makefile
# Minimal, clean, and purposeful

.PHONY: help setup dev test build run clean

# Default target
help: ## Show help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Development
setup: ## Initial project setup
	@scripts/container.sh setup

dev: ## Run development server (local)
	@scripts/dev.sh

dev-container: ## Run development server (container)
	@scripts/container.sh run dev

test: ## Run tests (local)
	@scripts/test.sh quick

test-full: ## Run full test suite
	@scripts/test.sh full

test-mcp: ## Test MCP server endpoints
	@scripts/test-mcp.sh

build: ## Build release binary
	@scripts/container.sh build prod

run: ## Run production server
	@scripts/container.sh run prod

# Code Quality
lint: ## Run linter
	@scripts/container.sh lint

format: ## Format code
	@scripts/container.sh format

check: ## Run all checks
	@scripts/test.sh full

# Database
db-setup: ## Initialize database
	@scripts/db-setup.sh

db-reset: ## Reset database
	@scripts/db-setup.sh reset

# Testing with Anvil
anvil: ## Start Anvil local blockchain
	@scripts/anvil.sh start

anvil-fork: ## Start Anvil with mainnet fork
	@scripts/anvil.sh fork

anvil-stop: ## Stop Anvil container
	@scripts/anvil.sh stop

anvil-status: ## Check Anvil status
	@scripts/anvil.sh status

# Container Management
container-build: ## Build containers
	@scripts/container.sh build dev

container-shell: ## Enter dev container
	@scripts/container.sh shell

container-stop: ## Stop all containers
	@scripts/container.sh stop

container-clean: ## Clean containers and artifacts
	@scripts/container.sh clean

docker-compose: ## Run with docker-compose
	@scripts/docker-compose.sh up

# Cleanup
clean: ## Clean everything
	@scripts/container.sh clean

# Utilities
coverage: ## Generate test coverage
	@scripts/container.sh coverage

doc: ## Generate documentation
	@cargo doc --open