# ABI Assistant Makefile

.PHONY: help dev test build deploy

# Default
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development
dev: ## Start dev server with Anvil
	@scripts/docker-compose.sh up -d
	@scripts/run-server.sh

server: ## Start only the MCP server (with .env loading)
	@scripts/run-server.sh

anvil: ## Start only Anvil
	@scripts/docker-compose.sh up -d

test: ## Run tests
	@cargo test

clean-build: ## Clean and rebuild locally for quick feedback
	@echo "Cleaning build artifacts..."
	@cargo clean
	@echo "Building in debug mode..."
	@cargo build
	@echo "Running tests..."
	@cargo test --quiet
	@echo "✓ Build successful!"

build: ## Build production image
	@scripts/docker-compose.sh build

stop: ## Stop all services
	@scripts/docker-compose.sh down

# Cloud Deployment (GCP via Cloud Build)
# No local dependencies required - everything runs in Cloud Build
# Usage: make deploy PROJECT_ID=your-project-id
# Usage: make deploy-prod PROJECT_ID=your-project-id

deploy: ## Deploy to GCP Cloud Run (dev)
	@test -n "$(PROJECT_ID)" || (echo "Error: PROJECT_ID is required" && exit 1)
	@echo "Deploying to GCP via Cloud Build..."
	@gcloud builds submit . \
		--project=$(PROJECT_ID) \
		--config=gcp/cloudbuild-deploy.yaml \
		--substitutions=_ENVIRONMENT=dev,_REGION=$${REGION:-us-central1},_DEPLOY_ANVIL=$${WITH_ANVIL:-false}

deploy-staging: ## Deploy to staging environment
	@test -n "$(PROJECT_ID)" || (echo "Error: PROJECT_ID is required" && exit 1)
	@echo "Deploying to staging via Cloud Build..."
	@gcloud builds submit . \
		--project=$(PROJECT_ID) \
		--config=gcp/cloudbuild-deploy.yaml \
		--substitutions=_ENVIRONMENT=staging,_REGION=$${REGION:-us-central1},_DEPLOY_ANVIL=$${WITH_ANVIL:-false}

deploy-prod: ## Deploy to production with Anvil
	@test -n "$(PROJECT_ID)" || (echo "Error: PROJECT_ID is required" && exit 1)
	@echo "Deploying to production via Cloud Build..."
	@gcloud builds submit . \
		--project=$(PROJECT_ID) \
		--config=gcp/cloudbuild-deploy.yaml \
		--substitutions=_ENVIRONMENT=prod,_REGION=$${REGION:-us-central1},_DEPLOY_ANVIL=true,_MCP_MIN_INSTANCES=1

undeploy: ## Remove services from GCP
	@test -n "$(PROJECT_ID)" || (echo "Error: PROJECT_ID is required" && exit 1)
	@echo "Removing services via Cloud Build..."
	@gcloud builds submit . \
		--project=$(PROJECT_ID) \
		--config=gcp/cloudbuild-undeploy.yaml \
		--substitutions=_ENVIRONMENT=$${ENV:-dev},_REGION=$${REGION:-us-central1}

# Cloud Infrastructure (Terraform via Cloud Build)
infra-plan: ## Plan infrastructure changes (via Cloud Build)
	@test -n "$(PROJECT_ID)" || (echo "Error: PROJECT_ID is required" && exit 1)
	@echo "Running Terraform plan via Cloud Build..."
	@gcloud builds submit . \
		--project=$(PROJECT_ID) \
		--config=gcp/cloudbuild-terraform.yaml \
		--substitutions=_ACTION=plan,_ENVIRONMENT=$${ENV:-dev},_REGION=$${REGION:-us-central1}

infra-apply: ## Apply infrastructure (via Cloud Build)
	@test -n "$(PROJECT_ID)" || (echo "Error: PROJECT_ID is required" && exit 1)
	@echo "Applying Terraform via Cloud Build..."
	@gcloud builds submit . \
		--project=$(PROJECT_ID) \
		--config=gcp/cloudbuild-terraform.yaml \
		--substitutions=_ACTION=apply,_ENVIRONMENT=$${ENV:-dev},_REGION=$${REGION:-us-central1}

infra-destroy: ## Destroy infrastructure (via Cloud Build)
	@test -n "$(PROJECT_ID)" || (echo "Error: PROJECT_ID is required" && exit 1)
	@echo "Destroying infrastructure via Cloud Build..."
	@gcloud builds submit . \
		--project=$(PROJECT_ID) \
		--config=gcp/cloudbuild-terraform.yaml \
		--substitutions=_ACTION=destroy,_ENVIRONMENT=$${ENV:-dev},_REGION=$${REGION:-us-central1}

# Setup
setup: ## Initial setup
	@cp .env.example .env
	@echo "✓ Created .env file - please update with your values"
	@scripts/docker-compose.sh build

clean: ## Clean all build artifacts and containers
	@cargo clean
	@scripts/docker-compose.sh down -v

check: ## Run all checks (format, lint, test)
	@echo "Checking code format..."
	@cargo fmt -- --check
	@echo "Running clippy..."
	@cargo clippy
	@echo "Running tests..."
	@cargo test
	@echo "✓ All checks passed!"