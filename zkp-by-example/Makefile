
# Makefile for the Sudoku game.
#
# This file contains commands for building, running, and deploying the application.

# Use .PHONY to ensure that the targets are always run, even if a file with the same name exists.
.PHONY: all backend-dev frontend-dev build docker-build gcb-build gcb-deploy

# The default target, which starts both the backend and frontend in development mode.
all: backend-dev frontend-dev

# Starts the backend in development mode.
# It uses `cargo-watch` to automatically rebuild and restart the server when files change.
backend-dev:
	@echo "Starting backend in development mode..."
	@cd backend && cargo watch -x run

# Starts the frontend in development mode.
frontend-dev:
	@echo "Starting frontend in development mode..."
	@cd frontend && npm run dev

# Builds both the backend and frontend for production.
build:
	@echo "Building backend..."
	@cd backend && cargo build --release
	@echo "Building frontend..."
	@cd frontend && npm run build

# Builds Docker images for both the backend and frontend.
# Requires the `GCP_PROJECT` environment variable to be set.
docker-build:
	@echo "Building Docker images..."
	@docker build -t gcr.io/$(GCP_PROJECT)/sudoku-backend:latest backend
	@docker build -t gcr.io/$(GCP_PROJECT)/sudoku-frontend:latest frontend

# Runs the Google Cloud Build pipeline for both the backend and frontend.
# This will build the Docker images and push them to Google Container Registry.
gcb-build:
	@echo "Running Google Cloud Build for backend..."
	@gcloud builds submit --config backend/cloudbuild.yaml backend
	@echo "Running Google Cloud Build for frontend..."
	@gcloud builds submit --config frontend/cloudbuild.yaml frontend

# Deploys the backend and frontend to Google Cloud Run.
gcb-deploy:
	@echo "Deploying backend to Cloud Run..."
	@gcloud builds submit --config backend/cloudbuild-deploy.yaml backend
	@echo "Deploying frontend to Cloud Run..."
	@gcloud builds submit --config frontend/cloudbuild-deploy.yaml frontend

