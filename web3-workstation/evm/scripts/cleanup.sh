#!/bin/bash

# Cleanup script
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
ACTION="$1"

case "$ACTION" in
    --local)
        echo -e "${YELLOW}Cleaning local resources...${NC}"
        # Clean Docker/Podman
        RUNTIME=$(command -v podman 2>/dev/null || command -v docker 2>/dev/null)
        if [ -n "$RUNTIME" ]; then
            $RUNTIME image prune -f 2>/dev/null || true
            rm -rf terraform/.terraform terraform/tfplan 2>/dev/null || true
        fi
        echo -e "${GREEN}✓ Local cleanup complete${NC}"
        ;;
    
    --destroy)
        echo -e "${RED}Destroying cloud infrastructure...${NC}"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            cd terraform
            terraform destroy -auto-approve -var="project_id=${PROJECT_ID}"
            cd ..
            echo -e "${GREEN}✓ Infrastructure destroyed${NC}"
        else
            echo "Cancelled"
        fi
        ;;
    
    *)
        echo "Usage: $0 [--local|--destroy]"
        echo "  --local   Clean local files and images"
        echo "  --destroy Destroy cloud infrastructure"
        exit 1
        ;;
esac