# blockchain-a2a-agent Makefile
# -----------------------------------------------------------
# Targets for building, testing, and running the agent locally.
# LLM routing requires GOOGLE_CLOUD_PROJECT and ADC credentials.
# -----------------------------------------------------------

# Configurable variables (override via env or command line)
GOOGLE_CLOUD_PROJECT ?= $(shell gcloud config get-value project 2>/dev/null)
VERTEX_LOCATION      ?= us-central1
GEMINI_MODEL         ?= gemini-3.0-flash
PORT                 ?= 8080

.PHONY: build test run run-llm run-keyword clean fmt lint check help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

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
