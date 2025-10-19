# Makefile for the Confidential AI Financial Analyst API

.PHONY: all local-build local-run remote-build remote-deploy

# Default target
all: local-build

# =============================================================================
# Local Development
# =============================================================================

local-build:
	@echo "Building services for local development..."
	@cd api-gateway && python3 -m venv venv && . venv/bin/activate && pip install -r requirements.txt
	@cd analyst-api && python3 -m venv venv && . venv/bin/activate && pip install -r requirements.txt
	@cd midnight-verifier && npm install && npm run build

local-run:
	@echo "Running services locally..."
	@cd api-gateway && . venv/bin/activate && uvicorn main:app --host 0.0.0.0 --port 8000 &
	@cd analyst-api && . venv/bin/activate && uvicorn main:app --host 0.0.0.0 --port 8001 &
	@cd midnight-verifier && node dist/main.js &

local-stop:
	@echo "Stopping services..."
	@killall uvicorn || true
	@killall node || true

# =============================================================================
# Remote Deployment
# =============================================================================

PROJECT_ID ?= $(shell gcloud config get-value project)
REGION ?= us-central1

remote-build:
	@echo "Building services for remote deployment..."
	@gcloud builds submit --config cloudbuild-build.yaml . --project=$(PROJECT_ID)

remote-deploy:
	@echo "Deploying services to Cloud Run..."
	@gcloud builds submit --config cloudbuild-deploy.yaml . --project=$(PROJECT_ID)

