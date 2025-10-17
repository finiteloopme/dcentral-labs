#!/bin/bash

# Script to import existing resources into Terraform state
# This handles resources that already exist in GCP

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${2:-us-central1}"
ZONE="${3:-us-central1-a}"
ENV="${4:-dev}"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: No project ID provided${NC}"
    echo "Usage: $0 [PROJECT_ID] [REGION] [ZONE] [ENV]"
    exit 1
fi

echo -e "${YELLOW}Importing existing resources for project: $PROJECT_ID${NC}"
echo "Region: $REGION"
echo "Zone: $ZONE"
echo "Environment: $ENV"
echo ""

# Change to terraform directory
cd terraform

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    terraform init \
        -backend-config="bucket=${PROJECT_ID}-terraform-state" \
        -backend-config="prefix=midnight-platform/${ENV}" \
        -input=false
fi

# Function to safely import a resource
import_resource() {
    local resource_type=$1
    local resource_name=$2
    local resource_id=$3
    local description=$4
    
    echo -e "${YELLOW}Importing ${description}...${NC}"
    
    # Check if resource already exists in state
    if terraform state show "${resource_type}.${resource_name}" &>/dev/null; then
        echo -e "${GREEN}✓ Resource already in state${NC}"
        return 0
    fi
    
    # Try to import the resource
    if terraform import \
        -var="project_id=${PROJECT_ID}" \
        -var="region=${REGION}" \
        -var="zone=${ZONE}" \
        -var="environment=${ENV}" \
        "${resource_type}.${resource_name}" \
        "${resource_id}" 2>/dev/null; then
        echo -e "${GREEN}✓ Successfully imported${NC}"
    else
        echo -e "${YELLOW}⚠ Resource not found or already managed${NC}"
    fi
}

# Import Workstation Cluster
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Importing Workstation Resources${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if the workstation cluster exists
CLUSTER_NAME="midnight-${ENV}-cluster"
if gcloud workstations clusters describe ${CLUSTER_NAME} \
    --location=${REGION} \
    --project=${PROJECT_ID} &>/dev/null; then
    
    echo -e "${GREEN}Found existing workstation cluster: ${CLUSTER_NAME}${NC}"
    
    # Import the cluster
    import_resource \
        "module.workstations.google_workstations_workstation_cluster.cluster" \
        "" \
        "projects/${PROJECT_ID}/locations/${REGION}/workstationClusters/${CLUSTER_NAME}" \
        "Workstation Cluster"
fi

# Check for workstation configuration
CONFIG_NAME="midnight-${ENV}-config"
if gcloud workstations configs describe ${CONFIG_NAME} \
    --cluster=${CLUSTER_NAME} \
    --location=${REGION} \
    --project=${PROJECT_ID} &>/dev/null; then
    
    echo -e "${GREEN}Found existing workstation config: ${CONFIG_NAME}${NC}"
    
    # Import the config
    import_resource \
        "module.workstations.google_workstations_workstation_config.config" \
        "" \
        "projects/${PROJECT_ID}/locations/${REGION}/workstationClusters/${CLUSTER_NAME}/workstationConfigs/${CONFIG_NAME}" \
        "Workstation Configuration"
fi

# Import VPC if it exists
VPC_NAME="midnight-${ENV}-vpc"
if gcloud compute networks describe ${VPC_NAME} \
    --project=${PROJECT_ID} &>/dev/null; then
    
    echo -e "${GREEN}Found existing VPC: ${VPC_NAME}${NC}"
    
    import_resource \
        "module.networking.google_compute_network.vpc" \
        "" \
        "projects/${PROJECT_ID}/global/networks/${VPC_NAME}" \
        "VPC Network"
fi

# Import Subnet if it exists
SUBNET_NAME="midnight-${ENV}-subnet"
if gcloud compute networks subnets describe ${SUBNET_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} &>/dev/null; then
    
    echo -e "${GREEN}Found existing subnet: ${SUBNET_NAME}${NC}"
    
    import_resource \
        "module.networking.google_compute_subnetwork.subnet" \
        "" \
        "projects/${PROJECT_ID}/regions/${REGION}/subnetworks/${SUBNET_NAME}" \
        "Subnet"
fi

# Import NAT IP if it exists
NAT_IP_NAME="midnight-${ENV}-nat-ip"
if gcloud compute addresses describe ${NAT_IP_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} &>/dev/null; then
    
    echo -e "${GREEN}Found existing NAT IP: ${NAT_IP_NAME}${NC}"
    
    import_resource \
        "module.networking.google_compute_address.nat_ip" \
        "" \
        "projects/${PROJECT_ID}/regions/${REGION}/addresses/${NAT_IP_NAME}" \
        "NAT IP Address"
fi

# Import Cloud Router if it exists
ROUTER_NAME="midnight-${ENV}-router"
if gcloud compute routers describe ${ROUTER_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} &>/dev/null; then
    
    echo -e "${GREEN}Found existing router: ${ROUTER_NAME}${NC}"
    
    import_resource \
        "module.networking.google_compute_router.router" \
        "" \
        "projects/${PROJECT_ID}/regions/${REGION}/routers/${ROUTER_NAME}" \
        "Cloud Router"
fi

# Import Cloud NAT if it exists
NAT_NAME="midnight-${ENV}-nat"
if gcloud compute routers nats describe ${NAT_NAME} \
    --router=${ROUTER_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} &>/dev/null; then
    
    echo -e "${GREEN}Found existing NAT gateway: ${NAT_NAME}${NC}"
    
    import_resource \
        "module.networking.google_compute_router_nat.nat" \
        "" \
        "projects/${PROJECT_ID}/regions/${REGION}/routers/${ROUTER_NAME}/nats/${NAT_NAME}" \
        "NAT Gateway"
fi

# Import Artifact Registry if it exists
REGISTRY_NAME="midnight-images"
if gcloud artifacts repositories describe ${REGISTRY_NAME} \
    --location=${REGION} \
    --project=${PROJECT_ID} &>/dev/null; then
    
    echo -e "${GREEN}Found existing artifact registry: ${REGISTRY_NAME}${NC}"
    
    import_resource \
        "module.registry.google_artifact_registry_repository.midnight_images" \
        "" \
        "projects/${PROJECT_ID}/locations/${REGION}/repositories/${REGISTRY_NAME}" \
        "Artifact Registry"
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Import Summary${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Show the current state
echo -e "${YELLOW}Current Terraform state:${NC}"
terraform state list

echo ""
echo -e "${GREEN}✅ Import process complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run 'terraform plan' to see what changes are needed"
echo "2. Run 'terraform apply' to reconcile any differences"
echo ""
echo -e "${YELLOW}To run a plan:${NC}"
echo "cd terraform && terraform plan -var=\"project_id=${PROJECT_ID}\" -var=\"region=${REGION}\" -var=\"zone=${ZONE}\" -var=\"environment=${ENV}\""