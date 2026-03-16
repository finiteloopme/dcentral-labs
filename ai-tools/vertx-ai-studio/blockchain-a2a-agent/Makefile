# blockchain-a2a-agent Makefile
# -----------------------------------------------------------
# Targets for building, testing, running, and deploying the agent.
# LLM routing requires GOOGLE_CLOUD_PROJECT and ADC credentials.
# -----------------------------------------------------------

# ---- Configurable variables ----
GOOGLE_CLOUD_PROJECT ?= $(shell gcloud config get-value project 2>/dev/null)
VERTEX_LOCATION      ?= global
GEMINI_MODEL         ?= gemini-3.1-flash-lite-preview
PORT                 ?= 8080

# Deployment runtime: vertex-ai (default) or cloud-run
RUNTIME              ?= vertex-ai

# Container image coordinates
REGION               ?= us-central1
AR_REPO              ?= rust-agents
IMAGE_NAME           ?= blockchain-a2a-agent
IMAGE_TAG            ?= latest
CONTAINER_IMAGE      ?= $(REGION)-docker.pkg.dev/$(GOOGLE_CLOUD_PROJECT)/$(AR_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

# Vertex AI Prediction settings
MACHINE_TYPE         ?= e2-standard-2
MIN_REPLICAS         ?= 1
MAX_REPLICAS         ?= 3

.PHONY: build test run run-llm run-keyword clean fmt lint check help
.PHONY: docker-build push deploy undeploy info

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ---- Development ----

build: ## Build the agent (release)
	cargo build --release

test: ## Run unit tests
	cargo test

check: ## Compile check + clippy lints
	cargo check
	cargo clippy -- -D warnings

fmt: ## Format code
	cargo fmt

run: run-llm ## Run the agent (alias for run-llm)

run-llm: build ## Run with LLM routing (needs ADC + GOOGLE_CLOUD_PROJECT)
	@if [ -z "$(GOOGLE_CLOUD_PROJECT)" ]; then \
		echo "ERROR: GOOGLE_CLOUD_PROJECT is not set."; \
		echo "  Set it via: export GOOGLE_CLOUD_PROJECT=my-project"; \
		echo "  Or run 'make run-keyword' for keyword-only mode."; \
		exit 1; \
	fi
	@echo "Starting agent with LLM routing (project=$(GOOGLE_CLOUD_PROJECT))..."
	GOOGLE_CLOUD_PROJECT=$(GOOGLE_CLOUD_PROJECT) \
	VERTEX_LOCATION=$(VERTEX_LOCATION) \
	GEMINI_MODEL=$(GEMINI_MODEL) \
	cargo run --release

run-keyword: build ## Run with keyword fallback only (no GCP needed)
	@echo "Starting agent in keyword-only mode..."
	cargo run --release

clean: ## Remove build artifacts
	cargo clean

# ---- Container ----

docker-build: ## Build container image locally
	docker build -t $(CONTAINER_IMAGE) .

push: ## Build and push container via Cloud Build
	@echo "Building and pushing $(CONTAINER_IMAGE)..."
	gcloud builds submit \
		--tag $(CONTAINER_IMAGE) \
		--project=$(GOOGLE_CLOUD_PROJECT) \
		.

# ---- Deployment (dispatches on RUNTIME) ----

deploy: push ## Deploy agent (RUNTIME=vertex-ai|cloud-run)
	@echo "Deploying with runtime: $(RUNTIME)"
	$(MAKE) deploy-$(RUNTIME)

undeploy: ## Undeploy agent (RUNTIME=vertex-ai|cloud-run)
	@echo "Undeploying runtime: $(RUNTIME)"
	$(MAKE) undeploy-$(RUNTIME)

info: ## Show deployment info (RUNTIME=vertex-ai|cloud-run)
	$(MAKE) info-$(RUNTIME)

# ---- Vertex AI Prediction (default) ----

deploy-vertex-ai: ## Deploy to Vertex AI Prediction
	@echo "==> Uploading model to Vertex AI..."
	gcloud ai models upload \
		--display-name=$(IMAGE_NAME) \
		--container-image-uri=$(CONTAINER_IMAGE) \
		--container-predict-route=/v1/messages \
		--container-health-route=/health \
		--container-ports=$(PORT) \
		--container-env-vars="VERTEX_LOCATION=$(VERTEX_LOCATION),GEMINI_MODEL=$(GEMINI_MODEL)" \
		--region=$(REGION) \
		--project=$(GOOGLE_CLOUD_PROJECT) \
		--format="value(model)" | tee /tmp/.a2a-model-id
	$(eval MODEL_ID := $(shell cat /tmp/.a2a-model-id | grep -oP 'models/\K[0-9]+'))
	@echo "==> Model uploaded: $(MODEL_ID)"
	@echo "==> Creating endpoint..."
	gcloud ai endpoints create \
		--display-name=$(IMAGE_NAME)-endpoint \
		--region=$(REGION) \
		--project=$(GOOGLE_CLOUD_PROJECT) \
		--format="value(name)" | tee /tmp/.a2a-endpoint-id
	$(eval ENDPOINT_ID := $(shell cat /tmp/.a2a-endpoint-id | grep -oP 'endpoints/\K[0-9]+'))
	@echo "==> Endpoint created: $(ENDPOINT_ID)"
	@echo "==> Deploying model to endpoint (this takes ~15-20 min)..."
	gcloud ai endpoints deploy-model $(ENDPOINT_ID) \
		--model=$(MODEL_ID) \
		--display-name=$(IMAGE_NAME)-v1 \
		--machine-type=$(MACHINE_TYPE) \
		--min-replica-count=$(MIN_REPLICAS) \
		--max-replica-count=$(MAX_REPLICAS) \
		--region=$(REGION) \
		--project=$(GOOGLE_CLOUD_PROJECT)
	@echo "==> Deployed! Query with:"
	@echo '  curl -X POST \'
	@echo '    -H "Authorization: Bearer $$(gcloud auth print-access-token)" \'
	@echo '    -H "Content-Type: application/json" \'
	@echo '    "https://$(REGION)-aiplatform.googleapis.com/v1/projects/$(GOOGLE_CLOUD_PROJECT)/locations/$(REGION)/endpoints/$(ENDPOINT_ID):rawPredict" \'
	@echo '    -d '"'"'{"jsonrpc":"2.0","id":"1","params":{"message":{"role":"user","parts":[{"text":"Bitcoin block height"}]}}}'"'"''

undeploy-vertex-ai: ## Undeploy from Vertex AI Prediction
	@echo "Listing Vertex AI endpoints for $(IMAGE_NAME)..."
	@gcloud ai endpoints list \
		--region=$(REGION) \
		--project=$(GOOGLE_CLOUD_PROJECT) \
		--filter="displayName:$(IMAGE_NAME)-endpoint" \
		--format="table(name,displayName,deployedModels[0].id)"
	@echo ""
	@echo "Use these commands to clean up:"
	@echo "  gcloud ai endpoints undeploy-model ENDPOINT_ID --deployed-model-id=DEPLOYED_MODEL_ID --region=$(REGION) --project=$(GOOGLE_CLOUD_PROJECT)"
	@echo "  gcloud ai endpoints delete ENDPOINT_ID --region=$(REGION) --project=$(GOOGLE_CLOUD_PROJECT)"
	@echo "  gcloud ai models delete MODEL_ID --region=$(REGION) --project=$(GOOGLE_CLOUD_PROJECT)"

info-vertex-ai: ## Show Vertex AI deployment info
	@echo "==> Vertex AI Models:"
	@gcloud ai models list \
		--region=$(REGION) \
		--project=$(GOOGLE_CLOUD_PROJECT) \
		--filter="displayName:$(IMAGE_NAME)" \
		--format="table(name,displayName,createTime)" 2>/dev/null || true
	@echo ""
	@echo "==> Vertex AI Endpoints:"
	@gcloud ai endpoints list \
		--region=$(REGION) \
		--project=$(GOOGLE_CLOUD_PROJECT) \
		--filter="displayName:$(IMAGE_NAME)-endpoint" \
		--format="table(name,displayName,deployedModels[0].id)" 2>/dev/null || true

# ---- Cloud Run ----

deploy-cloud-run: ## Deploy to Cloud Run
	gcloud run deploy $(IMAGE_NAME) \
		--image=$(CONTAINER_IMAGE) \
		--platform=managed \
		--region=$(REGION) \
		--allow-unauthenticated \
		--set-env-vars="GOOGLE_CLOUD_PROJECT=$(GOOGLE_CLOUD_PROJECT),VERTEX_LOCATION=$(VERTEX_LOCATION),GEMINI_MODEL=$(GEMINI_MODEL)" \
		--project=$(GOOGLE_CLOUD_PROJECT)
	@echo ""
	@echo "==> Agent Card URL:"
	@echo "  $$(gcloud run services describe $(IMAGE_NAME) --region=$(REGION) --project=$(GOOGLE_CLOUD_PROJECT) --format='value(status.url)')/.well-known/agent.json"

undeploy-cloud-run: ## Undeploy from Cloud Run
	gcloud run services delete $(IMAGE_NAME) \
		--region=$(REGION) \
		--project=$(GOOGLE_CLOUD_PROJECT) \
		--quiet

info-cloud-run: ## Show Cloud Run deployment info
	@gcloud run services describe $(IMAGE_NAME) \
		--region=$(REGION) \
		--project=$(GOOGLE_CLOUD_PROJECT) \
		--format="table(status.url,status.conditions[0].status)" 2>/dev/null || echo "Not deployed."
