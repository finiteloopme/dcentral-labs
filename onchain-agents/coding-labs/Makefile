# Coding Labs - Makefile
# Runtimes: local, container, cloud
# Operations: clean, build, test, run

.PHONY: help install clean build test run dev lint \
        container-clean container-build container-run container-stop container-logs \
        up down rebuild logs \
        cloud-setup cloud-deploy cloud-sync-users \
        cloud-status cloud-urls cloud-logs cloud-teardown \
        cloud-setup-project cloud-setup-dns cloud-setup-lb cloud-setup-auth \
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
# CLOUD (Cloud Run + LB + IAP + GCIP)
# =============================================================================
# Operator workflow:
#   1. make cloud-setup       (one-time bootstrap: project + DNS + LB + auth)
#   2. make cloud-deploy      (build + deploy services; auto Firebase substitutions)
#   3. make cloud-sync-users  (bind allowed_users from config.toml to IAP IAM)

cloud-setup: ## One-time bootstrap (project + DNS + LB + auth)
	@./scripts/cloud.sh setup

cloud-deploy: ## Build + deploy services (auto-supplies Firebase substitutions)
	@./scripts/cloud.sh deploy

cloud-sync-users: ## Sync allowed_users from config.toml to IAP IAM
	@./scripts/cloud.sh sync-users

cloud-status: ## Show Cloud Run service status
	@./scripts/cloud.sh status

cloud-urls: ## Show Cloud Run service URLs
	@./scripts/cloud.sh urls

cloud-logs: ## View Cloud Run logs (SVC=service-name)
	@./scripts/cloud.sh logs $(SVC)

cloud-teardown: ## DESTRUCTIVE: Tear down all infrastructure (LB + Cloud Run services)
	@./scripts/cloud.sh teardown

# Advanced sub-targets (called by cloud-setup; useful for recovery)
cloud-setup-project: ## (advanced) Project APIs + IAM only
	@./scripts/cloud.sh setup-project

cloud-setup-dns: ## (advanced) Cross-project DNS A record only
	@./scripts/cloud.sh setup-dns

cloud-setup-lb: ## (advanced) LB resources + URL map + IAP enable
	@./scripts/cloud.sh setup-lb

cloud-setup-auth: ## (advanced) GCIP Google IdP + authorizedDomains + IAP gcipSettings
	@./scripts/cloud.sh setup-auth

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
	@echo "Cloud workflow (3 commands; no manual gcloud follow-ups):"
	@echo "  1. make cloud-setup        # One-time bootstrap (project + DNS + LB + auth)"
	@echo "  2. make cloud-deploy       # Build + deploy services (auto Firebase config)"
	@echo "  3. make cloud-sync-users   # Bind allowed_users from config.toml to IAP IAM"
	@echo ""
	@echo "Pre-setup: fill config.toml [default.dns] + [default.auth.google].client_id,"
	@echo "and copy .env.example to .env with GOOGLE_OAUTH_CLIENT_SECRET. See"
	@echo "gcip-google-signin-setup.md for the full operator flow."
	@echo ""
	@echo "Local:"
	@grep -E '^(install|clean|build|test|run|dev|lint):.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Container:"
	@grep -E '^(container-[a-z]+|up|down|logs|rebuild):.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Cloud:"
	@grep -E '^cloud-.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Utilities:"
	@grep -E '^(config|health|send):.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make run                    # Start all services locally"
	@echo "  make rebuild                # Build and start containers"
	@echo "  make cloud-setup            # One-time cloud setup"
	@echo "  make cloud-deploy           # Deploy to Cloud Run"
	@echo "  make send MSG=\"Create an ERC-20 token\""
