#!/bin/bash

# Show deployment status
set -e

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Deployment Status${NC}\n"

# Project info
echo -e "${YELLOW}Project:${NC} ${PROJECT_ID:-not set}"
echo -e "${YELLOW}Region:${NC} ${REGION:-us-central1}"
echo ""

# Check Terraform outputs
if [ -d "terraform/.terraform" ]; then
    echo -e "${YELLOW}Infrastructure:${NC}"
    cd terraform && terraform output 2>/dev/null | head -5 || echo "  Not deployed"
    cd ..
else
    echo -e "${YELLOW}Infrastructure:${NC} Not initialized"
fi
echo ""

# Check images
if command -v gcloud >/dev/null 2>&1 && [ -n "$PROJECT_ID" ]; then
    echo -e "${YELLOW}Container Images:${NC}"
    gcloud artifacts docker images list \
        --repository=web3-workstation-images \
        --location=${REGION:-us-central1} \
        --limit=2 \
        --format="table(IMAGE,UPDATE_TIME)" 2>/dev/null || echo "  No images"
fi

# Check local container
if command -v podman >/dev/null 2>&1 || command -v docker >/dev/null 2>&1; then
    echo -e "\n${YELLOW}Local Container:${NC}"
    $(command -v podman 2>/dev/null || command -v docker) ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep -E "NAMES|web3-workstation" || echo "  Not running"
fi