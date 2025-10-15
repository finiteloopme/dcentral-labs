#!/bin/bash

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if required environment variables are set
if [ -z "$PROJECT_ID" ]; then
    print_error "PROJECT_ID environment variable is not set"
    echo "Please set it using: export PROJECT_ID=your-project-id"
    exit 1
fi

REGION="${REGION:-us-central1}"
REPO_NAME="${REPO_NAME:-web3-workstation}"

print_info "Setting up Cloud Build for Web3 Workstation"
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo ""

# Step 1: Enable required APIs
print_status "Enabling Cloud Build and Source Repository APIs..."
gcloud services enable cloudbuild.googleapis.com \
    sourcerepo.googleapis.com \
    artifactregistry.googleapis.com \
    storage.googleapis.com \
    --project=${PROJECT_ID}

# Step 2: Grant Cloud Build service account necessary permissions
print_status "Granting permissions to Cloud Build service account..."
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

for role in \
    "roles/artifactregistry.writer" \
    "roles/storage.admin" \
    "roles/compute.admin" \
    "roles/workstations.admin" \
    "roles/iam.serviceAccountUser" \
    "roles/resourcemanager.projectIamAdmin"
do
    print_info "Granting ${role}..."
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${CLOUDBUILD_SA}" \
        --role="${role}" \
        --condition=None \
        --quiet
done

# Step 3: Create Cloud Source Repository
print_status "Creating Cloud Source Repository..."
if gcloud source repos describe ${REPO_NAME} --project=${PROJECT_ID} &>/dev/null; then
    print_warning "Repository '${REPO_NAME}' already exists"
else
    gcloud source repos create ${REPO_NAME} --project=${PROJECT_ID}
    print_status "Repository '${REPO_NAME}' created"
fi

# Step 4: Initialize git and add remote
print_status "Configuring git repository..."
if [ ! -d .git ]; then
    git init
    print_status "Git repository initialized"
fi

# Add Cloud Source Repository as remote
REPO_URL="https://source.developers.google.com/p/${PROJECT_ID}/r/${REPO_NAME}"
if git remote get-url google &>/dev/null; then
    git remote set-url google ${REPO_URL}
    print_info "Updated existing 'google' remote"
else
    git remote add google ${REPO_URL}
    print_status "Added 'google' remote"
fi

# Step 5: Create initial commit if needed
if [ -z "$(git rev-parse --verify HEAD 2>/dev/null)" ]; then
    print_status "Creating initial commit..."
    git add .
    git commit -m "Initial commit: Web3 Workstation configuration"
fi

# Step 6: Push to Cloud Source Repository
print_status "Pushing to Cloud Source Repository..."
print_info "You may be prompted to authenticate..."
git push google main || git push google master || {
    print_warning "Failed to push to main/master. Creating main branch..."
    git checkout -b main
    git push google main
}

# Step 7: Create Cloud Build triggers
print_status "Creating Cloud Build triggers..."

# Main branch trigger
print_info "Creating trigger for main branch deployments..."
gcloud builds triggers create cloud-source-repositories \
    --repo=${REPO_NAME} \
    --branch-pattern="^main$|^master$" \
    --build-config=cloudbuild.yaml \
    --name="deploy-${REPO_NAME}" \
    --description="Deploy Web3 workstation on push to main" \
    --substitutions="_ENVIRONMENT=production,_FORCE_APPLY=true" \
    --project=${PROJECT_ID} \
    --quiet 2>/dev/null || print_warning "Deploy trigger already exists or failed to create"

# Pull request trigger
print_info "Creating trigger for pull request validation..."
gcloud builds triggers create cloud-source-repositories \
    --repo=${REPO_NAME} \
    --branch-pattern="^PR-.*" \
    --build-config=cloudbuild.yaml \
    --name="validate-${REPO_NAME}-pr" \
    --description="Validate changes on pull request" \
    --substitutions="_ENVIRONMENT=development,_FORCE_APPLY=false" \
    --project=${PROJECT_ID} \
    --quiet 2>/dev/null || print_warning "PR trigger already exists or failed to create"

# Manual trigger
print_info "Creating manual deployment trigger..."
gcloud builds triggers create cloud-source-repositories \
    --repo=${REPO_NAME} \
    --branch-pattern=".*" \
    --build-config=cloudbuild.yaml \
    --name="manual-deploy-${REPO_NAME}" \
    --description="Manual deployment trigger" \
    --substitutions="_ENVIRONMENT=production,_FORCE_APPLY=true" \
    --project=${PROJECT_ID} \
    --require-approval \
    --quiet 2>/dev/null || print_warning "Manual trigger already exists or failed to create"

# Step 8: Create state bucket if it doesn't exist
STATE_BUCKET="${PROJECT_ID}-web3-workstation-terraform-state"
print_status "Checking Terraform state bucket..."
if gsutil ls -b gs://${STATE_BUCKET} &>/dev/null; then
    print_info "State bucket already exists"
else
    print_status "Creating Terraform state bucket..."
    gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${STATE_BUCKET}
    gsutil versioning set on gs://${STATE_BUCKET}
fi

# Step 9: Run the first build (optional)
echo ""
print_info "Setup complete!"
echo ""
echo "=================================================================================="
echo "Cloud Build has been configured successfully!"
echo ""
echo "Repository URL: ${REPO_URL}"
echo "Console URL: https://console.cloud.google.com/cloud-build/triggers?project=${PROJECT_ID}"
echo ""
echo "Next steps:"
echo "1. View your triggers:"
echo "   gcloud builds triggers list --project=${PROJECT_ID}"
echo ""
echo "2. Trigger a manual build:"
echo "   gcloud builds triggers run deploy-${REPO_NAME} --branch=main --project=${PROJECT_ID}"
echo ""
echo "3. View build history:"
echo "   gcloud builds list --project=${PROJECT_ID}"
echo ""
echo "4. Make changes and push to trigger automatic builds:"
echo "   git add ."
echo "   git commit -m 'Your changes'"
echo "   git push google main"
echo "=================================================================================="

# Ask if user wants to trigger first build
echo ""
read -p "Do you want to trigger the first build now? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Triggering first build..."
    gcloud builds triggers run deploy-${REPO_NAME} \
        --branch=main \
        --project=${PROJECT_ID}
    
    echo ""
    print_info "Build triggered! View progress at:"
    echo "https://console.cloud.google.com/cloud-build/builds?project=${PROJECT_ID}"
fi