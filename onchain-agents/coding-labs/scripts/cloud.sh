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

  log_info "Enabling additional APIs (compute, dns, identitytoolkit)..."
  gcloud services enable \
    compute.googleapis.com \
    dns.googleapis.com \
    identitytoolkit.googleapis.com \
    --project="$PROJECT_ID"

  log_info "Creating IAP service identity (idempotent)..."
  gcloud beta services identity create --service=iap.googleapis.com \
    --project="$PROJECT_ID" 2>/dev/null || true
  
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
  
  log_info "Checking config.toml for cross-project DNS configuration..."
  DNS_PROJECT=$(_dns_field project_id 2>/dev/null || echo '')

  if [[ -z "$DNS_PROJECT" || "$DNS_PROJECT" == "<DNS_PROJECT_ID>" ]]; then
    log_warn "config.toml [default.dns].project_id is unset/placeholder."
    log_warn "Skipping cross-project DNS IAM grant. Edit config.toml and re-run"
    log_warn "'make cloud-setup' to grant when ready."
  elif [[ "$DNS_PROJECT" == "$PROJECT_ID" ]]; then
    log_info "DNS zone is in same project ($PROJECT_ID); no cross-project grant needed."
  else
    log_info "Granting cross-project DNS access to $DNS_PROJECT..."
    CB_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
    COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
    GRANT_FAILED=0

    for SA in "$CB_SA" "$COMPUTE_SA"; do
      if ! gcloud projects add-iam-policy-binding "$DNS_PROJECT" \
             --member="serviceAccount:$SA" \
             --role="roles/dns.recordSetEditor" \
             --condition=None --quiet 2>/dev/null; then
        log_warn "  Failed to grant for $SA"
        GRANT_FAILED=1
      fi
    done

    if [[ "$GRANT_FAILED" -eq 1 ]]; then
      log_warn ""
      log_warn "Cross-project IAM grant failed. You may not have permission on the"
      log_warn "DNS-hosting project. Either grant manually OR ask the DNS project"
      log_warn "owner to run:"
      log_warn ""
      log_warn "  gcloud projects add-iam-policy-binding $DNS_PROJECT \\"
      log_warn "    --member=serviceAccount:$CB_SA \\"
      log_warn "    --role=roles/dns.recordSetEditor"
      log_warn ""
      log_warn "  gcloud projects add-iam-policy-binding $DNS_PROJECT \\"
      log_warn "    --member=serviceAccount:$COMPUTE_SA \\"
      log_warn "    --role=roles/dns.recordSetEditor"
    else
      log_success "Cross-project DNS IAM granted on $DNS_PROJECT"
    fi
  fi

  echo ""
  log_success "Cloud infrastructure setup complete"
  echo ""
  log_info "Next steps:"
  log_info "  1. Fill in config.toml [default.dns] if not done; re-run 'make cloud-setup' to grant cross-project IAM"
  log_info "  2. Run: make cloud-setup-gcip-magiclink (enables email-link + emits Firebase config)"
  log_info "  3. Run: make cloud-deploy"
  log_info "  4. Run: make cloud-setup-dns"
  log_info "  5. Run: make cloud-setup-lb"
  log_info "  6. Manual: apply IAP gcipSettings YAML (see gcip-magiclink-setup.md Phase 4)"
  log_info "  7. Run: make cloud-sync-iap-users"
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

# -----------------------------------------------------------------------------
# Helpers for parsing [default.dns] from config.toml via smol-toml + bun
# -----------------------------------------------------------------------------
_dns_field() {
  # $1 = field name (project_id, zone_name, base_domain, subdomain)
  bun -e "
    const fs = require('fs');
    const { parse } = require('smol-toml');
    const config = parse(fs.readFileSync('config.toml', 'utf-8'));
    console.log(config.default?.dns?.${1} || '');
  " 2>/dev/null
}

_require_dns_config() {
  # Read all DNS fields and validate they're populated (not placeholder values).
  # Sets DNS_PROJECT, ZONE_NAME, BASE_DOMAIN, SUBDOMAIN, FQDN as globals.
  DNS_PROJECT=$(_dns_field project_id)
  ZONE_NAME=$(_dns_field zone_name)
  BASE_DOMAIN=$(_dns_field base_domain)
  SUBDOMAIN=$(_dns_field subdomain)

  if [[ -z "$DNS_PROJECT" || "$DNS_PROJECT" == "<DNS_PROJECT_ID>" ]]; then
    log_error "config.toml [default.dns].project_id is not set."
    log_error "Edit config.toml and fill in the [default.dns] block first."
    log_error "See gcip-magiclink-setup.md Phase 0 for guidance."
    return 1
  fi
  if [[ -z "$ZONE_NAME" || "$ZONE_NAME" == "<ZONE_NAME>" ]]; then
    log_error "config.toml [default.dns].zone_name is not set."
    return 1
  fi
  if [[ -z "$BASE_DOMAIN" || "$BASE_DOMAIN" == "<BASE_DOMAIN>" ]]; then
    log_error "config.toml [default.dns].base_domain is not set."
    return 1
  fi
  if [[ -z "$SUBDOMAIN" ]]; then
    log_error "config.toml [default.dns].subdomain is not set."
    return 1
  fi

  # Construct FQDN. base_domain may end with a dot (Cloud DNS convention).
  # Strip trailing dot, concat subdomain, then re-add trailing dot.
  FQDN="${SUBDOMAIN}.${BASE_DOMAIN%.}."
  return 0
}

cmd_setup_dns() {
  log_header "Setting up cross-project DNS A record"

  _require_dns_config || return 1

  log_info "DNS project:  $DNS_PROJECT"
  log_info "Managed zone: $ZONE_NAME"
  log_info "FQDN:         $FQDN"
  echo ""

  # Reserve global IP in kunal-scratch (LB project) if not already present
  LB_IP=$(gcloud compute addresses describe opencode-web-lb-ip \
    --global --project="$PROJECT_ID" --format='value(address)' 2>/dev/null || true)

  if [[ -z "$LB_IP" ]]; then
    log_info "Reserving global IP: opencode-web-lb-ip"
    gcloud compute addresses create opencode-web-lb-ip \
      --global --project="$PROJECT_ID" --quiet
    LB_IP=$(gcloud compute addresses describe opencode-web-lb-ip \
      --global --project="$PROJECT_ID" --format='value(address)')
  fi

  log_info "LB IP: $LB_IP"

  # Idempotent: update existing A record, or create one
  if gcloud dns record-sets describe "$FQDN" --type=A \
       --zone="$ZONE_NAME" --project="$DNS_PROJECT" &>/dev/null; then
    log_info "A record exists; updating to $LB_IP"
    gcloud dns record-sets update "$FQDN" --type=A --ttl=300 \
      --rrdatas="$LB_IP" --zone="$ZONE_NAME" --project="$DNS_PROJECT"
  else
    log_info "Creating A record"
    gcloud dns record-sets create "$FQDN" --type=A --ttl=300 \
      --rrdatas="$LB_IP" --zone="$ZONE_NAME" --project="$DNS_PROJECT"
  fi

  echo ""
  log_success "DNS A record set: $FQDN → $LB_IP"
}

cmd_setup_lb() {
  log_header "Provisioning LB resources for opencode-web + opencode-login"

  _require_dns_config || return 1

  # Strip trailing dot for SSL cert (cert domains do NOT use trailing dot)
  CERT_DOMAIN="${FQDN%.}"

  log_info "Project:    $PROJECT_ID"
  log_info "Region:     $REGION"
  log_info "FQDN:       $FQDN"
  log_info "Cert SAN:   $CERT_DOMAIN"
  echo ""

  # 1) Reserved global IP (cmd_setup_dns may have already created it)
  if ! gcloud compute addresses describe opencode-web-lb-ip \
        --global --project="$PROJECT_ID" &>/dev/null; then
    log_info "Reserving global IP: opencode-web-lb-ip"
    gcloud compute addresses create opencode-web-lb-ip \
      --global --project="$PROJECT_ID" --quiet
  else
    log_info "Global IP opencode-web-lb-ip already exists"
  fi

  # 2) Google-managed SSL cert (provisioning is async, takes 10-15 min)
  if ! gcloud compute ssl-certificates describe opencode-web-cert \
        --global --project="$PROJECT_ID" &>/dev/null; then
    log_info "Creating Google-managed SSL cert for $CERT_DOMAIN"
    gcloud compute ssl-certificates create opencode-web-cert \
      --domains="$CERT_DOMAIN" \
      --global --project="$PROJECT_ID" --quiet
  else
    log_info "SSL cert opencode-web-cert already exists"
  fi

  # 3) Serverless NEGs (one per Cloud Run service)
  for entry in "opencode-web-neg:opencode-web" "opencode-login-neg:opencode-login"; do
    NEG_NAME="${entry%%:*}"
    SVC_NAME="${entry##*:}"
    if ! gcloud compute network-endpoint-groups describe "$NEG_NAME" \
          --region="$REGION" --project="$PROJECT_ID" &>/dev/null; then
      log_info "Creating serverless NEG: $NEG_NAME → $SVC_NAME"
      gcloud compute network-endpoint-groups create "$NEG_NAME" \
        --region="$REGION" \
        --network-endpoint-type=serverless \
        --cloud-run-service="$SVC_NAME" \
        --project="$PROJECT_ID" --quiet
    else
      log_info "NEG $NEG_NAME already exists"
    fi
  done

  # 4) Backend services
  for entry in "opencode-web-backend:opencode-web-neg" "opencode-login-backend:opencode-login-neg"; do
    BS_NAME="${entry%%:*}"
    NEG_NAME="${entry##*:}"
    if ! gcloud compute backend-services describe "$BS_NAME" \
          --global --project="$PROJECT_ID" &>/dev/null; then
      log_info "Creating backend service: $BS_NAME"
      gcloud compute backend-services create "$BS_NAME" \
        --global \
        --load-balancing-scheme=EXTERNAL_MANAGED \
        --project="$PROJECT_ID" --quiet
      gcloud compute backend-services add-backend "$BS_NAME" \
        --global \
        --network-endpoint-group="$NEG_NAME" \
        --network-endpoint-group-region="$REGION" \
        --project="$PROJECT_ID" --quiet
    else
      log_info "Backend service $BS_NAME already exists"
    fi
  done

  # 5) URL map with path-based routing
  #    /login*       → opencode-login-backend
  #    /__/auth/*    → opencode-login-backend
  #    everything else (default) → opencode-web-backend
  if ! gcloud compute url-maps describe opencode-url-map \
        --global --project="$PROJECT_ID" &>/dev/null; then
    log_info "Creating URL map: opencode-url-map"
    gcloud compute url-maps create opencode-url-map \
      --default-service=opencode-web-backend \
      --global --project="$PROJECT_ID" --quiet

    log_info "Adding path matcher (login + auth handlers → opencode-login-backend)"
    gcloud compute url-maps add-path-matcher opencode-url-map \
      --path-matcher-name=login-paths \
      --default-service=opencode-web-backend \
      --new-hosts="$CERT_DOMAIN" \
      --backend-service-path-rules="/login=opencode-login-backend,/login/*=opencode-login-backend,/__/auth/*=opencode-login-backend" \
      --global --project="$PROJECT_ID" --quiet
  else
    log_info "URL map opencode-url-map already exists"
  fi

  # 6) Target HTTPS proxy
  if ! gcloud compute target-https-proxies describe opencode-https-proxy \
        --global --project="$PROJECT_ID" &>/dev/null; then
    log_info "Creating target HTTPS proxy: opencode-https-proxy"
    gcloud compute target-https-proxies create opencode-https-proxy \
      --url-map=opencode-url-map \
      --ssl-certificates=opencode-web-cert \
      --global --project="$PROJECT_ID" --quiet
  else
    log_info "Target HTTPS proxy opencode-https-proxy already exists"
  fi

  # 7) Global forwarding rule (port 443)
  if ! gcloud compute forwarding-rules describe opencode-fwd-rule \
        --global --project="$PROJECT_ID" &>/dev/null; then
    log_info "Creating forwarding rule: opencode-fwd-rule (443)"
    gcloud compute forwarding-rules create opencode-fwd-rule \
      --address=opencode-web-lb-ip \
      --target-https-proxy=opencode-https-proxy \
      --ports=443 \
      --load-balancing-scheme=EXTERNAL_MANAGED \
      --global --project="$PROJECT_ID" --quiet
  else
    log_info "Forwarding rule opencode-fwd-rule already exists"
  fi

  # 8) Enable IAP on opencode-web-backend ONLY (login backend stays public)
  log_info "Enabling IAP on opencode-web-backend (login backend stays public)"
  gcloud iap web enable \
    --resource-type=backend-services \
    --service=opencode-web-backend \
    --project="$PROJECT_ID" 2>/dev/null || log_warn "IAP enable skipped (already enabled or requires manual gcipSettings step)"

  echo ""
  log_success "LB resources provisioned"
  echo ""
  log_info "Next manual step (one-time):"
  log_info "  Apply IAP gcipSettings YAML for the agent-flow tenantIds pattern."
  log_info "  See gcip-magiclink-setup.md Phase 4."
  log_info ""
  log_info "Then bind users: make cloud-sync-iap-users"
}

cmd_setup_gcip_magiclink() {
  log_header "Enabling GCIP email-link sign-in"

  log_info "Project: $PROJECT_ID"
  echo ""

  ACCESS_TOKEN=$(gcloud auth print-access-token)

  curl -sS -X PATCH \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "x-goog-user-project: $PROJECT_ID" \
    -H "Content-Type: application/json" \
    "https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/config?updateMask=signIn.email" \
    -d '{"signIn":{"email":{"enabled":true,"passwordRequired":false}}}'

  echo ""
  log_success "GCIP email-link sign-in enabled in project $PROJECT_ID"

  # === Emit current Firebase public config for the operator ===
  echo ""
  log_info "Fetching current Firebase public config..."
  RESPONSE=$(curl -sS -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "x-goog-user-project: $PROJECT_ID" \
    "https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/config" \
    || echo '{}')

  read -r API_KEY SUBDOMAIN < <(echo "$RESPONSE" | bun -e "
    const r = JSON.parse(require('fs').readFileSync('/dev/stdin', 'utf-8'));
    console.log((r.client?.apiKey || '') + ' ' + (r.client?.firebaseSubdomain || ''));
  " 2>/dev/null)

  if [[ -z "$API_KEY" ]]; then
    log_warn "Could not extract apiKey from Identity Toolkit response."
    log_warn "Raw response (first 300 chars): ${RESPONSE:0:300}"
    log_warn "Manually fetch from: https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
    return 0
  fi

  AUTH_DOMAIN="${SUBDOMAIN:-$PROJECT_ID}.firebaseapp.com"

  echo ""
  log_success "Firebase public config (use as Cloud Build substitutions):"
  echo ""
  echo "  _FIREBASE_API_KEY=$API_KEY"
  echo "  _FIREBASE_AUTH_DOMAIN=$AUTH_DOMAIN"
  echo "  _FIREBASE_PROJECT_ID=$PROJECT_ID"
  echo ""
  log_info "Pass these to Cloud Build:"
  echo ""
  echo "  gcloud builds submit --substitutions=\\"
  echo "    _FIREBASE_API_KEY=$API_KEY,\\"
  echo "    _FIREBASE_AUTH_DOMAIN=$AUTH_DOMAIN,\\"
  echo "    _FIREBASE_PROJECT_ID=$PROJECT_ID,..."
  echo ""
  log_info "Or set them in your shell environment:"
  echo ""
  echo "  export _FIREBASE_API_KEY=$API_KEY"
  echo "  export _FIREBASE_AUTH_DOMAIN=$AUTH_DOMAIN"
  echo "  export _FIREBASE_PROJECT_ID=$PROJECT_ID"
  echo ""
  log_info "These values are PUBLIC by Firebase design — safe to commit/share."
  log_info "Security comes from authorized-domain whitelist + Security Rules,"
  log_info "not from secrecy of the apiKey."
}

cmd_sync_iap_users() {
  log_header "Syncing IAP users from config.toml to opencode-web-backend"

  # Parse allowed_users from config.toml using bun + smol-toml
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
    [[ -n "$user" ]] && echo "  - $user"
  done
  echo ""

  # Get current bindings on the backend service (NOT cloud-run anymore)
  log_info "Fetching current IAP bindings on opencode-web-backend..."
  CURRENT=$(gcloud iap web get-iam-policy \
    --resource-type=backend-services \
    --service=opencode-web-backend \
    --project="$PROJECT_ID" \
    --format='json' 2>/dev/null | \
    bun -e "
      const input = require('fs').readFileSync('/dev/stdin', 'utf-8');
      const policy = JSON.parse(input || '{}');
      const accessor = (policy.bindings || []).find(b =>
        b.role === 'roles/iap.httpsResourceAccessor');
      const users = (accessor?.members || [])
        .filter(m => m.startsWith('user:'))
        .map(m => m.replace('user:', ''));
      console.log(users.join('\n'));
    " 2>/dev/null || echo "")

  # Add new users
  log_info "Adding users present in config.toml..."
  echo "$USERS" | while read -r user; do
    [[ -z "$user" ]] && continue
    if ! echo "$CURRENT" | grep -qx "$user"; then
      log_info "  Adding: $user"
      gcloud iap web add-iam-policy-binding \
        --member="user:$user" \
        --role=roles/iap.httpsResourceAccessor \
        --resource-type=backend-services \
        --service=opencode-web-backend \
        --project="$PROJECT_ID" \
        --quiet 2>/dev/null
    else
      log_info "  Already exists: $user"
    fi
  done

  # Remove users not in config
  log_info "Removing users no longer in config.toml..."
  if [[ -n "$CURRENT" ]]; then
    echo "$CURRENT" | while read -r user; do
      [[ -z "$user" ]] && continue
      if ! echo "$USERS" | grep -qx "$user"; then
        log_warn "  Removing: $user"
        gcloud iap web remove-iam-policy-binding \
          --member="user:$user" \
          --role=roles/iap.httpsResourceAccessor \
          --resource-type=backend-services \
          --service=opencode-web-backend \
          --project="$PROJECT_ID" \
          --quiet 2>/dev/null
      fi
    done
  fi

  echo ""
  log_success "IAP users synced to opencode-web-backend"
}

cmd_teardown_lb() {
  log_header "Tearing down LB resources (DESTRUCTIVE)"

  log_warn "This will REMOVE the LB and BREAK the deployment."
  log_warn "Cloud DNS records and Cloud Run services are NOT touched."
  read -r -p "Are you sure? [y/N]: " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Cancelled"
    return 0
  fi

  # Delete in reverse dependency order; ignore errors if resource is absent
  for cmd in \
    "gcloud compute forwarding-rules delete opencode-fwd-rule --global --quiet --project=$PROJECT_ID" \
    "gcloud compute target-https-proxies delete opencode-https-proxy --global --quiet --project=$PROJECT_ID" \
    "gcloud compute url-maps delete opencode-url-map --global --quiet --project=$PROJECT_ID" \
    "gcloud iap web disable --resource-type=backend-services --service=opencode-web-backend --project=$PROJECT_ID" \
    "gcloud compute backend-services delete opencode-web-backend --global --quiet --project=$PROJECT_ID" \
    "gcloud compute backend-services delete opencode-login-backend --global --quiet --project=$PROJECT_ID" \
    "gcloud compute network-endpoint-groups delete opencode-web-neg --region=$REGION --quiet --project=$PROJECT_ID" \
    "gcloud compute network-endpoint-groups delete opencode-login-neg --region=$REGION --quiet --project=$PROJECT_ID" \
    "gcloud compute ssl-certificates delete opencode-web-cert --global --quiet --project=$PROJECT_ID" \
    "gcloud compute addresses delete opencode-web-lb-ip --global --quiet --project=$PROJECT_ID"; do
    log_info "Running: $cmd"
    eval "$cmd" 2>/dev/null || true
  done

  echo ""
  log_success "LB resources removed"
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
  setup-dns)
    cmd_setup_dns
    ;;
  setup-lb)
    cmd_setup_lb
    ;;
  setup-gcip-magiclink)
    cmd_setup_gcip_magiclink
    ;;
  sync-iap-users)
    cmd_sync_iap_users
    ;;
  teardown-lb)
    cmd_teardown_lb
    ;;
  *)
    show_usage "cloud.sh" "
  setup                  One-time setup (APIs, Artifact Registry, IAM)
  deploy                 Build and deploy to Cloud Run
  status                 Show Cloud Run service status
  urls                   Show service URLs
  logs [svc]             View logs (default: opencode-web)
  delete                 Delete all Cloud Run services

  setup-dns              Create cross-project DNS A record from config.toml
  setup-lb               Provision LB resources (NEGs, backend services,
                         URL map with path routing, SSL cert, fwd rule)
  setup-gcip-magiclink   Enable GCIP email-link sign-in in this project
  sync-iap-users         Sync IAP allowed_users from config.toml to the
                         opencode-web-backend backend service
  teardown-lb            DESTRUCTIVE: remove all LB resources

Environment variables:
  GCP_PROJECT  GCP project ID (default: kunal-scratch)
  GCP_REGION   GCP region (default: us-central1)"
    exit 1
    ;;
esac
