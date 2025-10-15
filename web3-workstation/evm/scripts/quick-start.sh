#!/bin/bash

# Quick start script - Complete automated setup
set -e

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Web3 Cloud Workstation - Quick Start${NC}\n"

# Check PROJECT_ID
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: PROJECT_ID not set${NC}"
    echo "Run: export PROJECT_ID=your-gcp-project-id"
    exit 1
fi

echo "This will:"
echo "  1. Check prerequisites"
echo "  2. Enable APIs and create infrastructure"
echo "  3. Build and deploy container"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Check dependencies
echo -e "\n${BLUE}Checking dependencies...${NC}"
MISSING=""
command -v gcloud >/dev/null 2>&1 || MISSING="$MISSING gcloud"
command -v terraform >/dev/null 2>&1 || MISSING="$MISSING terraform"
(command -v podman >/dev/null 2>&1 || command -v docker >/dev/null 2>&1) || MISSING="$MISSING podman/docker"

if [ -n "$MISSING" ]; then
    echo -e "${YELLOW}Missing:$MISSING${NC}"
    echo "Run: make install-deps"
    exit 1
fi

# Setup
echo -e "\n${BLUE}Setting up infrastructure...${NC}"
gcloud config set project $PROJECT_ID

# Create state bucket
gsutil mb -p $PROJECT_ID gs://${PROJECT_ID}-web3-workstation-terraform-state 2>/dev/null || true
gsutil versioning set on gs://${PROJECT_ID}-web3-workstation-terraform-state

# Deploy with Terraform
cd terraform
terraform init -backend-config="bucket=${PROJECT_ID}-web3-workstation-terraform-state" -reconfigure
terraform apply -auto-approve -var="project_id=${PROJECT_ID}"
cd ..

# Build and push image
echo -e "\n${BLUE}Building container image...${NC}"
./scripts/build-and-push.sh

echo -e "\n${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Access your workstation at:"
echo "https://console.cloud.google.com/workstations/list?project=${PROJECT_ID}"