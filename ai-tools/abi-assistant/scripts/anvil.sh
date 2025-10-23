#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/common.sh"

# Default values
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
COMMAND="${1:-help}"
shift || true

# Anvil container settings
ANVIL_IMAGE="abi-assistant-anvil:latest"
ANVIL_CONTAINER="abi-assistant-anvil"
ANVIL_PORT="${ANVIL_PORT:-8545}"

# Help message
show_help() {
    cat << EOF
Anvil Local Blockchain Management

Usage: $0 <command> [options]

Commands:
    start                Start Anvil with test configuration
    fork [url]          Start Anvil with mainnet fork
    stop                Stop Anvil container
    logs                View Anvil logs
    status              Check if Anvil is running
    help                Show this help message

Environment Variables:
    CONTAINER_RUNTIME    Container runtime to use (default: podman)
    ANVIL_PORT          Port to expose (default: 8545)
    FORK_URL            URL for mainnet fork (default: public RPC)

Examples:
    $0 start            # Start local test blockchain
    $0 fork             # Fork mainnet with default RPC
    $0 fork https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
    $0 stop             # Stop Anvil
EOF
}

# Build Anvil image if needed
ensure_image() {
    if ! $CONTAINER_RUNTIME image exists "$ANVIL_IMAGE"; then
        log_info "Building Anvil container..."
        $CONTAINER_RUNTIME build -f "$PROJECT_ROOT/oci/Dockerfile.anvil" -t "$ANVIL_IMAGE" "$PROJECT_ROOT"
    fi
}

# Start Anvil with test configuration
start() {
    log_info "Starting Anvil local blockchain..."
    
    # Stop existing container if running
    stop_quiet
    
    # Ensure image exists
    ensure_image
    
    # Start Anvil
    $CONTAINER_RUNTIME run -d \
        --name "$ANVIL_CONTAINER" \
        -p "$ANVIL_PORT:8545" \
        "$ANVIL_IMAGE" \
        --host 0.0.0.0 \
        --accounts 10 \
        --balance 10000 \
        --mnemonic "test test test test test test test test test test test junk"
    
    log_success "Anvil started on port $ANVIL_PORT"
    log_info "View logs: $CONTAINER_RUNTIME logs -f $ANVIL_CONTAINER"
    
    # Show test accounts
    echo ""
    log_info "Test accounts (10000 ETH each):"
    echo "Account 0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    echo "Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    echo ""
    echo "See all accounts: $CONTAINER_RUNTIME logs $ANVIL_CONTAINER | head -50"
}

# Start Anvil with mainnet fork
fork() {
    local fork_url="${1:-https://reth-ethereum.ithaca.xyz/rpc}"
    
    log_info "Starting Anvil with mainnet fork..."
    
    if [[ "$fork_url" == "https://reth-ethereum.ithaca.xyz/rpc" ]]; then
        log_warning "Using default public RPC. For better performance, use your own RPC:"
        echo "  $0 fork https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
        echo ""
    fi
    
    # Stop existing container if running
    stop_quiet
    
    # Ensure image exists
    ensure_image
    
    # Start Anvil with fork
    $CONTAINER_RUNTIME run -d \
        --name "$ANVIL_CONTAINER" \
        -p "$ANVIL_PORT:8545" \
        "$ANVIL_IMAGE" \
        --host 0.0.0.0 \
        --fork-url "$fork_url" \
        --accounts 10 \
        --balance 10000 \
        --mnemonic "test test test test test test test test test test test junk"
    
    log_success "Anvil started with mainnet fork on port $ANVIL_PORT"
    log_info "Fork URL: $fork_url"
    log_info "View logs: $CONTAINER_RUNTIME logs -f $ANVIL_CONTAINER"
}

# Stop Anvil quietly (for internal use)
stop_quiet() {
    $CONTAINER_RUNTIME stop "$ANVIL_CONTAINER" 2>/dev/null || true
    $CONTAINER_RUNTIME rm "$ANVIL_CONTAINER" 2>/dev/null || true
}

# Stop Anvil
stop() {
    log_info "Stopping Anvil..."
    
    if $CONTAINER_RUNTIME ps --format "{{.Names}}" | grep -q "^${ANVIL_CONTAINER}$"; then
        $CONTAINER_RUNTIME stop "$ANVIL_CONTAINER"
        $CONTAINER_RUNTIME rm "$ANVIL_CONTAINER"
        log_success "Anvil stopped"
    else
        log_info "Anvil is not running"
    fi
}

# View Anvil logs
logs() {
    if $CONTAINER_RUNTIME ps --format "{{.Names}}" | grep -q "^${ANVIL_CONTAINER}$"; then
        $CONTAINER_RUNTIME logs -f "$ANVIL_CONTAINER"
    else
        log_error "Anvil is not running"
        exit 1
    fi
}

# Check Anvil status
status() {
    if $CONTAINER_RUNTIME ps --format "{{.Names}}" | grep -q "^${ANVIL_CONTAINER}$"; then
        log_success "Anvil is running on port $ANVIL_PORT"
        
        # Try to get block number
        if command -v cast &> /dev/null; then
            local block_num=$(cast block-number --rpc-url "http://localhost:$ANVIL_PORT" 2>/dev/null || echo "unknown")
            log_info "Current block: $block_num"
        fi
    else
        log_info "Anvil is not running"
    fi
}

# Main command dispatcher
case "$COMMAND" in
    start)
        start
        ;;
    fork)
        fork "$@"
        ;;
    stop)
        stop
        ;;
    logs)
        logs
        ;;
    status)
        status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac