# Coding Labs - Makefile
# Runtimes: local, container, cloud
# Operations: clean, build, test, run

.PHONY: help install clean build test run dev lint \
        container-clean container-build container-run container-stop container-logs \
        up down rebuild logs \
        cloud-build cloud-deploy \
        config health send

.DEFAULT_GOAL := help

# =============================================================================
# LOCAL
# =============================================================================

install: ## Install all dependencies
	@./scripts/dev.sh install

clean: ## Clean build artifacts and node_modules
	@./scripts/dev.sh clean-all

build: ## Build all packages
	@./scripts/dev.sh build

test: ## Run all tests
	@./scripts/test.sh all

run: ## Run all services (registry + agent + opencode)
	@./scripts/dev.sh run-all

dev: run ## Alias for run

lint: ## Lint and format code
	@./scripts/dev.sh lint-fix
	@./scripts/dev.sh format

# =============================================================================
# CONTAINER
# =============================================================================

container-clean: ## Remove containers and images
	@./scripts/container.sh clean

container-build: config ## Build all container images
	@./scripts/container.sh compose-build

container-run: config ## Start all containers
	@./scripts/container.sh compose-up

container-stop: ## Stop all containers
	@./scripts/container.sh compose-down

container-logs: ## View container logs
	@./scripts/container.sh logs

# Aliases
up: container-run ## Start containers (alias)
down: container-stop ## Stop containers (alias)
logs: container-logs ## View logs (alias)
rebuild: container-build container-run ## Build and start containers

# =============================================================================
# CLOUD (Cloud Run)
# =============================================================================

cloud-build: ## Build for Cloud Run (stub)
	@echo "TODO: Build and push to gcr.io"

cloud-deploy: ## Deploy to Cloud Run (stub)
	@echo "TODO: Deploy to Cloud Run"

# =============================================================================
# UTILITIES
# =============================================================================

config: ## Generate .env.generated from config.toml
	@bun scripts/generate-env.ts

health: ## Check health of all services
	@./scripts/a2a.sh health

send: ## Send A2A message (usage: make send MSG="...")
	@./scripts/a2a.sh send "$(MSG)"

# =============================================================================
# HELP
# =============================================================================

help: ## Show this help
	@echo "Coding Labs - Multi-agent platform for on-chain development"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Local:"
	@grep -E '^(install|clean|build|test|run|dev|lint):.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Container:"
	@grep -E '^(container-[a-z]+|up|down|logs|rebuild):.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Cloud:"
	@grep -E '^cloud-.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Utilities:"
	@grep -E '^(config|health|send):.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make run                    # Start all services locally"
	@echo "  make rebuild                # Build and start containers"
	@echo "  make send MSG=\"Create an ERC-20 token\""
