#!/bin/bash

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly STANDALONE_COMPOSE="${SCRIPT_DIR}/standalone.yml"
readonly REMOTE_COMPOSE="${SCRIPT_DIR}/remote.yml"
readonly HEALTH_CHECK_TIMEOUT=30
readonly HEALTH_CHECK_INTERVAL=2

# Default to testnet if not set
ENV_MODE="${CHAIN_ENVIRONMENT:-testnet}"

# ==============================================================================
# Utility Functions
# ==============================================================================

log_info() {
    echo "🌙 $1"
}

log_success() {
    echo "✅ $1"
}

log_warning() {
    echo "⚠️  $1"
}

log_step() {
    echo "🔗 $1"
}

log_wait() {
    echo "⏳ $1"
}

log_cleanup() {
    echo "🧹 $1"
}

log_build() {
    echo "🏗️  $1"
}

log_launch() {
    echo "🚀 $1"
}

# ==============================================================================
# Container Management
# ==============================================================================

cleanup_containers() {
    log_cleanup "Cleaning up previous containers..."
    podman-compose -f "$STANDALONE_COMPOSE" down 2>/dev/null || true
    podman-compose -f "$REMOTE_COMPOSE" down 2>/dev/null || true
}

start_compose() {
    local compose_file="$1"
    podman-compose -f "$compose_file" up -d
}

# ==============================================================================
# Health Checks
# ==============================================================================

wait_for_proof_server() {
    local url="${1:-http://localhost:6300/health}"
    
    log_wait "Waiting for Proof Server health..."
    if ! timeout "$HEALTH_CHECK_TIMEOUT" bash -c \
        "until curl -s '$url' > /dev/null; do sleep $HEALTH_CHECK_INTERVAL; done"; then
        log_warning "Proof Server health check timed out after ${HEALTH_CHECK_TIMEOUT}s"
        return 1
    fi
    return 0
}

# ==============================================================================
# Environment Exporters
# ==============================================================================

export_standalone_env() {
    export MIDNIGHT_NODE_URL="ws://localhost:9944"
    export MIDNIGHT_INDEXER_URL="http://localhost:8081"
    export MIDNIGHT_PROOF_SERVER_URL="http://localhost:6300"
}

export_testnet_env() {
    export MIDNIGHT_NETWORK_FLAG="testnet"
    export MIDNIGHT_NODE_URL="wss://testnet-node.midnight.network"
    export MIDNIGHT_INDEXER_URL="https://testnet-indexer.midnight.network"
    export MIDNIGHT_PROOF_SERVER_URL="http://localhost:6300"
}

export_mainnet_env() {
    export MIDNIGHT_NETWORK_FLAG="mainnet"
    export MIDNIGHT_NODE_URL="wss://mainnet-node.midnight.network"
    export MIDNIGHT_INDEXER_URL="https://mainnet-indexer.midnight.network"
    export MIDNIGHT_PROOF_SERVER_URL="http://localhost:6300"
}

# ==============================================================================
# Mode Handlers
# ==============================================================================

setup_standalone() {
    cleanup_containers
    log_build "Starting Standalone Stack (Node + Indexer + Proof)..."
    start_compose "$STANDALONE_COMPOSE"
    export_standalone_env
}

setup_testnet() {
    cleanup_containers
    log_launch "Starting Testnet Sidecar..."
    export_testnet_env
    start_compose "$REMOTE_COMPOSE"
}

setup_mainnet() {
    cleanup_containers
    log_warning "STARTING MAINNET SIDECAR"
    log_warning "Ensure you are not using test keys!"
    export_mainnet_env
    start_compose "$REMOTE_COMPOSE"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log_info "Initializing Midnight Workstation..."
    log_step "Chain Environment: $ENV_MODE"

    case "$ENV_MODE" in
        standalone)
            setup_standalone
            ;;
        testnet)
            setup_testnet
            ;;
        mainnet)
            setup_mainnet
            ;;
        *)
            log_warning "Unknown environment: $ENV_MODE"
            log_info "Valid options: standalone, testnet, mainnet"
            exit 1
            ;;
    esac

    wait_for_proof_server
    log_success "Environment Ready: $ENV_MODE"
}

# Run main only if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
