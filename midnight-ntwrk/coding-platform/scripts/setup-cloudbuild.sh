#!/bin/bash
# Setup script for Cloud Build automation
# This script configures Cloud Build to run Terraform deployments

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_ID="${1:-${PROJECT_ID}}"
REGION="${2:-us-central1}"
ZONE="${3:-us-central1-a}"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: PROJECT_ID is required${NC}"
    echo "Usage: $0 <PROJECT_ID> [REGION] [ZONE]"
    exit 1
fi

echo -e "${GREEN}Setting up Cloud Build for project: ${PROJECT_ID}${NC}"

# Set project
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo -e "${YELLOW}Enabling required APIs...${NC}"
gcloud services enable \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    compute.googleapis.com \
    storage.googleapis.com \
    workstations.googleapis.com \
    secretmanager.googleapis.com \
    --project=${PROJECT_ID}

# Get project number (Cloud Build uses project number, not project ID)
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
if [ -z "$PROJECT_NUMBER" ]; then
    echo -e "${RED}Error: Could not get project number for ${PROJECT_ID}${NC}"
    exit 1
fi

# Cloud Build service account uses project NUMBER, not project ID
CLOUD_BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
echo -e "${YELLOW}Configuring Cloud Build service account: ${CLOUD_BUILD_SA}${NC}"
echo -e "${YELLOW}Project ID: ${PROJECT_ID}, Project Number: ${PROJECT_NUMBER}${NC}"

# Verify the Cloud Build service account exists
echo -e "${YELLOW}Verifying Cloud Build service account...${NC}"
if ! gcloud iam service-accounts describe ${CLOUD_BUILD_SA} --project=${PROJECT_ID} &>/dev/null; then
    echo -e "${YELLOW}Cloud Build service account not found. It will be created when Cloud Build API is enabled.${NC}"
fi

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

# Use the user-managed service account
CLOUD_BUILD_SA="${SA_EMAIL}"

# Grant necessary IAM roles to the service account
echo -e "${YELLOW}Granting IAM permissions...${NC}"

# Function to safely add IAM binding
add_iam_binding() {
    local role=$1
    local description=$2
    
    echo -e "  Adding ${role}..."
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${CLOUD_BUILD_SA}" \
        --role="${role}" \
        --condition=None \
        --quiet 2>/dev/null || {
            echo -e "${YELLOW}  Warning: Could not add ${role} (may already exist)${NC}"
        }
}

# Grant permissions one by one
add_iam_binding "roles/storage.admin" "Terraform state bucket access"
add_iam_binding "roles/compute.admin" "Compute resources management"
add_iam_binding "roles/compute.networkAdmin" "Network resources management"
add_iam_binding "roles/compute.securityAdmin" "Security and firewall management"
add_iam_binding "roles/workstations.admin" "Cloud Workstations management"
add_iam_binding "roles/artifactregistry.admin" "Artifact Registry access"
add_iam_binding "roles/iam.serviceAccountUser" "Service account impersonation"
add_iam_binding "roles/logging.logWriter" "Cloud Build logging"
add_iam_binding "roles/cloudbuild.builds.builder" "Cloud Build operations"
add_iam_binding "roles/secretmanager.secretAccessor" "Secret Manager access"

echo -e "${GREEN}✓ IAM permissions configured${NC}"

# Create Terraform state bucket if it doesn't exist
STATE_BUCKET="${PROJECT_ID}-terraform-state"
echo -e "${YELLOW}Creating Terraform state bucket: ${STATE_BUCKET}${NC}"

if ! gsutil ls -b gs://${STATE_BUCKET} &>/dev/null; then
    gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${STATE_BUCKET}
    
    # Enable versioning on the bucket
    gsutil versioning set on gs://${STATE_BUCKET}
    
    # Set lifecycle rule to delete old versions after 30 days
    cat > /tmp/lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 30,
          "isLive": false
        }
      }
    ]
  }
}
EOF
    gsutil lifecycle set /tmp/lifecycle.json gs://${STATE_BUCKET}
    rm /tmp/lifecycle.json
    
    echo -e "${GREEN}✓ State bucket created${NC}"
else
    echo -e "${GREEN}✓ State bucket already exists${NC}"
fi

# Create artifact repository if it doesn't exist
echo -e "${YELLOW}Creating Artifact Registry repository...${NC}"
gcloud artifacts repositories create midnight-platform \
    --repository-format=docker \
    --location=${REGION} \
    --description="Midnight Development Platform container images" \
    --project=${PROJECT_ID} 2>/dev/null || echo "Repository already exists"

# Create Cloud Build triggers
echo -e "${YELLOW}Creating Cloud Build triggers...${NC}"

# Check if triggers already exist
EXISTING_TRIGGERS=$(gcloud builds triggers list --project=${PROJECT_ID} --format="value(name)" 2>/dev/null || echo "")

# Create PR trigger
if ! echo "$EXISTING_TRIGGERS" | grep -q "terraform-plan-pr"; then
    echo "Creating PR plan trigger..."
    gcloud builds triggers create github \
        --repo-name=coding-platform \
        --repo-owner=midnight-network \
        --name=terraform-plan-pr \
        --description="Run Terraform plan on pull requests" \
        --pull-request-pattern="^main$" \
        --build-config=cicd/cloudbuild/cloudbuild-plan.yaml \
        --include-logs-with-status \
        --project=${PROJECT_ID} 2>/dev/null || echo "Trigger creation failed - may need GitHub connection"
fi

# Create main branch trigger
if ! echo "$EXISTING_TRIGGERS" | grep -q "terraform-apply-dev"; then
    echo "Creating main branch deploy trigger..."
    gcloud builds triggers create github \
        --repo-name=coding-platform \
        --repo-owner=midnight-network \
        --name=terraform-apply-dev \
        --description="Deploy to dev on merge to main" \
        --branch-pattern="^main$" \
        --build-config=cicd/cloudbuild/cloudbuild.yaml \
        --substitutions="_ENVIRONMENT=dev,_TERRAFORM_ACTION=apply,_AUTO_APPROVE=true,_REGION=${REGION},_ZONE=${ZONE}" \
        --project=${PROJECT_ID} 2>/dev/null || echo "Trigger creation failed - may need GitHub connection"
fi

# Create production trigger (manual)
if ! echo "$EXISTING_TRIGGERS" | grep -q "terraform-apply-prod"; then
    echo "Creating production deploy trigger..."
    gcloud builds triggers create manual \
        --name=terraform-apply-prod \
        --description="Deploy to production (requires approval)" \
        --build-config=cicd/cloudbuild/cloudbuild-prod.yaml \
        --substitutions="_ENVIRONMENT=prod,_REGION=${REGION},_ZONE=${ZONE}" \
        --require-approval \
        --project=${PROJECT_ID} 2>/dev/null || echo "Trigger creation failed"
fi

# Optional: Submit initial plan to test setup
echo -e "${YELLOW}Would you like to test Cloud Build with a plan? (y/N)${NC}"
read -r TEST_BUILD
if [[ "$TEST_BUILD" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Testing Cloud Build setup...${NC}"
    if [ -f "cicd/cloudbuild/cloudbuild-plan.yaml" ]; then
        gcloud builds submit \
            --config=cicd/cloudbuild/cloudbuild-plan.yaml \
            --substitutions="_ENVIRONMENT=dev,_REGION=${REGION},_ZONE=${ZONE}" \
            --project=${PROJECT_ID} \
            . || echo -e "${YELLOW}Test build failed - check configuration${NC}"
    else
        echo -e "${YELLOW}cicd/cloudbuild/cloudbuild-plan.yaml not found. Skipping test.${NC}"
    fi
else
    echo -e "${YELLOW}Test skipped. You can run it manually later.${NC}"
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Cloud Build setup complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Connect your GitHub repository:"
echo "   gcloud builds repositories create github --remote-uri=https://github.com/midnight-network/coding-platform"
echo ""
echo "2. Run a manual plan:"
echo "   gcloud builds submit --config=cicd/cloudbuild/cloudbuild-plan.yaml --substitutions=_ENVIRONMENT=dev"
echo ""
echo "3. Deploy to dev:"
echo "   gcloud builds submit --config=cicd/cloudbuild/cloudbuild.yaml --substitutions=_ENVIRONMENT=dev,_TERRAFORM_ACTION=apply,_AUTO_APPROVE=true"
echo ""
echo "4. View builds:"
echo "   https://console.cloud.google.com/cloud-build/builds?project=${PROJECT_ID}"
echo ""
echo -e "${YELLOW}Important: Review and adjust IAM permissions as needed for your security requirements${NC}"