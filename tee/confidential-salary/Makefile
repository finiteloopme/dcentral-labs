.PHONY: build run-server run-client clean help test-local test-remote

# Configuration
PROJECT_ID ?= $(shell gcloud config get-value project 2>/dev/null)
ZONE ?= us-central1-a
VM_NAME ?= salary-analyzer-vm
MACHINE_TYPE ?= c3-standard-4

# Export for scripts
export PROJECT_ID ZONE VM_NAME MACHINE_TYPE

help:
	@echo "Confidential Salary Analyzer"
	@echo "============================"
	@echo ""
	@echo "Local Development:"
	@echo "  make build          - Build all components"
	@echo "  make run-server     - Run server locally"
	@echo "  make run-client     - Run client locally"
	@echo "  make test-local     - Test with local server"
	@echo "  make clean          - Remove build artifacts"
	@echo ""
	@echo "GCP Operations:"
	@echo "  make gcp-create     - Create Confidential VM"
	@echo "  make gcp-deploy     - Deploy to VM"
	@echo "  make gcp-status     - Check status"
	@echo "  make gcp-logs       - View logs"
	@echo "  make gcp-ssh        - SSH to VM"
	@echo "  make gcp-cleanup    - Delete resources"
	@echo "  make gcp-setup      - Full setup (create + deploy)"
	@echo "  make test-remote    - Test remote server"
	@echo ""
	@echo "Configuration:"
	@echo "  PROJECT_ID = $(PROJECT_ID)"
	@echo "  ZONE = $(ZONE)"
	@echo "  VM_NAME = $(VM_NAME)"
	@echo "  MACHINE_TYPE = $(MACHINE_TYPE)"

# Local targets
build:
	@./scripts/build.sh

run-server:
	@./scripts/run_server.sh

run-client:
	@./scripts/attest_and_run_client.sh

clean:
	@echo "Cleaning build artifacts..."
	@cargo clean
	@rm -f measurements.json mrtd_calculation.json Dockerfile.deterministic
	@echo "✓ Clean complete"

test-local:
	@./scripts/test_local.sh demo

test-stress:
	@./scripts/test_local.sh stress

test-attestation:
	@./scripts/test_local.sh attestation

# GCP targets (delegating to script)
gcp-create:
	@./scripts/gcp_operations.sh create-vm

gcp-deploy:
	@./scripts/gcp_operations.sh deploy

gcp-build:
	@./scripts/remote_build.sh

gcp-rebuild:
	@./scripts/remote_build.sh --clean

gcp-status:
	@./scripts/gcp_operations.sh status

gcp-logs:
	@./scripts/gcp_operations.sh logs

gcp-ssh:
	@./scripts/gcp_operations.sh ssh

gcp-cleanup:
	@./scripts/gcp_operations.sh cleanup

gcp-setup:
	@./scripts/gcp_operations.sh full-setup

gcp-troubleshoot:
	@./scripts/troubleshoot.sh

test-remote:
	@./scripts/gcp_operations.sh test

# Convenience aliases
deploy: gcp-deploy
status: gcp-status
logs: gcp-logs
ssh: gcp-ssh