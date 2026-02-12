# Coding Labs - Makefile
# Multi-agent platform for on-chain development using A2A protocol

.PHONY: help install build dev typecheck lint lint-fix format clean clean-all \
        test test-unit test-unit-watch test-coverage test-integration \
        container-build container-build-opencode up down \
        compose-build compose-up compose-rebuild compose-down \
        logs shell container-status container-clean \
        health agent-card skills send send-stream \
        opencode-server opencode-frontend opencode-typecheck \
        generate-config registry-dev

# ============================================================================
# Configuration
# ============================================================================

# Default ports - override via CLI: make opencode-server OPENCODE_PORT=4098
OPENCODE_PORT ?= 4097

# Default target
.DEFAULT_GOAL := help

# ============================================================================
# Configuration Management
# ============================================================================

generate-config: ## Generate .env.generated from config.toml
	@bun scripts/generate-env.ts
	@echo "Generated .env.generated"

generate-config-prod: ## Generate production .env.generated from config.toml
	@bun scripts/generate-env.ts --env=production
	@echo "Generated .env.generated for production"

# ============================================================================
# Development
# ============================================================================

install: ## Install dependencies
	@./scripts/dev.sh install

build: ## Build all packages
	@./scripts/dev.sh build

dev: ## Run somnia-agent in dev mode
	@./scripts/dev.sh dev

registry-dev: ## Run agent-registry in dev mode
	@cd packages/agent-registry && npx tsx src/index.ts

typecheck: ## Run TypeScript type checking
	@./scripts/dev.sh typecheck

lint: ## Run ESLint
	@./scripts/dev.sh lint

lint-fix: ## Run ESLint with auto-fix
	@./scripts/dev.sh lint-fix

format: ## Format code with Prettier
	@./scripts/dev.sh format

clean: ## Clean build artifacts
	@./scripts/dev.sh clean

clean-all: ## Clean all including node_modules
	@./scripts/dev.sh clean-all

# ============================================================================
# Testing
# ============================================================================

test: ## Run all tests
	@./scripts/test.sh all

test-unit: ## Run unit tests
	@./scripts/test.sh unit

test-unit-watch: ## Run unit tests in watch mode
	@./scripts/test.sh unit-watch

test-coverage: ## Run unit tests with coverage
	@./scripts/test.sh unit-coverage

test-integration: ## Run integration tests (requires running agent)
	@./scripts/test.sh integration

# ============================================================================
# Containers (Podman)
# ============================================================================

container-build: ## Build all container images
	@./scripts/container.sh build

container-build-opencode: ## Build OpenCode web container only
	@./scripts/container.sh build-opencode

up: ## Start somnia-agent container
	@./scripts/container.sh up

down: ## Stop containers
	@./scripts/container.sh down

compose-build: ## Build all container images with compose
	@./scripts/container.sh compose-build

compose-up: generate-config ## Start all containers with compose (generates .env.generated first)
	@./scripts/container.sh compose-up

compose-rebuild: generate-config compose-build ## Build and start all containers (use after code changes)
	@./scripts/container.sh compose-up

compose-down: ## Stop all containers with compose
	@./scripts/container.sh compose-down

logs: ## View container logs (follow)
	@./scripts/container.sh logs

shell: ## Shell into somnia-agent container
	@./scripts/container.sh shell

container-status: ## Show container and image status
	@./scripts/container.sh status

container-clean: ## Stop containers and remove images
	@./scripts/container.sh clean

# ============================================================================
# OpenCode (Forked)
# ============================================================================

opencode-server: ## Run OpenCode server (default port 4097, override with OPENCODE_PORT=)
	@cd opencode && bun run dev -- web --hostname 0.0.0.0 --port $(OPENCODE_PORT)

opencode-frontend: ## Run OpenCode frontend (config.toml defaults, override with PORT=/ENV=)
	@cd opencode/packages/app && \
	  $(if $(PORT),VITE_OPENCODE_SERVER_PORT=$(PORT)) \
	  $(if $(ENV),VITE_APP_ENV=$(ENV)) \
	  bun run dev

opencode-typecheck: ## Typecheck OpenCode
	@cd opencode && bun run typecheck

# ============================================================================
# A2A Agent
# ============================================================================

health: ## Check agent health
	@./scripts/a2a.sh health

agent-card: ## Fetch and display agent card
	@./scripts/a2a.sh agent-card

skills: ## List agent skills
	@./scripts/a2a.sh skills

send: ## Send message to agent (usage: make send MSG="your message")
	@./scripts/a2a.sh send "$(MSG)"

send-stream: ## Send message with streaming (usage: make send-stream MSG="your message")
	@./scripts/a2a.sh send-stream "$(MSG)"

# ============================================================================
# Agent Registry
# ============================================================================

registry-health: ## Check agent registry health
	@curl -s http://localhost:4000/health | jq .

registry-agents: ## List agents from registry
	@curl -s http://localhost:4000/agents | jq .

# ============================================================================
# Help
# ============================================================================

help: ## Show this help
	@echo "Coding Labs - Multi-agent platform for on-chain development"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make install              # Install dependencies"
	@echo "  make dev                  # Start somnia-agent in dev mode"
	@echo "  make registry-dev         # Start agent-registry in dev mode"
	@echo "  make opencode-server      # Start OpenCode server (API with A2A plugin)"
	@echo "  make opencode-frontend    # Start OpenCode web frontend"
	@echo "  make compose-rebuild      # Build and start all containers"
	@echo "  make compose-up           # Start all containers (no rebuild)"
	@echo "  make send MSG=\"Create an ERC-20 token\"  # Send message to agent"
	@echo ""
	@echo "Local integration testing (4 terminals):"
	@echo "  Terminal 1: make registry-dev      # Agent Registry on :4000"
	@echo "  Terminal 2: make dev               # Somnia Agent on :4001"
	@echo "  Terminal 3: make opencode-server   # OpenCode backend on :4097"
	@echo "  Terminal 4: make opencode-frontend # OpenCode web UI on :3000"
	@echo "  Then open http://localhost:3000 in browser"
	@echo ""
	@echo "Configuration:"
	@echo "  make generate-config               # Generate .env.generated from config.toml"
	@echo "  make generate-config-prod          # Generate production config"
	@echo ""
	@echo "Configuration overrides:"
	@echo "  make opencode-server OPENCODE_PORT=4098  # Use custom server port"
	@echo "  make opencode-frontend PORT=4098         # Connect to custom server port"
	@echo "  make opencode-frontend ENV=production    # Use production config"
