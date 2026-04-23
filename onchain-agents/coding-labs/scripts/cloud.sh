#!/usr/bin/env bash
# Cloud deployment operations for Cloud Run + LB + IAP + GCIP
#
# Operator workflow (one-time per environment):
#   1. make cloud-setup       (bootstraps project + DNS + LB + auth)
#   2. make cloud-deploy      (build + deploy services; auto Firebase substitutions)
#   3. make cloud-sync-users  (bind allowed_users from config.toml to IAP IAM)
#
# Recurring:
#   make cloud-deploy         (re-deploy code; no manual env-var fixes needed)
#   make cloud-sync-users     (when allowed_users changes)
#
# Commands (top-level):
#   setup            One-time meta bootstrap (project + dns + lb + auth)
#   deploy           Build and deploy to Cloud Run (auto Firebase substitutions)
#   status           Show Cloud Run service status
#   urls             Show service URLs
#   logs [svc]       View logs (default: opencode-web)
#   sync-users       Sync IAP allowed_users from config.toml
#   teardown         DESTRUCTIVE: tear down LB + Cloud Run services
#
# Commands (advanced sub-targets, called by `setup`; useful for recovery):
#   setup-project    APIs + project IAM only
#   setup-dns        Cross-project DNS A record only
#   setup-lb         LB resources + URL map + IAP enable
#   setup-auth       GCIP Google IdP + authorizedDomains + IAP gcipSettings

source "$(dirname "$0")/common.sh"
cd_project_root

# Configuration
PROJECT_ID="${GCP_PROJECT:-kunal-scratch}"
REGION="${GCP_REGION:-us-central1}"
REPO="coding-labs"

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
    log_error "See gcip-google-signin-setup.md for guidance."
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

# Source .env file if present (for GOOGLE_OAUTH_CLIENT_SECRET, etc.)
_load_env() {
  local env_file
  env_file="$(cd_project_root && pwd)/.env"
  if [[ -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    set -a
    source "$env_file"
    set +a
  fi
}

# Read OAuth Client ID from config.toml [default.auth.google].client_id
_oauth_client_id() {
  bun -e "
    const fs = require('fs');
    const { parse } = require('smol-toml');
    const config = parse(fs.readFileSync('config.toml', 'utf-8'));
    console.log(config.default?.auth?.google?.client_id || '');
  " 2>/dev/null
}

# Read OAuth Client Secret from environment (after _load_env has sourced .env)
_oauth_client_secret() {
  echo "${GOOGLE_OAUTH_CLIENT_SECRET:-}"
}

# Read deployment FQDN from config.toml [default.dns] (subdomain + base_domain)
_deployment_fqdn() {
  local sub base
  sub=$(_dns_field subdomain)
  base=$(_dns_field base_domain | sed 's/\.$//')  # strip trailing dot
  if [[ -z "$sub" || -z "$base" ]]; then
    return 1
  fi
  echo "${sub}.${base}"
}

# -----------------------------------------------------------------------------
# Meta: full one-time bootstrap (project + DNS + LB + auth)
# -----------------------------------------------------------------------------
cmd_setup() {
  log_header "Full Cloud bootstrap"
  cmd_setup_project || return 1
  cmd_setup_dns || return 1
  cmd_setup_lb || return 1
  cmd_setup_auth || return 1
  echo ""
  log_success "Full Cloud bootstrap complete"
  log_info ""
  log_info "Next steps:"
  log_info "  1. Run: make cloud-deploy"
  log_info "  2. Run: make cloud-sync-users"
}

# -----------------------------------------------------------------------------
# Project bootstrap: APIs + IAM (formerly cmd_setup)
# -----------------------------------------------------------------------------
cmd_setup_project() {
  log_header "Setting up Cloud project (APIs + IAM)"

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
  log_success "Cloud project setup complete"
}

# -----------------------------------------------------------------------------
# Deploy: build + push + deploy. Auto-supplies Firebase substitutions.
# -----------------------------------------------------------------------------
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

  # Auto-fetch Firebase public config so opencode-login renders the Google
  # sign-in UI without manual substitution flags. Eliminates the recurring
  # empty-env-var bug after redeploys.
  log_info "Fetching current Firebase public config for substitutions..."
  local access_token response api_key auth_domain
  access_token=$(gcloud auth print-access-token 2>/dev/null)
  response=$(curl -sS -H "Authorization: Bearer $access_token" \
    -H "x-goog-user-project: $PROJECT_ID" \
    "https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/config" || echo '{}')
  api_key=$(echo "$response" | bun -e "
    const r = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
    console.log(r.client?.apiKey || '');
  ")
  auth_domain="${PROJECT_ID}.firebaseapp.com"

  if [[ -z "$api_key" ]]; then
    log_warn "Firebase apiKey unavailable; opencode-login will deploy with empty FIREBASE_API_KEY env var."
    log_warn "Run 'make cloud-setup-auth' first to ensure GCIP is configured."
  fi

  log_info "Submitting build to Cloud Build..."
  echo ""

  gcloud builds submit \
    --config=cloudbuild.yaml \
    --project="$PROJECT_ID" \
    --substitutions="_REGION=$REGION,_REPO=$REPO,_TAG=$tag,_FIREBASE_API_KEY=$api_key,_FIREBASE_AUTH_DOMAIN=$auth_domain" \
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

# -----------------------------------------------------------------------------
# DNS: cross-project A record from config.toml
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# LB: NEGs, backend services, URL map (path-routed), HTTPS proxy, cert, IAP
# -----------------------------------------------------------------------------
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
  #    /login*, /config, /styles.css, /health → opencode-login-backend
  #    everything else (default) → opencode-web-backend (IAP-protected)
  #
  # Note: /__/auth/* path was used by the old email-link handler.html (PR #62)
  # but is no longer needed since the Google sign-in popup flow (PR #68) uses
  # the firebaseapp.com handler directly.
  if ! gcloud compute url-maps describe opencode-url-map \
        --global --project="$PROJECT_ID" &>/dev/null; then
    log_info "Creating URL map: opencode-url-map"
    gcloud compute url-maps create opencode-url-map \
      --default-service=opencode-web-backend \
      --global --project="$PROJECT_ID" --quiet

    log_info "Adding path matcher (login + assets → opencode-login-backend)"
    gcloud compute url-maps add-path-matcher opencode-url-map \
      --path-matcher-name=login-paths \
      --default-service=opencode-web-backend \
      --new-hosts="$CERT_DOMAIN" \
      --backend-service-path-rules="/login=opencode-login-backend,/login/*=opencode-login-backend,/config=opencode-login-backend,/styles.css=opencode-login-backend,/health=opencode-login-backend" \
      --global --project="$PROJECT_ID" --quiet
  else
    log_info "URL map opencode-url-map already exists; checking path rules drift..."

    # Existing path rules may be stale (e.g., still pointing /__/auth/* somewhere
    # or missing /config, /styles.css, /health). Refresh idempotently.
    EXISTING_RULES=$(gcloud compute url-maps describe opencode-url-map \
      --global --project="$PROJECT_ID" \
      --format='value(pathMatchers[0].pathRules[].paths.list())' 2>/dev/null)
    EXISTING_SORTED=$(echo "$EXISTING_RULES" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//' | sed 's/^,//')
    EXPECTED_SORTED="/config,/health,/login,/login/*,/styles.css"
    if [[ "$EXISTING_SORTED" != "$EXPECTED_SORTED" ]]; then
      log_warn "URL map path rules drift detected; refreshing..."
      log_warn "  Existing: $EXISTING_SORTED"
      log_warn "  Expected: $EXPECTED_SORTED"
      gcloud compute url-maps remove-path-matcher opencode-url-map \
        --path-matcher-name=login-paths \
        --global --project="$PROJECT_ID" --quiet 2>/dev/null || true
      gcloud compute url-maps add-path-matcher opencode-url-map \
        --path-matcher-name=login-paths \
        --default-service=opencode-web-backend \
        --new-hosts="$CERT_DOMAIN" \
        --backend-service-path-rules="/login=opencode-login-backend,/login/*=opencode-login-backend,/config=opencode-login-backend,/styles.css=opencode-login-backend,/health=opencode-login-backend" \
        --global --project="$PROJECT_ID" --quiet
      log_success "URL map path rules refreshed"
    else
      log_info "URL map path rules are up to date"
    fi
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
  log_info "Next: 'make cloud-setup-auth' to configure GCIP Google IdP +"
  log_info "authorizedDomains + IAP gcipSettings. (Or just run 'make cloud-setup'"
  log_info "which chains all four sub-targets.)"
}

# -----------------------------------------------------------------------------
# Auth: GCIP Google IdP + authorizedDomains merge + IAP gcipSettings YAML
# -----------------------------------------------------------------------------
# Single function that automates everything previously manual after PR #68:
#   - POST/PATCH defaultSupportedIdpConfigs/google.com (Google IdP enable)
#   - PATCH config?updateMask=authorizedDomains (preserving Firebase defaults)
#   - gcloud beta iap settings set with agent-flow gcipSettings YAML
#
# Inputs:
#   - config.toml [default.auth.google].client_id  (public, committed)
#   - $GOOGLE_OAUTH_CLIENT_SECRET from .env       (sensitive, gitignored)
#   - config.toml [default.dns]                   (for FQDN + loginPageUri)
# -----------------------------------------------------------------------------
cmd_setup_auth() {
  log_header "Configuring GCIP Google IdP + authorizedDomains + IAP gcipSettings"

  _load_env

  local client_id client_secret deployment_fqdn
  client_id=$(_oauth_client_id)
  client_secret=$(_oauth_client_secret)
  deployment_fqdn=$(_deployment_fqdn) || {
    log_error "Could not determine deployment FQDN from config.toml [default.dns]."
    log_error "Ensure subdomain and base_domain are set."
    return 1
  }

  if [[ -z "$client_id" || "$client_id" == "<GOOGLE_OAUTH_CLIENT_ID>" ]]; then
    log_error "config.toml [default.auth.google].client_id is unset/placeholder."
    log_error "See gcip-google-signin-setup.md Phase 1 for setup."
    return 1
  fi
  if [[ -z "$client_secret" ]]; then
    log_error "GOOGLE_OAUTH_CLIENT_SECRET not set in environment."
    log_error "Copy .env.example to .env and fill in the secret."
    log_error "See gcip-google-signin-setup.md Phase 0."
    return 1
  fi

  local access_token
  access_token=$(gcloud auth print-access-token 2>/dev/null)

  # === 1. Configure Google IdP (POST first; if 409/400, PATCH) ===
  log_info "Configuring Google IdP in GCIP..."
  local http_code
  http_code=$(curl -s -o /tmp/gcip_idp_resp.json -w "%{http_code}" \
    -X POST -H "Authorization: Bearer $access_token" \
    -H "x-goog-user-project: $PROJECT_ID" \
    -H "Content-Type: application/json" \
    "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT_ID/defaultSupportedIdpConfigs?idpId=google.com" \
    -d "{\"enabled\":true,\"clientId\":\"$client_id\",\"clientSecret\":\"$client_secret\"}")

  if [[ "$http_code" =~ ^(409|400)$ ]]; then
    log_info "  Already exists; PATCHing..."
    curl -sX PATCH -H "Authorization: Bearer $access_token" \
      -H "x-goog-user-project: $PROJECT_ID" \
      -H "Content-Type: application/json" \
      "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT_ID/defaultSupportedIdpConfigs/google.com?updateMask=enabled,clientId,clientSecret" \
      -d "{\"enabled\":true,\"clientId\":\"$client_id\",\"clientSecret\":\"$client_secret\"}" \
      > /dev/null
  fi
  log_success "Google IdP configured"

  # === 2. authorizedDomains merge ===
  log_info "Syncing authorizedDomains (preserving defaults + adding $deployment_fqdn)..."
  local current_domains merged
  current_domains=$(curl -sH "Authorization: Bearer $access_token" \
    -H "x-goog-user-project: $PROJECT_ID" \
    "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT_ID/config" \
    | bun -e "
      const data = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
      console.log(JSON.stringify(data.authorizedDomains || []));
    ")
  merged=$(echo "$current_domains" | bun -e "
    const cur = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
    const required = ['localhost', '${PROJECT_ID}.firebaseapp.com', '${PROJECT_ID}.web.app', '$deployment_fqdn'];
    const merged = [...new Set([...cur, ...required])];
    console.log(JSON.stringify(merged));
  ")
  curl -sX PATCH -H "Authorization: Bearer $access_token" \
    -H "x-goog-user-project: $PROJECT_ID" \
    -H "Content-Type: application/json" \
    "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT_ID/config?updateMask=authorizedDomains" \
    -d "{\"authorizedDomains\":$merged}" > /dev/null
  log_success "authorizedDomains synced: $merged"

  # === 3. IAP gcipSettings (agent-flow YAML) ===
  log_info "Applying IAP gcipSettings (agent flow)..."
  local project_number login_url tmp_yaml
  project_number=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
  # Fetch current Firebase API key for loginPageUri query string
  local response api_key
  response=$(curl -sH "Authorization: Bearer $access_token" \
    -H "x-goog-user-project: $PROJECT_ID" \
    "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT_ID/config" || echo '{}')
  api_key=$(echo "$response" | bun -e "
    const r = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
    console.log(r.client?.apiKey || '');
  ")
  if [[ -z "$api_key" ]]; then
    log_warn "Could not fetch Firebase apiKey. IAP gcipSettings YAML cannot include the apiKey query parameter."
    log_warn "loginPageUri will be incomplete; IAP may reject."
    return 1
  fi
  login_url="https://${deployment_fqdn}/login?apiKey=${api_key}"
  tmp_yaml=$(mktemp)
  cat > "$tmp_yaml" <<EOF
accessSettings:
  gcipSettings:
    tenantIds:
    - _${project_number}
    loginPageUri: ${login_url}
EOF
  gcloud beta iap settings set "$tmp_yaml" \
    --project="$PROJECT_ID" \
    --resource-type=backend-services \
    --service=opencode-web-backend > /dev/null
  rm -f "$tmp_yaml"
  log_success "IAP gcipSettings applied (tenantIds: [_${project_number}])"

  echo ""
  log_success "Auth setup complete"
}

# -----------------------------------------------------------------------------
# Sync IAP allowed_users from config.toml
# -----------------------------------------------------------------------------
cmd_sync_users() {
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

# -----------------------------------------------------------------------------
# Teardown: LB resources + Cloud Run services (single confirmation)
# -----------------------------------------------------------------------------
cmd_teardown() {
  log_header "Tearing down ALL infrastructure (DESTRUCTIVE)"
  log_warn "This will REMOVE the LB AND all Cloud Run services."
  log_warn "Cloud DNS records and the Artifact Registry repo are NOT touched."
  read -r -p "Are you sure? Type 'yes' to confirm: " confirm
  if [[ "$confirm" != "yes" ]]; then
    log_info "Cancelled"
    return 0
  fi

  # 1. LB resources (delete in reverse dependency order; ignore errors)
  log_info "Removing LB resources..."
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
    eval "$cmd 2>/dev/null || true"
  done
  log_success "LB resources removed"

  # 2. Cloud Run services
  log_info "Removing Cloud Run services..."
  for service in opencode-web opencode-login payment-agent store-agent midnight-agent sonic-agent midnight-mcp evm-mcp somnia-agent agent-registry midnight-indexer midnight-proof-server midnight-node; do
    gcloud run services delete "$service" --region="$REGION" --project="$PROJECT_ID" --quiet 2>/dev/null || true
  done
  log_success "Cloud Run services removed"

  echo ""
  log_success "Full teardown complete"
}

# -----------------------------------------------------------------------------
# Dispatcher
# -----------------------------------------------------------------------------
case "${1:-}" in
  setup)
    cmd_setup
    ;;
  setup-project)
    cmd_setup_project
    ;;
  setup-dns)
    cmd_setup_dns
    ;;
  setup-lb)
    cmd_setup_lb
    ;;
  setup-auth)
    cmd_setup_auth
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
  sync-users)
    cmd_sync_users
    ;;
  teardown)
    cmd_teardown
    ;;
  *)
    show_usage "cloud.sh" "
  setup            One-time meta bootstrap (project + dns + lb + auth)
  deploy           Build and deploy to Cloud Run (auto Firebase substitutions)
  status           Show Cloud Run service status
  urls             Show service URLs
  logs [svc]       View logs (default: opencode-web)
  sync-users       Sync IAP allowed_users from config.toml
  teardown         DESTRUCTIVE: tear down LB + Cloud Run services

Advanced sub-targets (called by 'setup'; useful for recovery):
  setup-project    APIs + project IAM only
  setup-dns        Cross-project DNS A record only
  setup-lb         LB resources + URL map + IAP enable
  setup-auth       GCIP Google IdP + authorizedDomains + IAP gcipSettings

Environment variables:
  GCP_PROJECT  GCP project ID (default: kunal-scratch)
  GCP_REGION   GCP region (default: us-central1)"
    exit 1
    ;;
esac
