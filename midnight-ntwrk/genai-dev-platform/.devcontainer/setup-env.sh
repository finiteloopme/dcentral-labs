#!/bin/bash

set -euo pipefail

# ==============================================================================
# Midnight Development Environment Setup
#
# This script configures the development environment based on the selected mode:
# - standalone: Uses GKE-hosted services (injected via env vars)
# - testnet: Uses Midnight testnet endpoints
# - mainnet: Uses Midnight mainnet endpoints
# ==============================================================================

# Default to standalone if not set
ENV_MODE="${CHAIN_ENVIRONMENT:-standalone}"

# ==============================================================================
# Utility Functions
# ==============================================================================

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[OK] $1"
}

log_warning() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# ==============================================================================
# Health Checks
# ==============================================================================

check_service_health() {
    local name="$1"
    local url="$2"
    local health_path="${3:-/health}"
    
    if [[ -z "$url" ]]; then
        log_warning "$name URL not configured"
        return 1
    fi
    
    # Add /health if not already a full path
    local full_url="${url}${health_path}"
    
    if curl -sf --max-time 5 "$full_url" > /dev/null 2>&1; then
        log_success "$name is healthy"
        return 0
    else
        log_warning "$name health check failed: $full_url"
        return 1
    fi
}

check_all_services() {
    log_info "Checking service health..."
    echo ""
    
    local all_healthy=true
    
    check_service_health "Midnight Node" "$MIDNIGHT_NODE_URL" "/health" || all_healthy=false
    check_service_health "Proof Server" "$PROOF_SERVER_URL" "/health" || all_healthy=false
    check_service_health "Indexer" "$INDEXER_URL" "/health" || all_healthy=false
    
    echo ""
    
    if $all_healthy; then
        log_success "All services are healthy"
        return 0
    else
        log_warning "Some services are not responding"
        return 1
    fi
}

# ==============================================================================
# Environment Configuration
# ==============================================================================

configure_standalone() {
    log_info "Configuring standalone environment (GKE services)"
    
    # These are injected by the Workstation configuration from Terraform
    # If not set, try to discover them via gcloud
    if [[ -z "${MIDNIGHT_NODE_URL:-}" ]]; then
        log_info "Discovering GKE service URLs..."
        
        local cluster_name="${CLUSTER_NAME:-midnight-dev}"
        local project_id
        local region
        
        # Get project and region from metadata if available
        if project_id=$(curl -sf -H "Metadata-Flavor: Google" \
            "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null); then
            log_info "Detected GCP project: $project_id"
        else
            log_warning "Could not detect GCP project. Set MIDNIGHT_NODE_URL manually."
            return 1
        fi
        
        # Default region
        region="${GOOGLE_CLOUD_REGION:-us-central1}"
        
        # Discover service URLs
        export MIDNIGHT_NODE_URL=$(gcloud run services describe "midnight-node-${cluster_name}" \
            --project="$project_id" --region="$region" --format='value(status.url)' 2>/dev/null || echo "")
        
        export PROOF_SERVER_URL=$(gcloud run services describe "proof-server-${cluster_name}" \
            --project="$project_id" --region="$region" --format='value(status.url)' 2>/dev/null || echo "")
        
        export INDEXER_URL=$(gcloud run services describe "indexer-${cluster_name}" \
            --project="$project_id" --region="$region" --format='value(status.url)' 2>/dev/null || echo "")
    fi
    
    export MIDNIGHT_NETWORK="standalone"
}

configure_testnet() {
    log_info "Configuring testnet environment"
    
    export MIDNIGHT_NETWORK="testnet"
    export MIDNIGHT_NODE_URL="wss://testnet-node.midnight.network"
    export INDEXER_URL="https://testnet-indexer.midnight.network"
    
    # Proof server still uses Cloud Run (or local)
    if [[ -z "${PROOF_SERVER_URL:-}" ]]; then
        # Try to discover from Cloud Run
        configure_proof_server_url
    fi
}

configure_mainnet() {
    log_info "Configuring mainnet environment"
    log_warning "MAINNET MODE - Ensure you are not using test keys!"
    
    export MIDNIGHT_NETWORK="mainnet"
    export MIDNIGHT_NODE_URL="wss://mainnet-node.midnight.network"
    export INDEXER_URL="https://mainnet-indexer.midnight.network"
    
    # Proof server still uses Cloud Run (or local)
    if [[ -z "${PROOF_SERVER_URL:-}" ]]; then
        configure_proof_server_url
    fi
}

configure_proof_server_url() {
    local cluster_name="${CLUSTER_NAME:-midnight-dev}"
    local project_id
    local region="${GOOGLE_CLOUD_REGION:-us-central1}"
    
    if project_id=$(curl -sf -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null); then
        export PROOF_SERVER_URL=$(gcloud run services describe "proof-server-${cluster_name}" \
            --project="$project_id" --region="$region" --format='value(status.url)' 2>/dev/null || echo "")
    fi
}

# ==============================================================================
# Profile Setup
# ==============================================================================

write_env_to_profile() {
    local profile_file="/etc/profile.d/midnight-env.sh"
    
    cat > "$profile_file" << EOF
# Midnight Development Environment
# Generated by setup-env.sh

export MIDNIGHT_NETWORK="${MIDNIGHT_NETWORK:-standalone}"
export MIDNIGHT_NODE_URL="${MIDNIGHT_NODE_URL:-}"
export PROOF_SERVER_URL="${PROOF_SERVER_URL:-}"
export INDEXER_URL="${INDEXER_URL:-}"
export CLUSTER_NAME="${CLUSTER_NAME:-midnight-dev}"
EOF
    
    chmod 644 "$profile_file"
    log_success "Environment written to $profile_file"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    echo ""
    echo "========================================"
    echo "  Midnight Development Environment"
    echo "========================================"
    echo ""
    
    log_info "Mode: $ENV_MODE"
    echo ""

    case "$ENV_MODE" in
        standalone)
            configure_standalone
            ;;
        testnet)
            configure_testnet
            ;;
        mainnet)
            configure_mainnet
            ;;
        *)
            log_error "Unknown environment: $ENV_MODE"
            log_info "Valid options: standalone, testnet, mainnet"
            exit 1
            ;;
    esac

    # Write environment to profile for shell sessions
    write_env_to_profile
    
    # Display configuration
    echo ""
    log_info "Service URLs:"
    echo "  Node:         ${MIDNIGHT_NODE_URL:-<not configured>}"
    echo "  Proof Server: ${PROOF_SERVER_URL:-<not configured>}"
    echo "  Indexer:      ${INDEXER_URL:-<not configured>}"
    echo ""
    
    # Optional health check
    if [[ "${SKIP_HEALTH_CHECK:-}" != "true" ]]; then
        check_all_services || true
    fi
    
    log_success "Environment ready: $ENV_MODE"
    echo ""
}

# Run main only if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
