#!/usr/bin/env bash
# Cloud deployment operations for Cloud Run
#
# Commands:
#   setup   - One-time setup (APIs, Artifact Registry, IAM)
#   deploy  - Build and deploy to Cloud Run
#   status  - Show Cloud Run service status
#   urls    - Show service URLs
#   logs    - View logs (default: opencode-web)
#   delete  - Delete all Cloud Run services

source "$(dirname "$0")/common.sh"
cd_project_root

# Configuration
PROJECT_ID="${GCP_PROJECT:-kunal-scratch}"
REGION="${GCP_REGION:-us-central1}"
REPO="coding-labs"

cmd_setup() {
  log_header "Setting up Cloud infrastructure"
  
  log_info "Project: $PROJECT_ID"
  log_info "Region: $REGION"
  log_info "Repository: $REPO"
  echo ""
  
  log_info "Enabling required APIs..."
  gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    --project="$PROJECT_ID"
  
  log_info "Creating Artifact Registry repository..."
  if gcloud artifacts repositories describe "$REPO" \
    --location="$REGION" \
    --project="$PROJECT_ID" &>/dev/null; then
    log_info "Repository '$REPO' already exists"
  else
    gcloud artifacts repositories create "$REPO" \
      --repository-format=docker \
      --location="$REGION" \
      --project="$PROJECT_ID" \
      --description="Coding Labs container images"
    log_success "Repository '$REPO' created"
  fi
  
  # Get project number
  PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
  
  log_info "Granting Cloud Build permissions..."
  
  # Cloud Build needs run.admin to deploy
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/run.admin" \
    --condition=None \
    --quiet 2>/dev/null
  
  # Cloud Build needs to act as service accounts
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --condition=None \
    --quiet 2>/dev/null
  
  # Default compute SA is used by Cloud Build for deploy steps
  # It needs Cloud Run admin and SA user permissions
  log_info "Granting Cloud Run permissions to default compute SA..."
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/run.admin" \
    --condition=None \
    --quiet 2>/dev/null
  
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --condition=None \
    --quiet 2>/dev/null
  
  # Default compute SA needs Vertex AI access for LLM calls
  log_info "Granting Vertex AI access to default compute SA..."
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/aiplatform.user" \
    --condition=None \
    --quiet 2>/dev/null
  
  echo ""
  log_success "Cloud infrastructure setup complete"
  echo ""
  log_info "Next steps:"
  log_info "  1. Run: make cloud-deploy"
  log_info "  2. Get URLs: make cloud-urls"
}

cmd_deploy() {
  log_header "Deploying to Cloud Run"
  
  # Get git short SHA for image tagging
  local tag
  tag=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
  
  log_info "Project: $PROJECT_ID"
  log_info "Region: $REGION"
  log_info "Repository: $REPO"
  log_info "Tag: $tag"
  echo ""
  
  log_info "Submitting build to Cloud Build..."
  echo ""
  
  gcloud builds submit \
    --config=cloudbuild.yaml \
    --project="$PROJECT_ID" \
    --substitutions="_REGION=$REGION,_REPO=$REPO,_TAG=$tag" \
    .
  
  echo ""
  log_success "Deployment complete"
  echo ""
  cmd_urls
}

cmd_status() {
  log_header "Cloud Run Services"
  gcloud run services list \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="table(SERVICE,REGION,URL,LAST_DEPLOYED_BY)"
}

cmd_urls() {
  log_header "Service URLs"
  local found=false
  for service in agent-registry somnia-agent opencode-web; do
    url=$(gcloud run services describe "$service" \
      --region="$REGION" \
      --project="$PROJECT_ID" \
      --format='value(status.url)' 2>/dev/null)
    if [[ -n "$url" ]]; then
      printf "  %-16s %s\n" "$service:" "$url"
      found=true
    fi
  done
  
  if [[ "$found" == "false" ]]; then
    log_warn "No services found. Run: make cloud-deploy"
  fi
}

cmd_logs() {
  local service="${1:-opencode-web}"
  log_header "Logs for $service"
  gcloud run services logs read "$service" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --limit=50
}

cmd_delete() {
  log_header "Deleting Cloud Run services"
  log_warn "This will delete all services!"
  read -p "Are you sure? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    for service in opencode-web somnia-agent agent-registry; do
      log_info "Deleting $service..."
      gcloud run services delete "$service" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --quiet 2>/dev/null || true
    done
    log_success "Services deleted"
  else
    log_info "Cancelled"
  fi
}

# Main
case "${1:-}" in
  setup)
    cmd_setup
    ;;
  deploy)
    cmd_deploy
    ;;
  status)
    cmd_status
    ;;
  urls)
    cmd_urls
    ;;
  logs)
    cmd_logs "${2:-}"
    ;;
  delete)
    cmd_delete
    ;;
  *)
    show_usage "cloud.sh" "
  setup       One-time setup (APIs, Artifact Registry, IAM)
  deploy      Build and deploy to Cloud Run
  status      Show Cloud Run service status
  urls        Show service URLs
  logs [svc]  View logs (default: opencode-web)
  delete      Delete all Cloud Run services

Environment variables:
  GCP_PROJECT  GCP project ID (default: kunal-scratch)
  GCP_REGION   GCP region (default: us-central1)"
    exit 1
    ;;
esac
