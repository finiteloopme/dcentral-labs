#!/bin/bash
#
# Helm operations for Midnight K8s services
#
# Usage:
#   ./scripts/helm.sh upgrade     # Upgrade/install services
#   ./scripts/helm.sh status      # Show release status
#   ./scripts/helm.sh rollback    # Rollback to previous release
#   ./scripts/helm.sh history     # Show release history
#   ./scripts/helm.sh template    # Render templates locally
#   ./scripts/helm.sh uninstall   # Uninstall release
#

set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Get project directory and load environment
PROJECT_DIR="$(get_project_dir)"
load_env

# ==============================================================================
# Configuration
# ==============================================================================

RELEASE_NAME="${RELEASE_NAME:-midnight-services}"
NAMESPACE="${NAMESPACE:-midnight-services}"
CHART_PATH="${PROJECT_DIR}/terraform/charts/midnight-services"
CHAIN_ENVIRONMENT="${CHAIN_ENVIRONMENT:-standalone}"

# Image overrides (optional)
MIDNIGHT_NODE_IMAGE="${MIDNIGHT_NODE_IMAGE:-}"
PROOF_SERVER_IMAGE="${PROOF_SERVER_IMAGE:-}"
INDEXER_IMAGE="${INDEXER_IMAGE:-}"
INDEXER_SECRET="${INDEXER_SECRET:-}"

# ==============================================================================
# Helpers
# ==============================================================================

get_values_files() {
    local values_args="-f ${CHART_PATH}/values.yaml"
    
    local env_values="${CHART_PATH}/values-${CHAIN_ENVIRONMENT}.yaml"
    if [[ -f "$env_values" ]]; then
        values_args="$values_args -f $env_values"
    else
        log_error "Values file not found: $env_values"
        exit 1
    fi
    
    echo "$values_args"
}

get_set_args() {
    local set_args=""
    
    [[ -n "$MIDNIGHT_NODE_IMAGE" ]] && set_args="$set_args --set node.image=$MIDNIGHT_NODE_IMAGE"
    [[ -n "$PROOF_SERVER_IMAGE" ]] && set_args="$set_args --set proofServer.image=$PROOF_SERVER_IMAGE"
    [[ -n "$INDEXER_IMAGE" ]] && set_args="$set_args --set indexer.image=$INDEXER_IMAGE"
    [[ -n "$INDEXER_SECRET" ]] && set_args="$set_args --set indexer.secret=$INDEXER_SECRET"
    
    echo "$set_args"
}

# ==============================================================================
# Commands
# ==============================================================================

cmd_upgrade() {
    require_helm
    
    log_info "Upgrading Midnight services..."
    echo ""
    echo "  Release:     $RELEASE_NAME"
    echo "  Namespace:   $NAMESPACE"
    echo "  Environment: $CHAIN_ENVIRONMENT"
    echo ""
    
    local values_args=$(get_values_files)
    local set_args=$(get_set_args)
    
    # shellcheck disable=SC2086
    helm upgrade "$RELEASE_NAME" "$CHART_PATH" \
        --install \
        --namespace "$NAMESPACE" \
        --create-namespace \
        $values_args \
        $set_args \
        "$@"
    
    log_success "Upgrade complete"
}

cmd_status() {
    require_helm
    helm status "$RELEASE_NAME" --namespace "$NAMESPACE"
}

cmd_rollback() {
    require_helm
    local revision="${1:-}"
    
    if [[ -z "$revision" ]]; then
        log_info "Rolling back to previous release..."
        helm rollback "$RELEASE_NAME" --namespace "$NAMESPACE"
    else
        log_info "Rolling back to revision $revision..."
        helm rollback "$RELEASE_NAME" "$revision" --namespace "$NAMESPACE"
    fi
    
    log_success "Rollback complete"
}

cmd_history() {
    require_helm
    helm history "$RELEASE_NAME" --namespace "$NAMESPACE"
}

cmd_template() {
    require_helm
    
    local values_args=$(get_values_files)
    local set_args=$(get_set_args)
    
    # shellcheck disable=SC2086
    helm template "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        $values_args \
        $set_args \
        "$@"
}

cmd_uninstall() {
    require_helm
    
    log_warning "This will uninstall $RELEASE_NAME from $NAMESPACE!"
    echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
    sleep 5
    
    helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE"
    log_success "Uninstall complete"
}

cmd_pods() {
    require_kubectl
    kubectl get pods -n "$NAMESPACE" "$@"
}

cmd_logs() {
    require_kubectl
    local service="${1:-}"
    
    if [[ -z "$service" ]]; then
        log_error "Usage: $0 logs <service> [kubectl logs options]"
        echo "  Services: node, proof-server, indexer"
        exit 1
    fi
    
    shift
    kubectl logs -n "$NAMESPACE" -l "app=$service" "$@"
}

cmd_help() {
    cat <<EOF
Midnight Helm Operations Script

Usage: $(basename "$0") <command> [options]

Commands:
    upgrade              Upgrade/install Midnight services
    status               Show Helm release status
    rollback [revision]  Rollback to previous (or specific) revision
    history              Show release history
    template             Render templates locally (dry-run)
    uninstall            Uninstall the release
    pods                 List pods in namespace
    logs <service>       Show logs for a service (node, proof-server, indexer)

Configuration:
    Set in .env or as environment variables:
    
    CHAIN_ENVIRONMENT   standalone, testnet, mainnet (default: standalone)
    RELEASE_NAME        Helm release name (default: midnight-services)
    NAMESPACE           Kubernetes namespace (default: midnight-services)
    
    Image overrides (optional):
    MIDNIGHT_NODE_IMAGE    Override node image
    PROOF_SERVER_IMAGE     Override proof server image
    INDEXER_IMAGE          Override indexer image
    INDEXER_SECRET         32-byte hex secret for indexer

Examples:
    $(basename "$0") upgrade                      # Install/upgrade
    $(basename "$0") upgrade --dry-run            # Preview upgrade
    $(basename "$0") status                       # Check status
    $(basename "$0") rollback                     # Rollback to previous
    $(basename "$0") rollback 2                   # Rollback to revision 2
    $(basename "$0") logs node -f                 # Follow node logs
    $(basename "$0") pods -w                      # Watch pods
    
    CHAIN_ENVIRONMENT=testnet $(basename "$0") upgrade
EOF
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local command="${1:-help}"
    shift 2>/dev/null || true
    
    case "$command" in
        upgrade)   cmd_upgrade "$@" ;;
        status)    cmd_status ;;
        rollback)  cmd_rollback "$@" ;;
        history)   cmd_history ;;
        template)  cmd_template "$@" ;;
        uninstall) cmd_uninstall ;;
        pods)      cmd_pods "$@" ;;
        logs)      cmd_logs "$@" ;;
        help|-h|--help) cmd_help ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
