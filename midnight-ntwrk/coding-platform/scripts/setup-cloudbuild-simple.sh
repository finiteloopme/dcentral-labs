#!/bin/bash
# Simplified Cloud Build setup script
# Handles the most common configuration with better error handling

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_ID="${1:-${PROJECT_ID}}"
REGION="${2:-us-central1}"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: PROJECT_ID is required${NC}"
    echo "Usage: $0 <PROJECT_ID> [REGION]"
    exit 1
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     Setting up Cloud Build for Midnight Platform${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Set project
echo -e "${YELLOW}Setting project to: ${PROJECT_ID}${NC}"
gcloud config set project ${PROJECT_ID}

# Get project number
echo -e "${YELLOW}Getting project information...${NC}"
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
if [ -z "$PROJECT_NUMBER" ]; then
    echo -e "${RED}Error: Could not get project number. Is the project ID correct?${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Project Number: ${PROJECT_NUMBER}${NC}"

# Enable required APIs
echo -e "${YELLOW}Enabling required APIs (this may take a few minutes)...${NC}"
gcloud services enable \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    compute.googleapis.com \
    storage.googleapis.com \
    workstations.googleapis.com \
    --project=${PROJECT_ID}

echo -e "${GREEN}✓ APIs enabled${NC}"

# Create Terraform state bucket
STATE_BUCKET="${PROJECT_ID}-terraform-state"
echo -e "${YELLOW}Creating Terraform state bucket: ${STATE_BUCKET}${NC}"

if gsutil ls -b gs://${STATE_BUCKET} &>/dev/null; then
    echo -e "${GREEN}✓ State bucket already exists${NC}"
else
    gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${STATE_BUCKET}
    gsutil versioning set on gs://${STATE_BUCKET}
    echo -e "${GREEN}✓ State bucket created with versioning${NC}"
fi

# Create Artifact Registry repository
echo -e "${YELLOW}Creating Artifact Registry repository...${NC}"
gcloud artifacts repositories create midnight-platform \
    --repository-format=docker \
    --location=${REGION} \
    --description="Midnight Development Platform container images" \
    --project=${PROJECT_ID} 2>/dev/null || echo -e "${GREEN}✓ Repository already exists${NC}"

# Create user-managed service account for Cloud Build
echo -e "${YELLOW}Creating user-managed service account for Cloud Build...${NC}"
SA_NAME="midnight-cloudbuild-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Create service account if it doesn't exist
if gcloud iam service-accounts describe ${SA_EMAIL} --project=${PROJECT_ID} &>/dev/null; then
    echo -e "${GREEN}✓ Service account already exists${NC}"
else
    gcloud iam service-accounts create ${SA_NAME} \
        --display-name="Midnight Cloud Build Service Account" \
        --description="User-managed service account for Cloud Build operations" \
        --project=${PROJECT_ID}
    echo -e "${GREEN}✓ Service account created${NC}"
fi

# Grant permissions to the user-managed service account
echo -e "${YELLOW}Configuring service account permissions...${NC}"

# Grant permissions (ignore errors if already exists)
for role in \
    "roles/storage.admin" \
    "roles/compute.admin" \
    "roles/compute.networkAdmin" \
    "roles/compute.securityAdmin" \
    "roles/workstations.admin" \
    "roles/artifactregistry.admin" \
    "roles/iam.serviceAccountUser" \
    "roles/logging.logWriter" \
    "roles/cloudbuild.builds.builder"
do
    echo -e "  Adding ${role}..."
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="${role}" \
        --condition=None \
        --quiet &>/dev/null || true
done

echo -e "${GREEN}✓ Permissions configured${NC}"

# Success message
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     ✅ Cloud Build Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Test with a plan:"
echo "   gcloud builds submit --config=cicd/cloudbuild/cloudbuild-plan.yaml \\"
echo "     --substitutions=_ENVIRONMENT=dev,_REGION=${REGION}"
echo ""
echo "2. Deploy infrastructure:"
echo "   make cloud-deploy"
echo ""
echo "3. View builds:"
echo "   https://console.cloud.google.com/cloud-build/builds?project=${PROJECT_ID}"
echo ""
echo -e "${GREEN}Ready to deploy! 🚀${NC}"