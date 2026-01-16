# Adding a New Chain

This guide walks through adding a new blockchain to the genai-chain-dev framework.

## Prerequisites

- Earthly installed locally (or use containerized build)
- Podman for local testing
- Understanding of the target chain's architecture

## Quick Start

Use the scaffolding script:

```bash
./scripts/new-chain.sh <chain-name> --type=<chain-type> [options]
```

### Example: Add Polygon

```bash
./scripts/new-chain.sh polygon \
    --type=evm \
    --chain-id=137 \
    --rpc-url=https://polygon-rpc.com \
    --explorer-url=https://polygonscan.com \
    --native-currency=MATIC
```

This creates:

```
chains/polygon/
├── Earthfile
├── chain.config.toml
└── AGENTS.md
```

> **Note:** Infrastructure (Terraform, Cloud Build) is centralized at the root level.
> Use `make cloud-deploy CHAIN=polygon` to deploy.

## Manual Setup

### Step 1: Create Directory Structure

```bash
mkdir -p chains/mychain
```

### Step 2: Create Earthfile

```dockerfile
VERSION 0.8

IMPORT ../evm AS evm

# Development build
dev:
    FROM evm+chain-image \
        --CLI_NAME=mychainctl \
        --CHAIN_NAME=MyChain \
        --CHAIN_ID=12345 \
        --RPC_URL=https://rpc.mychain.network \
        --EXPLORER_URL=https://explorer.mychain.network \
        --FAUCET_URL=https://faucet.mychain.network \
        --NATIVE_CURRENCY=MYC \
        --NATIVE_DECIMALS=18
    
    COPY AGENTS.md /etc/opencode/AGENTS.md
    SAVE IMAGE mychain-dev:latest

# Production build with push
all:
    ARG REGISTRY=us-central1-docker.pkg.dev
    ARG PROJECT_ID
    ARG TAG=latest
    
    FROM +dev
    SAVE IMAGE --push ${REGISTRY}/${PROJECT_ID}/dev-images/mychain-dev:${TAG}
```

### Step 3: Create chain.config.toml

```toml
[chain]
name = "MyChain"
type = "evm"
id = "mychain"

[cli]
name = "mychainctl"
description = "MyChain development CLI"

[networks.mainnet]
name = "MyChain Mainnet"
chain_id = 12345
rpc_url = "https://rpc.mychain.network"
explorer_url = "https://explorer.mychain.network"
native_currency = "MYC"
native_decimals = 18
is_default = true

[networks.testnet]
name = "MyChain Testnet"
chain_id = 12346
rpc_url = "https://testnet.rpc.mychain.network"
explorer_url = "https://testnet.explorer.mychain.network"
faucet_url = "https://faucet.mychain.network"
native_currency = "tMYC"
native_decimals = 18

[networks.local]
name = "Local (Anvil)"
chain_id = 31337
rpc_url = "http://localhost:8545"
native_currency = "ETH"
native_decimals = 18

[image]
name = "mychain-dev"
base = "evm"

[gcp]
project_id_suffix = "mychain-dev"
region = "us-central1"
artifact_registry = "dev-images"

[workstation]
machine_type = "e2-standard-4"
boot_disk_size_gb = 50
home_disk_size_gb = 100

[features]
anvil = true
foundry = true
opencode = true
wallet_plaintext = true
```

### Step 4: Create AGENTS.md

Write AI context documentation for your chain:

```markdown
# MyChain Development Environment - AI Context

You are an AI assistant in a **MyChain blockchain development workstation**.

## Network Information

| Property | Value |
|----------|-------|
| **Chain ID** | 12345 |
| **RPC URL** | https://rpc.mychain.network |
| **Explorer** | https://explorer.mychain.network |
| **Native Token** | MYC |

## Available Tools

### CLI (`mychainctl`)

[Document all CLI commands...]

### Development Workflow

[Document typical workflows...]

## Chain-Specific Considerations

[Document any unique aspects of this chain...]
```

### Step 5: Infrastructure (Centralized)

Infrastructure is managed centrally at the repository root. No per-chain Terraform, Makefile, or cloudbuild.yaml is needed.

The shared infrastructure at `terraform/` uses the chain name as a variable. When you deploy, it automatically:
- Creates an Artifact Registry repository
- Sets up Cloud Workstations with your chain's image

See the root `README.md` for environment setup and the bootstrap process.

## Testing

### Build Locally

```bash
# Using local Earthly
make build CHAIN=mychain

# Or using containerized Earthly (no local install required)
make build-container CHAIN=mychain
```

### Run Locally

```bash
make run CHAIN=mychain
```

Or interactively:

```bash
make shell CHAIN=mychain
```

### Verify CLI

```bash
# Inside container
mychainctl --help
mychainctl wallet create test
mychainctl wallet list
mychainctl node start
mychainctl network list
```

## Deployment

### 1. Configure Environment

```bash
# Copy and edit .env at repository root
cp .env.example .env
# Set PROJECT_ID, STATE_BUCKET, CLOUDBUILD_SA_EMAIL
```

### 2. Deploy via Cloud Build

```bash
make cloud-deploy CHAIN=mychain
```

Or deploy locally with Terraform:

```bash
make deploy CHAIN=mychain
```

## Customization

### Adding Chain-Specific Features

If your chain needs additional tools or configuration:

1. Create custom install scripts in `scripts/install/`
2. Extend the Earthfile to include them
3. Update AGENTS.md with documentation

Example Earthfile extension:

```dockerfile
dev:
    FROM evm+chain-image \
        --CLI_NAME=mychainctl \
        # ... other args ...
    
    # Install chain-specific tools
    COPY scripts/install/mychain-tools.sh /tmp/
    RUN bash /tmp/mychain-tools.sh
    
    COPY AGENTS.md /etc/opencode/AGENTS.md
    SAVE IMAGE mychain-dev:latest
```

### Custom CLI Commands

To add chain-specific CLI commands, you would need to:

1. Create a new CLI package extending the EVM CLI
2. Add custom commands
3. Update the Earthfile to build your custom CLI

This is an advanced customization - for most EVM chains, the standard CLI is sufficient.

## Non-EVM Chains

For non-EVM chains, you'll need to:

1. Create a new chain type under `chains/<type>/`
2. Implement the `ChainAdapter` interface
3. Create appropriate tooling install scripts
4. Update AGENTS.md with chain-specific workflows

See the framework documentation for interface definitions.
