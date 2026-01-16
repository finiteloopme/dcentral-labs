#!/usr/bin/env bash
# Clean build artifacts and caches
#
# Usage:
#   ./scripts/clean.sh              # Clean all
#   ./scripts/clean.sh <chain>      # Clean specific chain
#   ./scripts/clean.sh --deep       # Deep clean including node_modules

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

TARGET=""
DEEP=false
IMAGES=false
ALL=false
STOP_ONLY=false

# =============================================================================
# Parse Arguments
# =============================================================================

show_help() {
    cat << EOF
Clean build artifacts and caches

Usage:
  $(basename "$0") [target] [options]

Arguments:
  target                    Chain to clean (optional, cleans all if omitted)

Options:
  --stop-only               Only stop containers, don't clean anything
  --deep                    Deep clean (includes node_modules, terraform state)
  --images                  Also remove Docker/Podman images
  --all                     Clean everything including Earthly cache
  -h, --help                Show this help message

Examples:
  $(basename "$0")                    # Stop containers + clean build artifacts
  $(basename "$0") somnia             # Stop + clean somnia only
  $(basename "$0") somnia --stop-only # Just stop somnia container
  $(basename "$0") --deep             # Deep clean including node_modules
  $(basename "$0") --all              # Clean everything
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --deep)
            DEEP=true
            shift
            ;;
        --images)
            IMAGES=true
            shift
            ;;
        --all)
            ALL=true
            DEEP=true
            IMAGES=true
            shift
            ;;
        --stop-only)
            STOP_ONLY=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
            else
                log_error "Unexpected argument: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# =============================================================================
# Clean Functions
# =============================================================================

stop_containers() {
    local chain="$1"
    local container_name="${chain}-dev"
    
    if command -v podman &>/dev/null; then
        # Check if container exists (running or stopped)
        if podman container exists "$container_name" 2>/dev/null; then
            log_info "  Stopping container ${container_name}..."
            podman stop "$container_name" 2>/dev/null || true
            podman rm "$container_name" 2>/dev/null || true
        fi
    fi
}

clean_npm_artifacts() {
    local dir="$1"
    
    if [[ -d "$dir" ]]; then
        log_info "  Cleaning npm build artifacts in $(basename "$dir")..."
        rm -rf "${dir}/dist" "${dir}/build" "${dir}/.tsbuildinfo" 2>/dev/null || true
        
        if [[ "$DEEP" == "true" ]]; then
            log_info "  Removing node_modules in $(basename "$dir")..."
            rm -rf "${dir}/node_modules" 2>/dev/null || true
        fi
    fi
}

clean_terraform() {
    local dir="$1"
    
    if [[ -d "$dir" ]]; then
        log_info "  Cleaning Terraform artifacts in $(basename "$dir")..."
        rm -rf "${dir}/.terraform" "${dir}/.terraform.lock.hcl" 2>/dev/null || true
        
        if [[ "$DEEP" == "true" ]]; then
            log_info "  Removing Terraform state in $(basename "$dir")..."
            rm -f "${dir}/terraform.tfstate" "${dir}/terraform.tfstate.backup" 2>/dev/null || true
        fi
    fi
}

clean_chain() {
    local chain="$1"
    local chain_dir="${CHAINS_DIR}/${chain}"
    
    log_info "Cleaning ${chain}..."
    
    # Always stop containers first
    stop_containers "$chain"
    
    # If stop-only mode, we're done
    if [[ "$STOP_ONLY" == "true" ]]; then
        return
    fi
    
    # CLI artifacts
    clean_npm_artifacts "${chain_dir}/cli"
    
    # Container images
    if [[ "$IMAGES" == "true" ]]; then
        if command -v podman &>/dev/null; then
            log_info "  Removing ${chain}-dev images..."
            podman rmi "${chain}-dev:latest" 2>/dev/null || true
        fi
    fi
}

clean_core() {
    log_info "Cleaning core..."
    
    clean_npm_artifacts "${CORE_DIR}/cli"
    clean_npm_artifacts "${CORE_DIR}/build"
}

clean_earthly() {
    log_info "Cleaning Earthly cache..."
    
    if command -v earthly &> /dev/null; then
        earthly prune --all 2>/dev/null || true
    fi
}

# =============================================================================
# Run Clean
# =============================================================================

if [[ "$STOP_ONLY" == "true" ]]; then
    log_info "Stopping containers..."
else
    log_info "Cleaning build artifacts..."
fi

if [[ -n "$TARGET" ]]; then
    # Clean specific chain
    require_chain "$TARGET"
    clean_chain "$TARGET"
else
    # Clean everything
    
    # All chains (stop containers for each)
    for chain in $(list_chains); do
        clean_chain "$chain"
    done
    
    # Skip the rest if stop-only mode
    if [[ "$STOP_ONLY" != "true" ]]; then
        # Core
        clean_core
        
        # Shared terraform
        clean_terraform "${TERRAFORM_DIR}"
        
        # Chain types (evm, etc.)
        for chain_type in evm; do
            if [[ -d "${CHAINS_DIR}/${chain_type}" ]]; then
                clean_npm_artifacts "${CHAINS_DIR}/${chain_type}/cli"
            fi
        done
    fi
fi

# Earthly cache
if [[ "$ALL" == "true" && "$STOP_ONLY" != "true" ]]; then
    clean_earthly
fi

if [[ "$STOP_ONLY" == "true" ]]; then
    log_success "Containers stopped!"
else
    log_success "Clean complete!"
fi
