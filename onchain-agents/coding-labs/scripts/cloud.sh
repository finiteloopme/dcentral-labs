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
    iap.googleapis.com \
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
  
  echo "Midnight Infrastructure:"
  for service in midnight-node midnight-indexer midnight-proof-server; do
    url=$(gcloud run services describe "$service" \
      --region="$REGION" \
      --project="$PROJECT_ID" \
      --format='value(status.url)' 2>/dev/null)
    if [[ -n "$url" ]]; then
      printf "  %-24s %s\n" "$service:" "$url"
      found=true
    fi
  done
  
  echo ""
  echo "Application Services:"
  for service in agent-registry somnia-agent sonic-agent midnight-agent store-agent payment-agent midnight-mcp evm-mcp opencode-login opencode-web; do
    url=$(gcloud run services describe "$service" \
      --region="$REGION" \
      --project="$PROJECT_ID" \
      --format='value(status.url)' 2>/dev/null)
    if [[ -n "$url" ]]; then
      printf "  %-24s %s\n" "$service:" "$url"
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
    # Delete in reverse dependency order
    for service in opencode-web opencode-login payment-agent store-agent midnight-agent sonic-agent midnight-mcp evm-mcp somnia-agent agent-registry midnight-indexer midnight-proof-server midnight-node; do
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

cmd_sync_users() {
  log_header "Syncing IAP users from config.toml"
  
  # Parse allowed_users from config.toml using bun
  log_info "Reading allowed_users from config.toml..."
  USERS=$(bun -e "
    const fs = require('fs');
    const { parse } = require('smol-toml');
    const config = parse(fs.readFileSync('config.toml', 'utf-8'));
    const users = config.default?.auth?.allowed_users || [];
    console.log(users.join('\n'));
  " 2>/dev/null)
  
  if [[ -z "$USERS" ]]; then
    log_warn "No users found in config.toml [default.auth.allowed_users]"
    return 1
  fi
  
  log_info "Users in config.toml:"
  echo "$USERS" | while read -r user; do
    echo "  - $user"
  done
  echo ""
  
  # Get current IAP bindings
  log_info "Fetching current IAP bindings..."
  CURRENT=$(gcloud beta iap web get-iam-policy \
    --region="$REGION" \
    --resource-type=cloud-run \
    --service=opencode-web \
    --project="$PROJECT_ID" \
    --format='json' 2>/dev/null | \
    bun -e "
      const input = require('fs').readFileSync('/dev/stdin', 'utf-8');
      const policy = JSON.parse(input || '{}');
      const bindings = policy.bindings || [];
      const accessorBinding = bindings.find(b => b.role === 'roles/iap.httpsResourceAccessor');
      const members = accessorBinding?.members || [];
      const users = members
        .filter(m => m.startsWith('user:'))
        .map(m => m.replace('user:', ''));
      console.log(users.join('\n'));
    " 2>/dev/null || echo "")
  
  # Add new users
  log_info "Checking for users to add..."
  echo "$USERS" | while read -r user; do
    [[ -z "$user" ]] && continue
    if ! echo "$CURRENT" | grep -q "^${user}$"; then
      log_info "Adding: $user"
      gcloud beta iap web add-iam-policy-binding \
        --member="user:$user" \
        --role=roles/iap.httpsResourceAccessor \
        --region="$REGION" \
        --resource-type=cloud-run \
        --service=opencode-web \
        --project="$PROJECT_ID" \
        --quiet 2>/dev/null
    else
      log_info "Already exists: $user"
    fi
  done
  
  # Remove users not in config
  log_info "Checking for users to remove..."
  if [[ -n "$CURRENT" ]]; then
    echo "$CURRENT" | while read -r user; do
      [[ -z "$user" ]] && continue
      if ! echo "$USERS" | grep -q "^${user}$"; then
        log_warn "Removing: $user"
        gcloud beta iap web remove-iam-policy-binding \
          --member="user:$user" \
          --role=roles/iap.httpsResourceAccessor \
          --region="$REGION" \
          --resource-type=cloud-run \
          --service=opencode-web \
          --project="$PROJECT_ID" \
          --quiet 2>/dev/null
      fi
    done
  fi
  
  echo ""
  log_success "IAP users synced from config.toml"
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
  sync-users)
    cmd_sync_users
    ;;
  *)
    show_usage "cloud.sh" "
  setup       One-time setup (APIs, Artifact Registry, IAM)
  deploy      Build and deploy to Cloud Run
  status      Show Cloud Run service status
  urls        Show service URLs
  logs [svc]  View logs (default: opencode-web)
  delete      Delete all Cloud Run services
  sync-users  Sync IAP allowed users from config.toml

Environment variables:
  GCP_PROJECT  GCP project ID (default: kunal-scratch)
  GCP_REGION   GCP region (default: us-central1)"
    exit 1
    ;;
esac
