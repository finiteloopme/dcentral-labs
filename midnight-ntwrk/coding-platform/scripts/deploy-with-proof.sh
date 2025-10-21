#!/bin/bash
#
# Deploy to Google Cloud with proof service configuration
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
REGION="${REGION:-us-central1}"
PROOF_MODE="${PROOF_SERVICE_MODE:-local}"
PROOF_URL="${PROOF_SERVICE_URL:-}"
PROOF_KEY="${PROOF_SERVICE_API_KEY:-}"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy Midnight Platform to Google Cloud with proof service configuration"
    echo ""
    echo "Options:"
    echo "  --project PROJECT_ID       GCP project ID"
    echo "  --env ENVIRONMENT         Environment (dev/staging/prod)"
    echo "  --region REGION           GCP region (default: us-central1)"
    echo "  --proof-mode MODE         Proof mode: local or external"
    echo "  --proof-url URL           External proof service URL"
    echo "  --proof-key KEY           API key for proof service"
    echo "  --midnight                Use Midnight proof service"
    echo "  --auto-approve            Auto-approve Terraform changes"
    echo "  --help                    Show this help"
    echo ""
    echo "Examples:"
    echo "  # Deploy with local proof service"
    echo "  $0 --env dev"
    echo ""
    echo "  # Deploy with Midnight proof service"
    echo "  $0 --env staging --midnight"
    echo ""
    echo "  # Deploy with custom proof service"
    echo "  $0 --env prod --proof-url https://my-proof.com --proof-key secret"
    echo ""
}

# Parse arguments
AUTO_APPROVE="false"
while [[ $# -gt 0 ]]; do
    case $1 in
        --project)
            PROJECT_ID="$2"
            shift 2
            ;;
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --proof-mode)
            PROOF_MODE="$2"
            shift 2
            ;;
        --proof-url)
            PROOF_URL="$2"
            PROOF_MODE="external"
            shift 2
            ;;
        --proof-key)
            PROOF_KEY="$2"
            shift 2
            ;;
        --midnight)
            PROOF_MODE="external"
            PROOF_URL="https://proof-api.midnight.network"
            shift
            ;;
        --auto-approve)
            AUTO_APPROVE="true"
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Validate project
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: PROJECT_ID not set${NC}"
    echo "Set with: --project PROJECT_ID or export PROJECT_ID=your-project"
    exit 1
fi

# Show configuration
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Deploying Midnight Platform to Google Cloud${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project: $PROJECT_ID"
echo "  Environment: $ENVIRONMENT"
echo "  Region: $REGION"
echo ""
echo -e "${YELLOW}Proof Service:${NC}"
echo "  Mode: $PROOF_MODE"
if [ "$PROOF_MODE" = "external" ]; then
    echo "  URL: $PROOF_URL"
    [ -n "$PROOF_KEY" ] && echo "  API Key: [SET]"
fi
echo ""

# Build substitutions
SUBSTITUTIONS="_ENVIRONMENT=${ENVIRONMENT}"
SUBSTITUTIONS="${SUBSTITUTIONS},_REGION=${REGION}"
SUBSTITUTIONS="${SUBSTITUTIONS},_ZONE=${REGION}-a"
SUBSTITUTIONS="${SUBSTITUTIONS},_TERRAFORM_ACTION=apply"
SUBSTITUTIONS="${SUBSTITUTIONS},_AUTO_APPROVE=${AUTO_APPROVE}"
SUBSTITUTIONS="${SUBSTITUTIONS},_PROOF_SERVICE_MODE=${PROOF_MODE}"

if [ -n "$PROOF_URL" ]; then
    SUBSTITUTIONS="${SUBSTITUTIONS},_PROOF_SERVICE_URL=${PROOF_URL}"
fi

if [ -n "$PROOF_KEY" ]; then
    # For production, use Secret Manager
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo -e "${YELLOW}Storing API key in Secret Manager...${NC}"
        echo -n "$PROOF_KEY" | gcloud secrets create proof-api-key-${ENVIRONMENT} \
            --data-file=- \
            --project="$PROJECT_ID" 2>/dev/null || \
        echo -n "$PROOF_KEY" | gcloud secrets versions add proof-api-key-${ENVIRONMENT} \
            --data-file=- \
            --project="$PROJECT_ID"
        
        # Grant Cloud Build access to the secret
        gcloud secrets add-iam-policy-binding proof-api-key-${ENVIRONMENT} \
            --member="serviceAccount:midnight-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
            --role="roles/secretmanager.secretAccessor" \
            --project="$PROJECT_ID"
        
        # Reference secret in substitution
        SUBSTITUTIONS="${SUBSTITUTIONS},_PROOF_SERVICE_API_KEY=\$(gcloud secrets versions access latest --secret=proof-api-key-${ENVIRONMENT})"
    else
        SUBSTITUTIONS="${SUBSTITUTIONS},_PROOF_SERVICE_API_KEY=${PROOF_KEY}"
    fi
fi

# Confirm before deployment
if [ "$AUTO_APPROVE" != "true" ]; then
    echo -e "${YELLOW}Ready to deploy. Continue? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 0
    fi
fi

# Submit to Cloud Build
echo -e "${BLUE}Submitting to Cloud Build...${NC}"
gcloud builds submit \
    --config=cicd/cloudbuild/cloudbuild.yaml \
    --substitutions="$SUBSTITUTIONS" \
    --project="$PROJECT_ID" \
    .

# Check build status
BUILD_ID=$(gcloud builds list --limit=1 --project="$PROJECT_ID" --format="value(id)")
echo ""
echo -e "${GREEN}Build submitted successfully!${NC}"
echo "Build ID: $BUILD_ID"
echo ""
echo "Monitor progress:"
echo "  gcloud builds log $BUILD_ID --stream"
echo ""
echo "Or view in console:"
echo "  https://console.cloud.google.com/cloud-build/builds/$BUILD_ID?project=$PROJECT_ID"