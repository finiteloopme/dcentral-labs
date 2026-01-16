# TOML Configuration Reference

This document describes the `chain.config.toml` configuration file format used by genai-chain-dev.

## Overview

Each chain implementation includes a `chain.config.toml` file that defines:

- Chain identity and type
- CLI naming
- Network configurations
- Container image settings
- GCP deployment settings
- Feature flags

## Complete Example

```toml
# Chain identity
[chain]
name = "Somnia"
type = "evm"
id = "somnia"

# CLI configuration
[cli]
name = "somniactl"
description = "Somnia development CLI"
version = "1.0.0"

# Network configurations
[networks.testnet]
name = "Somnia Testnet"
chain_id = 50311
rpc_url = "https://dream-rpc.somnia.network"
ws_url = "wss://dream-ws.somnia.network"
explorer_url = "https://somnia-testnet.socialscan.io"
explorer_api_url = "https://api.somnia-testnet.socialscan.io"
faucet_url = "https://faucet.somnia.network"
native_currency = "STT"
native_decimals = 18
is_default = true

[networks.local]
name = "Local (Anvil)"
chain_id = 31337
rpc_url = "http://localhost:8545"
native_currency = "ETH"
native_decimals = 18
is_default = false

# Container image configuration
[image]
name = "somnia-dev"
base = "evm"
registry = "us-central1-docker.pkg.dev"

# GCP configuration
[gcp]
project_id_suffix = "somnia-dev"
region = "us-central1"
artifact_registry = "dev-images"

# Workstation configuration
[workstation]
machine_type = "e2-standard-4"
boot_disk_size_gb = 50
home_disk_size_gb = 100
idle_timeout = "43200s"
running_timeout = "86400s"

# Feature flags
[features]
anvil = true
foundry = true
opencode = true
wallet_plaintext = true
hardhat = false
```

## Section Reference

### [chain]

Core chain identity.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Human-readable chain name (e.g., "Somnia") |
| `type` | string | Yes | Chain type: "evm", "midnight", etc. |
| `id` | string | Yes | Lowercase identifier (e.g., "somnia") |

Example:

```toml
[chain]
name = "Somnia"
type = "evm"
id = "somnia"
```

### [cli]

CLI tool configuration.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | CLI binary name (e.g., "somniactl") |
| `description` | string | No | CLI description for help text |
| `version` | string | No | CLI version (default: "1.0.0") |

Example:

```toml
[cli]
name = "somniactl"
description = "Somnia development CLI"
version = "1.0.0"
```

### [networks.<name>]

Network configurations. Multiple networks can be defined.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Human-readable network name |
| `chain_id` | integer | Yes | Blockchain chain ID |
| `rpc_url` | string | Yes | JSON-RPC endpoint URL |
| `ws_url` | string | No | WebSocket endpoint URL |
| `explorer_url` | string | No | Block explorer URL |
| `explorer_api_url` | string | No | Explorer API URL (for verification) |
| `faucet_url` | string | No | Testnet faucet URL |
| `native_currency` | string | Yes | Native token symbol |
| `native_decimals` | integer | Yes | Native token decimals (usually 18) |
| `is_default` | boolean | No | Set as default network (default: false) |

Example:

```toml
[networks.testnet]
name = "Somnia Testnet"
chain_id = 50311
rpc_url = "https://dream-rpc.somnia.network"
explorer_url = "https://somnia-testnet.socialscan.io"
faucet_url = "https://faucet.somnia.network"
native_currency = "STT"
native_decimals = 18
is_default = true

[networks.mainnet]
name = "Somnia Mainnet"
chain_id = 50312
rpc_url = "https://rpc.somnia.network"
explorer_url = "https://explorer.somnia.network"
native_currency = "SOMNIA"
native_decimals = 18

[networks.local]
name = "Local (Anvil)"
chain_id = 31337
rpc_url = "http://localhost:8545"
native_currency = "ETH"
native_decimals = 18
```

### [image]

Container image configuration.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Image name (e.g., "somnia-dev") |
| `base` | string | Yes | Base chain type ("evm") |
| `registry` | string | No | Container registry (default: "us-central1-docker.pkg.dev") |

Example:

```toml
[image]
name = "somnia-dev"
base = "evm"
registry = "us-central1-docker.pkg.dev"
```

### [gcp]

Google Cloud Platform configuration.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project_id_suffix` | string | No | Suggested project ID suffix |
| `region` | string | No | Default GCP region (default: "us-central1") |
| `artifact_registry` | string | No | Artifact Registry repository name |

Example:

```toml
[gcp]
project_id_suffix = "somnia-dev"
region = "us-central1"
artifact_registry = "dev-images"
```

### [workstation]

Cloud Workstation configuration.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `machine_type` | string | No | GCE machine type (default: "e2-standard-4") |
| `boot_disk_size_gb` | integer | No | Boot disk size in GB (default: 50) |
| `home_disk_size_gb` | integer | No | Persistent home disk in GB (default: 100) |
| `idle_timeout` | string | No | Idle timeout (default: "43200s" = 12 hours) |
| `running_timeout` | string | No | Max running time (default: "86400s" = 24 hours) |
| `gpu_type` | string | No | GPU type if needed (e.g., "nvidia-tesla-t4") |
| `gpu_count` | integer | No | Number of GPUs (default: 0) |

Example:

```toml
[workstation]
machine_type = "e2-standard-4"
boot_disk_size_gb = 50
home_disk_size_gb = 100
idle_timeout = "43200s"
running_timeout = "86400s"

# With GPU:
# machine_type = "n1-standard-4"
# gpu_type = "nvidia-tesla-t4"
# gpu_count = 1
```

### [features]

Feature flags to enable/disable functionality.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `anvil` | boolean | true | Enable Anvil local node |
| `foundry` | boolean | true | Enable Foundry toolchain |
| `opencode` | boolean | true | Enable OpenCode AI assistant |
| `wallet_plaintext` | boolean | true | Use plaintext wallet storage |
| `hardhat` | boolean | false | Include Hardhat (in addition to Foundry) |

Example:

```toml
[features]
anvil = true
foundry = true
opencode = true
wallet_plaintext = true
hardhat = false
```

## Usage in Earthly

The TOML configuration is primarily documentation and can be parsed at build time:

```bash
# Parse chain name from TOML
npx ts-node core/build/parse-toml.ts chains/somnia/chain.config.toml chain.name
# Output: Somnia

# Parse CLI name
npx ts-node core/build/parse-toml.ts chains/somnia/chain.config.toml cli.name
# Output: somniactl
```

In Earthfile:

```dockerfile
# These values come from chain.config.toml
FROM evm+chain-image \
    --CLI_NAME=somniactl \
    --CHAIN_NAME=Somnia \
    --CHAIN_ID=50311 \
    # ...
```

## Environment Variables

At runtime, the CLI reads configuration from:

1. `/etc/chain/config.json` - Chain configuration (from TOML at build time)
2. `~/.config/<cli-name>/config.json` - User preferences
3. Environment variables:
   - `CHAIN_CONFIG_DIR` - Override config directory
   - `WALLET_DIR` - Override wallet storage location

## Validation

The TOML file should be validated before build:

```bash
# Check TOML syntax
npx toml-cli lint chains/somnia/chain.config.toml

# Validate required fields (future enhancement)
./scripts/validate-chain-config.sh chains/somnia/chain.config.toml
```

## Migration

When updating the configuration format:

1. Update this reference document
2. Update the TOML parser in `core/build/parse-toml.ts`
3. Update the `new-chain.sh` scaffolding script
4. Update existing chain configurations
