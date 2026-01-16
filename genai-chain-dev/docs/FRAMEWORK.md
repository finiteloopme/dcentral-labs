# genai-chain-dev Framework Architecture

This document describes the architecture and design of the genai-chain-dev framework for creating GenAI-enabled blockchain development platforms.

## Overview

genai-chain-dev is a modular framework that provides:

- **Composable Earthly builds** with inheritance for chain-specific customization
- **TOML-driven configuration** for chain networks, CLI naming, and features
- **Cloud Workstations integration** using Google's Code OSS base image
- **Pre-configured AI assistant** (OpenCode) with chain-specific context
- **Type-safe CLI** for wallet management, contract development, and local nodes

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              genai-chain-dev                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐    │
│  │      Core        │     │   Chain Types    │     │     Chains       │    │
│  │                  │     │                  │     │                  │    │
│  │  - Base image    │────▶│  - EVM           │────▶│  - Somnia        │    │
│  │  - CLI framework │     │  - (future)      │     │  - (polygon)     │    │
│  │  - Scripts       │     │                  │     │  - (arbitrum)    │    │
│  │  - TF modules    │     │  Foundry, viem   │     │                  │    │
│  └──────────────────┘     └──────────────────┘     └──────────────────┘    │
│           │                        │                        │               │
│           ▼                        ▼                        ▼               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                         Earthly Build System                          │  │
│  │                                                                        │  │
│  │   core/Earthfile ──▶ chains/evm/Earthfile ──▶ chains/somnia/Earthfile │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│                                    ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                         Container Image                               │  │
│  │                                                                        │  │
│  │   Google Code OSS + Foundry + CLI + OpenCode + Chain Config           │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│                                    ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                      Cloud Workstations                               │  │
│  │                                                                        │  │
│  │   Developer accesses via browser, pre-configured environment          │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
genai-chain-dev/
├── Earthfile                    # Root build orchestration
├── README.md                    # Project documentation
├── SESSION.md                   # Development session tracking
│
├── core/                        # Shared framework components
│   ├── Earthfile               # Base image targets
│   ├── cli/                    # CLI framework (TypeScript)
│   │   ├── src/
│   │   │   ├── interfaces/     # Chain, Wallet, Contract interfaces
│   │   │   ├── commands/       # Base command classes
│   │   │   └── utils/          # Logger, config, exec utilities
│   │   └── package.json
│   ├── scripts/
│   │   ├── install/            # Tool installation scripts
│   │   ├── configure/          # Configuration scripts
│   │   └── profile.d/          # Shell profile scripts
│   ├── build/                  # Build-time utilities
│   │   └── parse-toml.ts       # TOML parser for Earthly
│   └── terraform/
│       └── modules/            # Reusable Terraform modules
│           ├── workstations/   # Cloud Workstations
│           └── artifact-registry/
│
├── chains/
│   ├── evm/                    # EVM chain type
│   │   ├── Earthfile          # Foundry + CLI targets
│   │   ├── cli/               # EVM-specific CLI
│   │   │   └── src/
│   │   │       ├── lib/       # wallet-store, provider, anvil
│   │   │       └── commands/  # wallet, node, contract, init
│   │   ├── scripts/           # Foundry installation
│   │   └── templates/         # Project scaffolding
│   │
│   └── somnia/                 # Somnia chain implementation
│       ├── Earthfile          # Imports from evm, adds config
│       ├── chain.config.toml  # Chain configuration
│       └── AGENTS.md          # AI context document
│
├── scripts/                    # Build/deploy scripts
│   ├── common.sh              # Shared utilities
│   ├── build.sh               # Build images
│   ├── earthly-container.sh   # Run Earthly via Podman (no local install)
│   ├── run-local.sh           # Run locally
│   ├── deploy.sh              # Deploy infrastructure
│   ├── test.sh                # Run tests
│   ├── clean.sh               # Cleanup
│   └── new-chain.sh           # Scaffold new chain
│
└── docs/                       # Documentation
    ├── FRAMEWORK.md           # This file
    ├── ADDING-CHAIN.md        # Guide to add new chains
    └── TOML-REFERENCE.md      # Configuration reference
```

## Build System

### Local Build Options

There are two ways to build locally:

1. **With local Earthly installed:**
   ```bash
   make build CHAIN=somnia
   ```

2. **Without local Earthly (containerized):**
   ```bash
   make build-container CHAIN=somnia
   ```

The containerized option runs Earthly v0.8.15 inside a Podman container, eliminating the need for local Earthly installation. It uses `--privileged` mode for BuildKit and persists cache to `~/.earthly`.

### Earthly Inheritance

The build system uses Earthly's import/inheritance model:

```
core/Earthfile (workstation-base, opencode, dev-base)
       │
       ▼
chains/evm/Earthfile (foundry, cli-build, evm-base, chain-image)
       │
       ▼
chains/somnia/Earthfile (dev, all)
```

Each layer adds capabilities:

1. **Core**: Base image, OpenCode installation, common tools
2. **Chain Type (EVM)**: Foundry toolchain, EVM CLI with wallet/contract commands
3. **Chain**: Network configuration, AI context, welcome message

### Key Earthly Targets

| Target | Location | Purpose |
|--------|----------|---------|
| `workstation-base` | core | Google Code OSS base image |
| `opencode` | core | OpenCode AI assistant |
| `dev-base` | core | Base with common dev tools |
| `foundry` | evm | Foundry toolchain (forge, cast, anvil) |
| `cli-build` | evm | Build EVM CLI TypeScript |
| `evm-base` | evm | Foundry + CLI installed |
| `chain-image` | evm | Parameterized chain image |
| `dev` | chain | Local development image |
| `all` | chain | Production image with push |

### Build Arguments

Chain images are configured via build arguments:

```bash
earthly +chain-image \
    --CLI_NAME=somniactl \
    --CHAIN_NAME=Somnia \
    --CHAIN_ID=50311 \
    --RPC_URL=https://dream-rpc.somnia.network \
    --EXPLORER_URL=https://somnia-testnet.socialscan.io \
    --FAUCET_URL=https://faucet.somnia.network \
    --NATIVE_CURRENCY=STT \
    --NATIVE_DECIMALS=18
```

## CLI Architecture

### Interface Hierarchy

```typescript
// Core interfaces (chain-agnostic)
interface ChainAdapter {
  readonly id: string;
  readonly displayName: string;
  wallet: WalletAdapter;
  contract: ContractAdapter;
  node?: NodeAdapter;
  networks: NetworkConfig[];
}

// EVM implementation
class EVMChainAdapter implements ChainAdapter {
  // Uses viem for wallet operations
  // Wraps Foundry for contract operations
  // Uses Anvil for local node
}
```

### Command Structure

```
{cli-name}
├── init <name>              # Scaffold project
├── compile                  # Build contracts
├── test                     # Run tests
├── deploy <contract>        # Deploy contract
├── verify <address>         # Verify on explorer
├── wallet
│   ├── create <name>
│   ├── import <name>
│   ├── list
│   ├── balance [name]
│   ├── address [name]
│   ├── send <to> <amount>
│   ├── remove <name>
│   ├── set-default <name>
│   └── export <name>
├── node
│   ├── start
│   ├── stop
│   ├── status
│   └── logs
└── network
    ├── list
    └── current
```

## Configuration

### chain.config.toml

Each chain has a TOML configuration file:

```toml
[chain]
name = "Somnia"
type = "evm"
id = "somnia"

[cli]
name = "somniactl"

[networks.testnet]
chain_id = 50311
rpc_url = "https://dream-rpc.somnia.network"
native_currency = "STT"
is_default = true

[features]
anvil = true
foundry = true
opencode = true
```

See [TOML-REFERENCE.md](./TOML-REFERENCE.md) for complete documentation.

### AGENTS.md

Each chain includes an AI context file that provides:

- Network information (chain ID, RPC, explorer)
- CLI command reference
- Development workflow guidance
- Chain-specific patterns and best practices
- Troubleshooting tips

This file is copied to `/etc/opencode/AGENTS.md` in the container.

## Infrastructure

### Terraform Modules

#### workstations

Creates Cloud Workstations infrastructure:

- Workstation cluster
- Workstation configuration (machine type, disk, timeouts)
- Individual workstations with IAM bindings
- Admin access configuration

#### artifact-registry

Creates Artifact Registry repository for container images.

### Deployment Flow

```
1. Build image locally or in Cloud Build
2. Push to Artifact Registry
3. Apply Terraform to create/update workstations
4. Developers access via Cloud Workstations
```

## Adding New Chains

See [ADDING-CHAIN.md](./ADDING-CHAIN.md) for a complete guide.

Quick start:

```bash
./scripts/new-chain.sh polygon --type=evm --chain-id=137 --native-currency=MATIC
```

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Build system | Earthly | Composable, cacheable, Cloud Build compatible |
| Base image | Google Code OSS | Cloud Workstations native, VS Code included |
| CLI language | TypeScript | Type safety, familiar to web3 devs |
| Wallet storage | Plaintext JSON | Ephemeral dev environments, simplicity |
| Config format | TOML | Human-readable, well-structured |
| Testing | Vitest | Fast, ESM-native, good TypeScript support |

## Future Enhancements

- [ ] Additional chain types (non-EVM: Midnight, Solana, etc.)
- [ ] Plugin system for CLI extensions
- [ ] Contract verification automation
- [ ] Integrated faucet requests
- [ ] Multi-network deployment workflows
- [ ] Hardhat compatibility layer
