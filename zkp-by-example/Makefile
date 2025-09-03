# Makefile for the Sudoku game.
#
# This file contains commands for building, running, and deploying the application.

# Use .PHONY to ensure that the targets are always run, even if a file with the same name exists.
.PHONY: all backend-dev frontend-dev proof-service-dev proofserver-dev build docker-build gcb-build gcb-deploy

# The default target, which starts the backend, frontend, and proof-service in development mode.
all: backend-dev frontend-dev proof-service-dev

# Starts the backend in development mode.
# It uses `cargo-watch` to automatically rebuild and restart the server when files change.
backend-dev:
	@echo "Starting backend in development mode..."
	@cd backend && cargo watch -x run

# Starts the frontend in development mode.
frontend-dev:
	@echo "Starting frontend in development mode..."
	@cd frontend && npm run dev

# Starts the proof-service in development mode.
proof-service-dev: proofserver-dev
proofserver-dev:
	@echo "Starting proof-service in development mode..."
	@cd proof-service && cargo watch -x run

# Builds the backend, frontend, and proof-service for production.
build:
	@echo "Building backend..."
	@cd backend && cargo build --release
	@echo "Building frontend..."
	@cd frontend && npm run build
	@echo "Building proof-service..."
	@cd proof-service && cargo build --release

# Runs the tests for the proof-service.
test:
	@echo "Running tests for proof-service..."
	@cd proof-service && cargo test -- --nocapture


# Builds Docker images for the backend, frontend, and proof-service.
# Requires the `GCP_PROJECT` environment variable to be set.
docker-build:
	@echo "Building Docker images..."
	@docker build -t gcr.io/$(GCP_PROJECT)/sudoku-backend:latest backend
	@docker build -t gcr.io/$(GCP_PROJECT)/sudoku-frontend:latest frontend
	@docker build -t gcr.io/$(GCP_PROJECT)/sudoku-proof-service:latest proof-service

# Runs the Google Cloud Build pipeline for the backend, frontend, and proof-service.
# This will build the Docker images and push them to Google Container Registry.
gcb-build:
	@echo "Running Google Cloud Build for backend..."
	@gcloud builds submit --config backend/cloudbuild.yaml backend
	@echo "Running Google Cloud Build for frontend..."
	@gcloud builds submit --config frontend/cloudbuild.yaml frontend
	@echo "Running Google Cloud Build for proof-service..."
	@gcloud builds submit --config proof-service/cloudbuild.yaml proof-service

# Deploys the backend, frontend, and proof-service to Google Cloud Run.
gcb-deploy:
	@echo "Deploying backend to Cloud Run..."
	@gcloud builds submit --config backend/cloudbuild-deploy.yaml backend
	@echo "Deploying frontend to Cloud Run..."
	@gcloud builds submit --config frontend/cloudbuild-deploy.yaml frontend
	@echo "Deploying proof-service to Cloud Run..."
	@gcloud builds submit --config proof-service/cloudbuild-deploy.yaml proof-service