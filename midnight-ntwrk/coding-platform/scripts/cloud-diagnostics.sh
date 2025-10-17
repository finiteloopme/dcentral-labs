#!/bin/bash

# Cloud Build Diagnostics Script
# Diagnoses Cloud Build configuration and permissions

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get project ID
PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: No project ID provided${NC}"
    echo "Usage: $0 [PROJECT_ID]"
    exit 1
fi

echo -e "${YELLOW}Diagnosing Cloud Build Configuration for $PROJECT_ID${NC}"
echo ""

# Project information
echo "Project Information:"
echo "  Project ID: $PROJECT_ID"
PROJECT_NUM=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)" 2>/dev/null || echo "ERROR")
echo "  Project Number: $PROJECT_NUM"
echo ""

# Check APIs
echo "API Status:"
check_api() {
    local api=$1
    local name=$2
    if gcloud services list --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        echo -e "  $name: ${GREEN}✅ Enabled${NC}"
    else
        echo -e "  $name: ${RED}❌ Disabled${NC}"
    fi
}

check_api "cloudbuild.googleapis.com" "Cloud Build API"
check_api "artifactregistry.googleapis.com" "Artifact Registry API"
check_api "compute.googleapis.com" "Compute API"
check_api "workstations.googleapis.com" "Workstations API"
echo ""

# Cloud Build Service Account
echo "Cloud Build Service Account:"
SA_EMAIL="${PROJECT_NUM}@cloudbuild.gserviceaccount.com"
echo "  Account: $SA_EMAIL"
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
    echo -e "  Status: ${GREEN}✅ Exists${NC}"
    
    # Check roles
    echo "  Roles:"
    ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --filter="bindings.members:$SA_EMAIL" --format="value(bindings.role)" 2>/dev/null)
    if [ -n "$ROLES" ]; then
        echo "$ROLES" | while read -r role; do
            echo "    - $role"
        done
    else
        echo -e "    ${RED}No roles assigned${NC}"
    fi
else
    echo -e "  Status: ${RED}❌ Not found${NC}"
fi
echo ""

# State Bucket
echo "Terraform State Bucket:"
BUCKET="gs://${PROJECT_ID}-terraform-state"
if gsutil ls "$BUCKET" &>/dev/null; then
    echo -e "  $BUCKET: ${GREEN}✅ Exists${NC}"
    
    # Check permissions
    if gsutil iam get "$BUCKET" &>/dev/null; then
        echo "  Permissions: Accessible"
    else
        echo -e "  Permissions: ${YELLOW}⚠️  Cannot read permissions${NC}"
    fi
else
    echo -e "  $BUCKET: ${RED}❌ Not found${NC}"
fi
echo ""

# Artifact Registry
echo "Artifact Registry:"
REPO_NAME="midnight-images"
if gcloud artifacts repositories describe "$REPO_NAME" --location=us-central1 --project="$PROJECT_ID" &>/dev/null; then
    echo -e "  Repository '$REPO_NAME': ${GREEN}✅ Exists${NC}"
else
    echo -e "  Repository '$REPO_NAME': ${RED}❌ Not found${NC}"
fi
echo ""

# Cloud Build Triggers
echo "Cloud Build Triggers:"
TRIGGERS=$(gcloud builds triggers list --project="$PROJECT_ID" --format="value(name)" 2>/dev/null)
if [ -n "$TRIGGERS" ]; then
    echo "$TRIGGERS" | while read -r trigger; do
        echo "  - $trigger"
    done
else
    echo "  No triggers configured"
fi
echo ""

# Recent Builds
echo "Recent Cloud Builds:"
BUILDS=$(gcloud builds list --limit=3 --project="$PROJECT_ID" --format="table(id,status,createTime.date())" 2>/dev/null)
if [ -n "$BUILDS" ]; then
    echo "$BUILDS"
else
    echo "  No builds found"
fi
echo ""

# Recommendations
echo -e "${YELLOW}Recommendations:${NC}"
if [ "$PROJECT_NUM" = "ERROR" ]; then
    echo -e "  ${RED}• Project not found or not accessible${NC}"
fi

# Check if any required APIs are disabled
if ! gcloud services list --enabled --filter="name:cloudbuild.googleapis.com" --format="value(name)" | grep -q "cloudbuild"; then
    echo -e "  ${RED}• Enable Cloud Build API: gcloud services enable cloudbuild.googleapis.com${NC}"
fi

if ! gcloud services list --enabled --filter="name:artifactregistry.googleapis.com" --format="value(name)" | grep -q "artifact"; then
    echo -e "  ${RED}• Enable Artifact Registry API: gcloud services enable artifactregistry.googleapis.com${NC}"
fi

# Check if state bucket exists
if ! gsutil ls "$BUCKET" &>/dev/null; then
    echo -e "  ${YELLOW}• Create state bucket: gsutil mb gs://${PROJECT_ID}-terraform-state${NC}"
fi

echo ""
echo -e "${GREEN}To fix all issues, run: make cloud-setup${NC}"