#!/bin/bash

# Midnight Development Platform - GCloud Commands
# This script contains all gcloud commands extracted from the Makefile

set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-us-central1}"
ENV="${ENV:-dev}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if project is set
check_project() {
    if [ -z "$PROJECT_ID" ]; then
        echo "ERROR: Set PROJECT_ID or run: gcloud config set project YOUR_PROJECT"
        exit 1
    fi
}

# Deploy to Google Cloud
deploy() {
    check_project
    echo -e "${GREEN}Deploying to Google Cloud...${NC}"
    echo "  Project: $PROJECT_ID"
    echo "  Environment: $ENV"
    echo "  Region: $REGION"
    echo ""
    
    # Build substitutions string
    SUBSTITUTIONS="_ENVIRONMENT=$ENV,_REGION=$REGION,_ZONE=${REGION}-a,_TERRAFORM_ACTION=apply,_AUTO_APPROVE=true"
    
    gcloud beta builds submit \
        --config=cicd/cloudbuild/cloudbuild.yaml \
        --substitutions="$SUBSTITUTIONS" \
        --project="$PROJECT_ID" .
}

# Undeploy - Clean up all cloud resources
undeploy() {
    check_project
    echo -e "${YELLOW}WARNING: This will destroy all cloud resources!${NC}"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Undeploy cancelled."
        exit 0
    fi
    
    echo -e "${YELLOW}Destroying cloud resources...${NC}"
    gcloud beta builds submit \
        --config=cicd/cloudbuild/cloudbuild-destroy.yaml \
        --substitutions="_ENVIRONMENT=$ENV,_REGION=$REGION,_ZONE=${REGION}-a,_TERRAFORM_ACTION=destroy,_AUTO_APPROVE=true" \
        --project="$PROJECT_ID" .
}

# Start workstation
workstation_start() {
    check_project
    local WORKSTATION_ID="${2:-midnight-developer-1}"
    echo -e "${GREEN}Starting workstation: $WORKSTATION_ID...${NC}"
    gcloud workstations start "$WORKSTATION_ID" \
        --cluster=midnight-dev-cluster \
        --config=midnight-dev-config \
        --region="$REGION" \
        --project="$PROJECT_ID"
}

# Stop workstation
workstation_stop() {
    check_project
    local WORKSTATION_ID="${2:-midnight-developer-1}"
    echo -e "${YELLOW}Stopping workstation: $WORKSTATION_ID...${NC}"
    gcloud workstations stop "$WORKSTATION_ID" \
        --cluster=midnight-dev-cluster \
        --config=midnight-dev-config \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --quiet
}

# Create tunnel to workstation
workstation_tunnel() {
    check_project
    local WORKSTATION_ID="${2:-midnight-developer-1}"
    echo -e "${GREEN}Creating tunnel to Code OSS for $WORKSTATION_ID...${NC}"
    echo "Access at: http://localhost:8080"
    gcloud workstations start-tcp-tunnel "$WORKSTATION_ID" 80 \
        --cluster=midnight-dev-cluster \
        --config=midnight-dev-config \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --local-host-port=localhost:8080
}

# Get workstation status
workstation_status() {
    check_project
    local WORKSTATION_ID="${2:-midnight-developer-1}"
    echo -e "${GREEN}Deployment status for $WORKSTATION_ID:${NC}"
    gcloud workstations describe "$WORKSTATION_ID" \
        --cluster=midnight-dev-cluster \
        --config=midnight-dev-config \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="table(name.segment(-1):label=WORKSTATION,state,host)" 2>/dev/null || echo "Workstation not found"
    echo ""
    echo -e "${GREEN}Recent builds:${NC}"
    gcloud builds list --limit=3 --project="$PROJECT_ID" \
        --format="table(id,status,createTime.date())"
}

# Main command handler
case "$1" in
    deploy)
        deploy
        ;;
    undeploy)
        undeploy
        ;;
    ws-start)
        workstation_start "$@"
        ;;
    ws-stop)
        workstation_stop "$@"
        ;;
    ws-tunnel)
        workstation_tunnel "$@"
        ;;
    status)
        workstation_status "$@"
        ;;
    *)
        echo "Usage: $0 {deploy|undeploy|ws-start|ws-stop|ws-tunnel|status} [workstation-id]"
        echo ""
        echo "Commands:"
        echo "  deploy                    - Deploy to Google Cloud"
        echo "  undeploy                  - Destroy all cloud resources"
        echo "  ws-start [workstation-id] - Start workstation (default: midnight-developer-1)"
        echo "  ws-stop [workstation-id]  - Stop workstation (default: midnight-developer-1)"
        echo "  ws-tunnel [workstation-id] - Create tunnel to Code OSS (default: midnight-developer-1)"
        echo "  status [workstation-id]   - Show deployment status (default: midnight-developer-1)"
        echo ""
        echo "Examples:"
        echo "  $0 ws-start                    # Start default workstation"
        echo "  $0 ws-start developer-2        # Start specific workstation"
        echo "  $0 ws-stop developer-3         # Stop specific workstation"
        exit 1
        ;;
esac