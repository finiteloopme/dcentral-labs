#!/usr/bin/env bash
# Scaffold a new chain implementation
#
# Usage:
#   ./scripts/new-chain.sh <chain-name> --type=<chain-type>
#
# Examples:
#   ./scripts/new-chain.sh polygon --type=evm
#   ./scripts/new-chain.sh arbitrum --type=evm --chain-id=42161

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

CHAIN_NAME=""
CHAIN_TYPE=""
CHAIN_ID=""
RPC_URL=""
EXPLORER_URL=""
FAUCET_URL=""
NATIVE_CURRENCY=""
DISPLAY_NAME=""

# =============================================================================
# Parse Arguments
# =============================================================================

show_help() {
    cat << EOF
Scaffold a new chain implementation

Usage:
  $(basename "$0") <chain-name> --type=<chain-type> [options]

Arguments:
  chain-name                Chain identifier (lowercase, e.g., polygon)

Required:
  --type=TYPE               Chain type (currently: evm)

Optional:
  --display-name=NAME       Human-readable name (default: capitalized chain-name)
  --chain-id=ID             Default chain ID
  --rpc-url=URL             Default RPC endpoint
  --explorer-url=URL        Block explorer URL
  --faucet-url=URL          Testnet faucet URL
  --native-currency=SYM     Native token symbol (e.g., MATIC, ETH)
  -h, --help                Show this help message

Available chain types:
  evm                       EVM-compatible chains (uses Foundry)

Examples:
  $(basename "$0") polygon --type=evm --chain-id=137 --native-currency=MATIC
  $(basename "$0") arbitrum --type=evm --chain-id=42161 --rpc-url=https://arb1.arbitrum.io/rpc
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --type=*)
            CHAIN_TYPE="${1#*=}"
            shift
            ;;
        --display-name=*)
            DISPLAY_NAME="${1#*=}"
            shift
            ;;
        --chain-id=*)
            CHAIN_ID="${1#*=}"
            shift
            ;;
        --rpc-url=*)
            RPC_URL="${1#*=}"
            shift
            ;;
        --explorer-url=*)
            EXPLORER_URL="${1#*=}"
            shift
            ;;
        --faucet-url=*)
            FAUCET_URL="${1#*=}"
            shift
            ;;
        --native-currency=*)
            NATIVE_CURRENCY="${1#*=}"
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$CHAIN_NAME" ]]; then
                CHAIN_NAME="$1"
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
# Validate
# =============================================================================

if [[ -z "$CHAIN_NAME" ]]; then
    log_error "Chain name required"
    show_help
    exit 1
fi

if [[ -z "$CHAIN_TYPE" ]]; then
    log_error "--type is required"
    show_help
    exit 1
fi

# Validate chain type
case "$CHAIN_TYPE" in
    evm)
        ;;
    *)
        log_error "Unknown chain type: $CHAIN_TYPE"
        log_error "Available types: evm"
        exit 1
        ;;
esac

# Check if chain already exists
CHAIN_DIR="${CHAINS_DIR}/${CHAIN_NAME}"
if [[ -d "$CHAIN_DIR" ]]; then
    log_error "Chain already exists: $CHAIN_NAME"
    log_error "Directory: $CHAIN_DIR"
    exit 1
fi

# Set defaults
DISPLAY_NAME="${DISPLAY_NAME:-$(echo "$CHAIN_NAME" | sed 's/\b\(.\)/\u\1/')}"
CLI_NAME="${CHAIN_NAME}ctl"
NATIVE_CURRENCY="${NATIVE_CURRENCY:-ETH}"
CHAIN_ID="${CHAIN_ID:-1}"

# =============================================================================
# Create Chain
# =============================================================================

log_info "Creating new chain: ${CHAIN_NAME}"
log_info "  Type: ${CHAIN_TYPE}"
log_info "  Display Name: ${DISPLAY_NAME}"
log_info "  CLI Name: ${CLI_NAME}"
log_info "  Directory: ${CHAIN_DIR}"

# Create directory
mkdir -p "${CHAIN_DIR}"

# =============================================================================
# Create Earthfile
# =============================================================================

log_info "Creating Earthfile..."

cat > "${CHAIN_DIR}/Earthfile" << EOF
VERSION 0.8

IMPORT ../${CHAIN_TYPE} AS ${CHAIN_TYPE}

# =============================================================================
# ${DISPLAY_NAME} Chain
# =============================================================================

# Development build (no push)
dev:
    FROM ${CHAIN_TYPE}+chain-image \\
        --CLI_NAME=${CLI_NAME} \\
        --CHAIN_NAME=${DISPLAY_NAME} \\
        --CHAIN_ID=${CHAIN_ID} \\
        --RPC_URL=${RPC_URL:-https://rpc.example.com} \\
        --EXPLORER_URL=${EXPLORER_URL:-https://explorer.example.com} \\
        --FAUCET_URL=${FAUCET_URL:-https://faucet.example.com} \\
        --NATIVE_CURRENCY=${NATIVE_CURRENCY} \\
        --NATIVE_DECIMALS=18
    
    # Chain-specific AI context
    COPY AGENTS.md /etc/opencode/AGENTS.md
    
    SAVE IMAGE ${CHAIN_NAME}-dev:latest

# Production build with push
all:
    ARG REGISTRY=us-central1-docker.pkg.dev
    ARG PROJECT_ID
    ARG TAG=latest
    
    FROM +dev
    SAVE IMAGE --push \${REGISTRY}/\${PROJECT_ID}/dev-images/${CHAIN_NAME}-dev:\${TAG}
EOF

# =============================================================================
# Create chain.config.toml
# =============================================================================

log_info "Creating chain.config.toml..."

cat > "${CHAIN_DIR}/chain.config.toml" << EOF
# ${DISPLAY_NAME} Chain Configuration

[chain]
name = "${DISPLAY_NAME}"
type = "${CHAIN_TYPE}"
id = "${CHAIN_NAME}"

[cli]
name = "${CLI_NAME}"
description = "${DISPLAY_NAME} development CLI"

[networks.mainnet]
name = "${DISPLAY_NAME} Mainnet"
chain_id = ${CHAIN_ID}
rpc_url = "${RPC_URL:-https://rpc.example.com}"
explorer_url = "${EXPLORER_URL:-https://explorer.example.com}"
native_currency = "${NATIVE_CURRENCY}"
native_decimals = 18
is_default = true

[networks.local]
name = "Local (Anvil)"
chain_id = 31337
rpc_url = "http://localhost:8545"
native_currency = "ETH"
native_decimals = 18
is_default = false

[image]
name = "${CHAIN_NAME}-dev"
base = "${CHAIN_TYPE}"

[features]
anvil = true
foundry = true
opencode = true
wallet_plaintext = true
EOF

# =============================================================================
# Create AGENTS.md
# =============================================================================

log_info "Creating AGENTS.md..."

cat > "${CHAIN_DIR}/AGENTS.md" << EOF
# ${DISPLAY_NAME} Development Environment - AI Context

You are an AI assistant in a **${DISPLAY_NAME} blockchain development workstation**.

## Network Information

| Property | Value |
|----------|-------|
| **Chain ID** | ${CHAIN_ID} |
| **RPC URL** | ${RPC_URL:-https://rpc.example.com} |
| **Explorer** | ${EXPLORER_URL:-https://explorer.example.com} |
| **Native Token** | ${NATIVE_CURRENCY} |

## Available Tools

### CLI (\`${CLI_NAME}\`)

\`\`\`bash
# Project initialization
${CLI_NAME} init <project-name>

# Contract development
${CLI_NAME} compile
${CLI_NAME} test
${CLI_NAME} deploy <contract>

# Wallet management
${CLI_NAME} wallet create <name>
${CLI_NAME} wallet balance [name]
${CLI_NAME} wallet send <to> <amount>

# Local development
${CLI_NAME} node start
${CLI_NAME} node stop
\`\`\`

### Foundry Toolchain

\`\`\`bash
forge build
forge test
anvil
cast send
cast call
\`\`\`

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Docs](https://docs.soliditylang.org/)
EOF

# =============================================================================
# Done
# =============================================================================

log_success "Chain scaffolded successfully!"
echo ""
log_info "Created files:"
log_info "  ${CHAIN_DIR}/Earthfile"
log_info "  ${CHAIN_DIR}/chain.config.toml"
log_info "  ${CHAIN_DIR}/AGENTS.md"
echo ""
log_info "Next steps:"
log_info "  1. Update chain.config.toml with correct network details"
log_info "  2. Update AGENTS.md with chain-specific documentation"
log_info "  3. Build locally: make build CHAIN=${CHAIN_NAME}"
log_info "  4. Run locally: make run CHAIN=${CHAIN_NAME}"
log_info "  5. Deploy: make cloud-deploy CHAIN=${CHAIN_NAME}"
echo ""
