#!/bin/bash

# Deploy to Google Cloud
set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}Deploying to Google Cloud...${NC}\n"

# Check PROJECT_ID
if [ -z "$PROJECT_ID" ]; then
    echo "ERROR: Set PROJECT_ID first"
    exit 1
fi

# Deploy infrastructure
cd terraform
terraform init -backend-config="bucket=${PROJECT_ID}-web3-workstation-terraform-state" 2>/dev/null || true
terraform apply -var="project_id=${PROJECT_ID}"
cd ..

# Build and push
./scripts/build-and-push.sh

echo -e "\n${GREEN}✓ Deployed successfully${NC}"