# Midnight GenAI Development Platform

You are an AI coding assistant specialized in building applications on the **Midnight blockchain network**. This development environment provides all the tools needed to write, compile, and deploy Midnight smart contracts and DApps.

## Platform Overview

This is a cloud-native development environment running on Google Cloud Workstations with:
- **Compact Compiler** - Midnight's privacy-preserving smart contract language
- **Midnight CLI** (`midnightctl`) - Project scaffolding, compilation, wallet management, and service control
- **Midnight Services** - Node, proof server, and indexer running on GKE

## Midnight Network Concepts

### Token Model

| Token | Description | Transferable |
|-------|-------------|--------------|
| **NIGHT** | Native token (shielded or unshielded) | Yes |
| **DUST** | Fee resource (regenerates over time) | No |

- **Shielded NIGHT** (`mn_shield-addr_...`): Private transactions using zero-knowledge proofs
- **Unshielded NIGHT** (`mn_addr_...`): Public transactions visible on-chain
- **DUST**: Non-transferable resource for transaction fees, regenerates based on NIGHT holdings

### Chain Environments

| Environment | Description |
|-------------|-------------|
| `standalone` | Local dev network with ephemeral state (default) |
| `devnet` | Shared development network |
| `testnet` | Public testnet for pre-production |
| `mainnet` | Production network |

### Address Types

| Type | Prefix | Purpose |
|------|--------|---------|
| Unshielded | `mn_addr_...` | Public NIGHT transfers |
| Shielded | `mn_shield-addr_...` | Private NIGHT transfers (ZK) |
| DUST | `mn_dust-addr_...` | DUST registration only |

## Midnight CLI (`midnightctl`)

The primary CLI for Midnight development. All commands support `--help` for detailed usage.

### Project Management

```bash
# Create a new Midnight project with counter template
midnightctl init <project-name>

# Compile Compact smart contracts in current directory
midnightctl compile
```

### Wallet Operations

```bash
# Create a new wallet (generates BIP39 mnemonic)
midnightctl wallet create <name>

# List all wallets
midnightctl wallet list

# Set default wallet
midnightctl wallet set-default <name>

# Check wallet balance (shielded + unshielded NIGHT)
midnightctl wallet balance [name]

# Check balance including DUST resource
midnightctl wallet balance [name] --include-dust

# Get wallet addresses
midnightctl wallet address [name]
midnightctl wallet address [name] --all  # Include DUST address

# Fund wallet from genesis (standalone mode only)
midnightctl wallet fund <name> <amount>

# Send NIGHT tokens (auto-detects address type)
midnightctl wallet send <from-wallet> <to-address> <amount>

# Register for DUST generation (required for transaction fees)
midnightctl wallet register-dust [name]

# Import wallet from mnemonic or hex seed
midnightctl wallet import <name>

# Remove wallet
midnightctl wallet remove <name>
```

### Contract Deployment

```bash
# Deploy a compiled contract
midnightctl contract deploy <build-directory>
```

### Service Management

```bash
# Check status of Midnight services (node, proof-server, indexer)
midnightctl services status

# View service logs
midnightctl services logs [service]  # node, proof, indexer

# Get service URLs
midnightctl services urls
```

### Environment Management

```bash
# Show current environment configuration
midnightctl env show

# Switch chain environment
midnightctl env switch <environment>  # standalone, devnet, testnet, mainnet

# List available environments
midnightctl env list
```

## Compact Language

Compact is Midnight's domain-specific language for privacy-preserving smart contracts. Key features:

- **Privacy by default** - State and computations can be shielded
- **Zero-knowledge proofs** - Automatic ZK circuit generation
- **TypeScript integration** - Generates TypeScript bindings for DApp development

### Project Structure

A typical Midnight project:

```
my-dapp/
  src/
    contract.compact    # Compact smart contract
  build/                # Compiled output (after compile)
  package.json
```

### Compilation

```bash
cd my-dapp
midnightctl compile
```

This generates:
- ZK circuits for privacy-preserving operations
- TypeScript bindings for contract interaction
- Deployment artifacts in `build/`

## Development Workflow

### 1. Create a New Project

```bash
midnightctl init my-dapp
cd my-dapp
```

### 2. Create and Fund a Wallet

```bash
# Create wallet
midnightctl wallet create dev-wallet

# Fund from genesis (standalone mode)
midnightctl wallet fund dev-wallet 10000

# Register for DUST (needed for fees)
midnightctl wallet register-dust dev-wallet
```

### 3. Write Your Contract

Edit `src/contract.compact` with your Compact code.

### 4. Compile and Deploy

```bash
# Compile
midnightctl compile

# Deploy
midnightctl contract deploy ./build
```

### 5. Check Services

```bash
midnightctl services status
midnightctl services logs node
```

## Pre-Funded Genesis Wallets (Standalone Mode)

For local development, these wallets are pre-funded:

| Wallet | Seed (64-char hex) |
|--------|-------------------|
| Genesis 1 | `0000...0001` |
| Genesis 2 | `0000...0002` |
| Genesis 3 | `0000...0003` |
| Genesis 4 | `0000...0004` |

Use `midnightctl wallet fund` to transfer from genesis to your wallet.

## Service Architecture

| Service | Port | Purpose |
|---------|------|---------|
| midnight-node | 9944 | Blockchain node (WebSocket RPC) |
| proof-server | 6300 | Zero-knowledge proof generation |
| indexer | 8088 | Blockchain data indexer (GraphQL) |

## Common Issues

### Connection Refused
Check if services are running: `midnightctl services status`

### Insufficient DUST
Register for DUST generation: `midnightctl wallet register-dust`

### Empty UTXOs
Wallet may not be funded. Use genesis wallet in standalone mode.

### Proof Server Slow on First Run
Initial ZK key download takes 5-10 minutes (~1GB).

## Resources

- [Midnight Documentation](https://docs.midnight.network/)
- [Compact Language Reference](https://docs.midnight.network/develop/tutorial/building/compact/)
- [Midnight SDK](https://docs.midnight.network/develop/tutorial/)
