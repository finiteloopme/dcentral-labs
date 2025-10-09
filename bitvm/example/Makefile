# BitVM3 Tverification-engineless Vault - Makefile
# Simplifies development and operational tasks

# Check if podman is available, fall back to docker if not
CONTAINER_ENGINE := $(shell command -v podman 2> /dev/null || echo docker)
COMPOSE_ENGINE := $(shell command -v podman-compose 2> /dev/null || echo docker-compose)

.PHONY: help
help: ## Show this help message
	@echo "BitVM3 Tverification-engineless Vault - Development & Operations"
	@echo "=================================================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick Start:"
	@echo "  make install      # Install all dependencies"
	@echo "  make dev          # Start development environment"
	@echo "  make test         # Run all tests"

# =============================================================================
# VARIABLES
# =============================================================================

VERIFIER_DIR := verification-engine
PROTOCOL_DIR := vault-protocol
DOCKER_COMPOSE := $(COMPOSE_ENGINE)
CARGO := cargo
NPM := npm
DOCKER := $(CONTAINER_ENGINE)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# =============================================================================
# INSTALLATION & SETUP
# =============================================================================

.PHONY: setup-podman
setup-podman: ## Install and configure Podman
	@echo "$(BLUE)🔧 Setting up Podman...$(NC)"
	@bash scripts/setup-podman.sh
	@echo "$(GREEN)✅ Podman setup complete$(NC)"

.PHONY: install
install: install-verification-engine install-ts ## Install all dependencies
	@echo "$(GREEN)✅ All dependencies installed$(NC)"

.PHONY: install-verification-engine
install-verification-engine: ## Install Verification Engine dependencies
	@echo "$(BLUE)📦 Installing Verification Engine dependencies...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) fetch
	@echo "$(GREEN)✅ Verification Engine dependencies installed$(NC)"

.PHONY: install-ts
install-ts: ## Install Vault Protocol dependencies
	@echo "$(BLUE)📦 Installing Vault Protocol dependencies...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) install
	@echo "$(GREEN)✅ Vault Protocol dependencies installed$(NC)"

.PHONY: setup
setup: install setup-bitcoin setup-db ## Complete project setup
	@echo "$(GREEN)✅ Project setup complete$(NC)"

.PHONY: setup-bitcoin
setup-bitcoin: ## Setup Bitcoin regtest node
	@echo "$(BLUE)🔧 Setting up Bitcoin regtest...$(NC)"
	@$(DOCKER) run -d --name bitcoin-regtest \
		-p 18443:18443 -p 18444:18444 \
		docker.io/ruimarinho/bitcoin-core:latest \
		-regtest -server -rpcuser=bitvm3 -rpcpassword=password \
		-rpcallowip=0.0.0.0/0 -rpcbind=0.0.0.0
	@echo "$(GREEN)✅ Bitcoin regtest running$(NC)"

.PHONY: setup-db
setup-db: ## Setup PostgreSQL database
	@echo "$(BLUE)🔧 Setting up PostgreSQL...$(NC)"
	@$(DOCKER) run -d --name bitvm3-postgres \
		-e POSTGRES_USER=bitvm3 \
		-e POSTGRES_PASSWORD=password \
		-e POSTGRES_DB=bitvm3 \
		-p 5432:5432 \
		docker.io/postgres:16-alpine
	@echo "$(GREEN)✅ PostgreSQL running$(NC)"

# =============================================================================
# BUILD
# =============================================================================

.PHONY: build
build: build-verification-engine build-ts ## Build all components
	@echo "$(GREEN)✅ Build complete$(NC)"

.PHONY: build-verification-engine
build-verification-engine: ## Build Verification Engine backend
	@echo "$(BLUE)🔨 Building Verification Engine backend...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) build --release
	@echo "$(GREEN)✅ Verification Engine backend built$(NC)"

.PHONY: build-ts
build-ts: ## Build Vault Protocol frontend
	@echo "$(BLUE)🔨 Building Vault Protocol frontend...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) run build
	@echo "$(GREEN)✅ Vault Protocol frontend built$(NC)"

.PHONY: build-docker
build-docker: ## Build Docker images
	@echo "$(BLUE)🐳 Building Docker images...$(NC)"
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)✅ Docker images built$(NC)"

# =============================================================================
# DEVELOPMENT
# =============================================================================

.PHONY: dev
dev: ## Start development environment (all services)
	@echo "$(BLUE)🚀 Starting development environment...$(NC)"
	@make -j2 dev-verification-engine dev-ts

.PHONY: dev-verification-engine
dev-verification-engine: ## Start Verification Engine backend in development mode
	@echo "$(BLUE)🦀 Starting Verification Engine backend...$(NC)"
	@cd $(VERIFIER_DIR) && RUST_LOG=debug $(CARGO) run --bin bitvm3-server

.PHONY: dev-ts
dev-ts: ## Start Vault Protocol frontend in development mode
	@echo "$(BLUE)📘 Starting Vault Protocol frontend...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) run dev

.PHONY: dev-docker
dev-docker: ## Start development environment with Docker
	@echo "$(BLUE)🐳 Starting Docker development environment...$(NC)"
	@$(DOCKER_COMPOSE) up

.PHONY: watch
watch: ## Watch for changes and rebuild
	@echo "$(BLUE)👁️  Watching for changes...$(NC)"
	@make -j2 watch-verification-engine watch-ts

.PHONY: watch-verification-engine
watch-verification-engine: ## Watch Verification Engine files for changes
	@cd $(VERIFIER_DIR) && $(CARGO) watch -x "build --release"

.PHONY: watch-ts
watch-ts: ## Watch Vault Protocol files for changes
	@cd $(PROTOCOL_DIR) && $(NPM) run watch

# =============================================================================
# TESTING
# =============================================================================

.PHONY: test
test: test-verification-engine test-ts ## Run all tests
	@echo "$(GREEN)✅ All tests passed$(NC)"

.PHONY: test-verification-engine
test-verification-engine: ## Run Verification Engine tests
	@echo "$(BLUE)🧪 Running Verification Engine tests...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) test --workspace
	@echo "$(GREEN)✅ Verification Engine tests passed$(NC)"

.PHONY: test-ts
test-ts: ## Run Vault Protocol tests
	@echo "$(BLUE)🧪 Running Vault Protocol tests...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) test
	@echo "$(GREEN)✅ Vault Protocol tests passed$(NC)"

.PHONY: test-integration
test-integration: ## Run integration tests
	@echo "$(BLUE)🧪 Running integration tests...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) run test:integration
	@echo "$(GREEN)✅ Integration tests passed$(NC)"

.PHONY: test-e2e
test-e2e: ## Run end-to-end tests
	@echo "$(BLUE)🧪 Running E2E tests...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@sleep 5
	@cd $(PROTOCOL_DIR) && $(NPM) run test:e2e
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✅ E2E tests passed$(NC)"

.PHONY: bench
bench: ## Run benchmarks
	@echo "$(BLUE)📊 Running benchmarks...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) bench
	@echo "$(GREEN)✅ Benchmarks complete$(NC)"

.PHONY: coverage
coverage: ## Generate test coverage report
	@echo "$(BLUE)📊 Generating coverage report...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) tarpaulin --out Html
	@cd $(PROTOCOL_DIR) && $(NPM) run coverage
	@echo "$(GREEN)✅ Coverage reports generated$(NC)"

# =============================================================================
# DEMO & EXAMPLES
# =============================================================================

.PHONY: demo
demo: ## Run the simple demo
	@echo "$(BLUE)🎬 Running BitVM3 simple demo...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) run demo

.PHONY: demo-full
demo-full: ## Run the full feature demo
	@echo "$(BLUE)🎯 Running BitVM3 full demo...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) run full-demo

.PHONY: demo-real
demo-real: ## Run demo with real BitVM verification (starts server automatically)
	@bash scripts/run-real-demo.sh

.PHONY: server
server: ## Start the verification engine API server
	@echo "$(BLUE)🚀 Starting verification engine API server...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) build --release --bin bitvm3-server
	@echo "$(GREEN)✅ Server built$(NC)"
	@echo "$(YELLOW)📡 Starting server on http://localhost:8080$(NC)"
	@cd $(VERIFIER_DIR) && PORT=8080 ./target/release/bitvm3-server

.PHONY: server-dev
server-dev: ## Start the verification engine in development mode with auto-reload
	@echo "$(BLUE)🚀 Starting verification engine in dev mode...$(NC)"
	@cd $(VERIFIER_DIR) && PORT=8080 $(CARGO) watch -x "run --bin bitvm3-server"

.PHONY: demo-real-interactive
demo-real-interactive: ## Run real demo interactively (requires manual server start)
	@echo "$(BLUE)🔬 Running real BitVM demo (interactive mode)...$(NC)"
	@echo ""
	@echo "$(YELLOW)Prerequisites:$(NC)"
	@echo "  1. Start the verification engine server in another terminal:"
	@echo "     $$ make server"
	@echo ""
	@echo "  2. Once server is running, press Enter to continue..."
	@read -p ""
	@echo "$(BLUE)🚀 Running real BitVM demo...$(NC)"
	@cd $(PROTOCOL_DIR) && RUST_API_URL=http://localhost:8080 $(NPM) run real-demo

.PHONY: cli
cli: ## Start the CLI interface
	@echo "$(BLUE)💻 Starting CLI interface...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) start

.PHONY: example-deposit
example-deposit: ## Run deposit example
	@echo "$(BLUE)💰 Running deposit example...$(NC)"
	@curl -X POST http://localhost:8080/api/v1/deposit \
		-H "Content-Type: application/json" \
		-d '{"participant":"alice","amount":100000000,"currency":"BTC"}'

.PHONY: example-withdraw
example-withdraw: ## Run withdrawal example
	@echo "$(BLUE)💸 Running withdrawal example...$(NC)"
	@curl -X POST http://localhost:8080/api/v1/withdraw \
		-H "Content-Type: application/json" \
		-d '{"participant":"alice","amount":50000000,"currency":"BTC"}'

.PHONY: example-challenge
example-challenge: ## Run challenge example
	@echo "$(BLUE)⚔️  Running challenge example...$(NC)"
	@curl -X POST http://localhost:8080/api/v1/challenge \
		-H "Content-Type: application/json" \
		-d '{"challenger":"alice","disputedTx":"tx_123","evidence":"proof_data"}'

# =============================================================================
# CODE QUALITY
# =============================================================================

.PHONY: lint
lint: lint-verification-engine lint-ts ## Run all linters
	@echo "$(GREEN)✅ All linting passed$(NC)"

.PHONY: lint-verification-engine
lint-verification-engine: ## Lint Verification Engine code
	@echo "$(BLUE)🔍 Linting Verification Engine code...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) clippy --all-targets --all-features -- -D warnings
	@echo "$(GREEN)✅ Verification Engine linting passed$(NC)"

.PHONY: lint-ts
lint-ts: ## Lint Vault Protocol code
	@echo "$(BLUE)🔍 Linting Vault Protocol code...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) run lint
	@echo "$(GREEN)✅ Vault Protocol linting passed$(NC)"

.PHONY: fmt
fmt: fmt-verification-engine fmt-ts ## Format all code
	@echo "$(GREEN)✅ All code formatted$(NC)"

.PHONY: fmt-verification-engine
fmt-verification-engine: ## Format Verification Engine code
	@echo "$(BLUE)🎨 Formatting Verification Engine code...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) fmt --all
	@echo "$(GREEN)✅ Verification Engine code formatted$(NC)"

.PHONY: fmt-ts
fmt-ts: ## Format Vault Protocol code
	@echo "$(BLUE)🎨 Formatting Vault Protocol code...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) run format
	@echo "$(GREEN)✅ Vault Protocol code formatted$(NC)"

.PHONY: audit
audit: audit-verification-engine audit-ts ## Security audit
	@echo "$(GREEN)✅ Security audit complete$(NC)"

.PHONY: audit-verification-engine
audit-verification-engine: ## Audit Verification Engine dependencies
	@echo "$(BLUE)🔒 Auditing Verification Engine dependencies...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) audit
	@echo "$(GREEN)✅ Verification Engine audit passed$(NC)"

.PHONY: audit-ts
audit-ts: ## Audit Vault Protocol dependencies
	@echo "$(BLUE)🔒 Auditing Vault Protocol dependencies...$(NC)"
	@cd $(PROTOCOL_DIR) && $(NPM) audit
	@echo "$(GREEN)✅ Vault Protocol audit passed$(NC)"

# =============================================================================
# DOCKER & DEPLOYMENT
# =============================================================================

.PHONY: docker-up
docker-up: ## Start all services with Docker Compose
	@echo "$(BLUE)🐳 Starting Docker services...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✅ Services running$(NC)"
	@make docker-ps

.PHONY: docker-down
docker-down: ## Stop all Docker services
	@echo "$(BLUE)🐳 Stopping Docker services...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✅ Services stopped$(NC)"

.PHONY: docker-restart
docker-restart: docker-down docker-up ## Restart Docker services
	@echo "$(GREEN)✅ Services restarted$(NC)"

.PHONY: docker-logs
docker-logs: ## Show Docker logs
	@$(DOCKER_COMPOSE) logs -f

.PHONY: docker-ps
docker-ps: ## Show running Docker containers
	@$(DOCKER_COMPOSE) ps

.PHONY: docker-clean
docker-clean: ## Clean Docker volumes and images
	@echo "$(YELLOW)⚠️  Cleaning Docker volumes and images...$(NC)"
	@$(DOCKER_COMPOSE) down -v --rmi all
	@echo "$(GREEN)✅ Docker cleaned$(NC)"

# =============================================================================
# DATABASE
# =============================================================================

.PHONY: db-migrate
db-migrate: ## Run database migrations
	@echo "$(BLUE)🗄️  Running database migrations...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) run --bin migrate
	@echo "$(GREEN)✅ Migrations complete$(NC)"

.PHONY: db-reset
db-reset: ## Reset database
	@echo "$(YELLOW)⚠️  Resetting database...$(NC)"
	@$(DOCKER_COMPOSE) exec postgres psql -U bitvm3 -c "DROP DATABASE IF EXISTS bitvm3;"
	@$(DOCKER_COMPOSE) exec postgres psql -U bitvm3 -c "CREATE DATABASE bitvm3;"
	@make db-migrate
	@echo "$(GREEN)✅ Database reset$(NC)"

.PHONY: db-backup
db-backup: ## Backup database
	@echo "$(BLUE)💾 Backing up database...$(NC)"
	@mkdir -p backups
	@$(DOCKER_COMPOSE) exec postgres pg_dump -U bitvm3 bitvm3 > backups/bitvm3_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ Database backed up$(NC)"

# =============================================================================
# MONITORING & LOGS
# =============================================================================

.PHONY: logs
logs: ## Show all logs
	@echo "$(BLUE)📜 Showing logs...$(NC)"
	@make -j2 logs-verification-engine logs-ts

.PHONY: logs-verification-engine
logs-verification-engine: ## Show Verification Engine logs
	@tail -f verification-engine/bitvm3.log 2>/dev/null || echo "No Verification Engine logs found"

.PHONY: logs-ts
logs-ts: ## Show Vault Protocol logs
	@tail -f vault-protocol/app.log 2>/dev/null || echo "No Vault Protocol logs found"

.PHONY: monitor
monitor: ## Start monitoring dashboard
	@echo "$(BLUE)📊 Starting monitoring dashboard...$(NC)"
	@open http://localhost:8080/metrics || xdg-open http://localhost:8080/metrics

.PHONY: status
status: ## Show system status
	@echo "$(BLUE)📊 System Status$(NC)"
	@echo "===================="
	@echo "$(YELLOW)Services:$(NC)"
	@$(DOCKER_COMPOSE) ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "$(YELLOW)API Health:$(NC)"
	@curl -s http://localhost:8080/api/v1/health | jq '.' 2>/dev/null || echo "API not responding"
	@echo ""
	@echo "$(YELLOW)Vault State:$(NC)"
	@curl -s http://localhost:8080/api/v1/vault/state | jq '.' 2>/dev/null || echo "Unable to fetch vault state"

# =============================================================================
# RELEASE & PRODUCTION
# =============================================================================

.PHONY: release
release: ## Create a release build
	@echo "$(BLUE)📦 Creating release build...$(NC)"
	@make clean
	@make build
	@make test
	@make audit
	@echo "$(GREEN)✅ Release build ready$(NC)"

.PHONY: deploy
deploy: ## Deploy to production
	@echo "$(BLUE)🚀 Deploying to production...$(NC)"
	@make release
	@$(DOCKER_COMPOSE) -f docker-compose.prod.yml up -d
	@echo "$(GREEN)✅ Deployed to production$(NC)"

.PHONY: rollback
rollback: ## Rollback to previous version
	@echo "$(YELLOW)⚠️  Rolling back...$(NC)"
	@$(DOCKER_COMPOSE) -f docker-compose.prod.yml down
	@git checkout HEAD~1
	@make deploy
	@echo "$(GREEN)✅ Rollback complete$(NC)"

# =============================================================================
# CLEANUP
# =============================================================================

.PHONY: clean
clean: ## Clean build artifacts
	@echo "$(BLUE)🧹 Cleaning build artifacts...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) clean
	@cd $(PROTOCOL_DIR) && rm -rf dist node_modules
	@echo "$(GREEN)✅ Clean complete$(NC)"

.PHONY: clean-all
clean-all: clean docker-clean ## Clean everything including Docker
	@echo "$(BLUE)🧹 Deep cleaning...$(NC)"
	@rm -rf backups/*.sql
	@rm -rf logs/*
	@echo "$(GREEN)✅ Deep clean complete$(NC)"

.PHONY: reset
reset: clean-all ## Reset to fresh state
	@echo "$(YELLOW)⚠️  Resetting to fresh state...$(NC)"
	@make install
	@make setup
	@echo "$(GREEN)✅ Reset complete$(NC)"

# =============================================================================
# DOCUMENTATION
# =============================================================================

.PHONY: docs
docs: ## Generate documentation
	@echo "$(BLUE)📚 Generating documentation...$(NC)"
	@cd $(VERIFIER_DIR) && $(CARGO) doc --no-deps --open
	@cd $(PROTOCOL_DIR) && $(NPM) run docs
	@echo "$(GREEN)✅ Documentation generated$(NC)"

.PHONY: readme
readme: ## Open README in browser
	@open README.md || xdg-open README.md

# =============================================================================
# UTILITIES
# =============================================================================

.PHONY: tree
tree: ## Show project structure
	@tree -I 'node_modules|target|dist|.git' -L 3

.PHONY: count
count: ## Count lines of code
	@echo "$(BLUE)📊 Lines of Code$(NC)"
	@echo "===================="
	@echo "Verification Engine:"
	@find $(VERIFIER_DIR) -name "*.rs" -type f | xargs wc -l | tail -1
	@echo "Vault Protocol:"
	@find $(PROTOCOL_DIR) -name "*.ts" -type f | xargs wc -l | tail -1
	@echo "Total:"
	@find . \( -name "*.rs" -o -name "*.ts" \) -type f | xargs wc -l | tail -1

.PHONY: check
check: ## Run all checks
	@echo "$(BLUE)✔️  Running all checks...$(NC)"
	@make lint
	@make test
	@make audit
	@echo "$(GREEN)✅ All checks passed$(NC)"

.PHONY: ci
ci: ## Run CI pipeline
	@echo "$(BLUE)🔄 Running CI pipeline...$(NC)"
	@make clean
	@make install
	@make build
	@make check
	@echo "$(GREEN)✅ CI pipeline passed$(NC)"

# Default target
.DEFAULT_GOAL := help