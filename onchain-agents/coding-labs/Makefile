# Coding Labs - Makefile
# Multi-agent platform for on-chain development using A2A protocol

.PHONY: help install build dev typecheck lint lint-fix format clean clean-all \
        test test-unit test-unit-watch test-coverage test-integration \
        container-build container-build-opencode up down compose-up compose-down \
        logs shell container-status container-clean \
        health agent-card skills send send-stream \
        opencode-server opencode-web opencode-dev opencode-typecheck opencode-build-frontend

# Default target
.DEFAULT_GOAL := help

# ============================================================================
# Development
# ============================================================================

install: ## Install dependencies
	@./scripts/dev.sh install

build: ## Build all packages
	@./scripts/dev.sh build

dev: ## Run somnia-agent in dev mode
	@./scripts/dev.sh dev

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

compose-up: ## Start all containers with compose
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

opencode-server: ## Run OpenCode server (API only, for development)
	@cd opencode && bun run dev

opencode-web: ## Run OpenCode frontend dev server (requires opencode-server)
	@cd opencode && bun run dev:web

opencode-dev: ## Run OpenCode server with web UI (proxies from app.opencode.ai)
	@cd opencode && bun run dev -- web --hostname 0.0.0.0 --port 4096

opencode-typecheck: ## Typecheck OpenCode
	@cd opencode && bun run typecheck

opencode-build-frontend: ## Build OpenCode frontend
	@cd opencode/packages/app && bun run build

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
# Help
# ============================================================================

help: ## Show this help
	@echo "Coding Labs - Multi-agent platform for on-chain development"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make install              # Install dependencies"
	@echo "  make dev                  # Start somnia-agent in dev mode"
	@echo "  make opencode-server      # Start OpenCode server (API with A2A plugin)"
	@echo "  make opencode-dev         # Start OpenCode with web UI"
	@echo "  make compose-up           # Start all containers"
	@echo "  make send MSG=\"Create an ERC-20 token\"  # Send message to agent"
	@echo ""
	@echo "Development workflow:"
	@echo "  Terminal 1: make dev              # Start Somnia Agent on :4001"
	@echo "  Terminal 2: make opencode-server  # Start OpenCode server on :4096"
	@echo "  Then test A2A tools in OpenCode CLI"
