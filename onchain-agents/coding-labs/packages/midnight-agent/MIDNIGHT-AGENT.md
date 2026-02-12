# Midnight Agent

A2A agent for the **Midnight Network** - a privacy-preserving blockchain using zero-knowledge proofs.

## Overview

The Midnight Agent provides AI-powered assistance for developing applications on Midnight Network.
Unlike EVM-based agents (somnia-agent), Midnight uses its own smart contract language called
**Compact** and requires ZK proof generation for transaction execution.

## Version Compatibility Matrix (v1.0)

This agent is built for **Compatibility v1.0** of the Midnight Network.

| Component | Version | Notes |
|-----------|---------|-------|
| Compact Compiler | 0.28.0 | Language version 0.20 |
| Compact Runtime | 0.14.0 | TypeScript runtime |
| Midnight.js | v3.0.0 | SDK for DApp development |
| Ledger | 7.0.0 | Core ledger logic |
| Proof Server | 7.0.0 | ZK proof generation |
| Indexer | v3.0.0 | GraphQL state queries |
| DApp Connector API | v4.0.0 | Wallet connection |
| Wallet SDK | 1.0.0 | Lace wallet integration |

**Source**: https://docs.midnight.network/next/relnotes/overview#compatibility-matrix

## Network Endpoints

### Preview (Development)

| Service | URL |
|---------|-----|
| Node RPC | https://rpc.preview.midnight.network |
| Indexer (GraphQL) | https://indexer.preview.midnight.network/api/v3/graphql |
| Proof Server | https://lace-proof-pub.preview.midnight.network |
| Faucet | https://faucet.preview.midnight.network/ |
| Block Explorer | https://explorer.preview.midnight.network/ (VPN required) |

### Preprod (Staging)

| Service | URL |
|---------|-----|
| Node RPC | https://rpc.preprod.midnight.network |
| Indexer (GraphQL) | https://indexer.preprod.midnight.network/api/v3/graphql |
| Proof Server | https://lace-proof-pub.preprod.midnight.network |
| Faucet | https://faucet.preprod.midnight.network/ |
| Block Explorer | https://explorer.preprod.midnight.network/ (VPN required) |

## Skills

| Skill | Status | Description |
|-------|--------|-------------|
| `compact-gen` | **Active** | Generate Compact smart contracts using LLM |
| `compile` | Planned | Compile Compact to ZK circuits (requires compactc) |
| `deploy` | Planned | Deploy contract to Midnight (requires wallet) |
| `call` | Planned | Execute circuit with ZK proof generation |
| `query-state` | Planned | Query public ledger via Indexer GraphQL |
| `private-state` | Planned | Manage local encrypted private state |

### compact-gen Skill

The primary skill currently implemented. Uses Vertex AI (Gemini) with comprehensive
Compact language context from `SKILLS.md` to generate smart contracts.

**Example prompts:**
- "Create a simple counter contract"
- "Generate a voting contract with private ballots"
- "Create a token contract with confidential balances"
- "Build a contract with time-locked access control"

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    midnight-agent                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Skills                                                 │  │
│  │  - compact-gen (LLM generates Compact code)           │  │
│  │  - compile (shell to compact compiler) [planned]      │  │
│  │  - deploy (Midnight.js + wallet) [planned]            │  │
│  │  - call (execute circuit with ZK proof) [planned]     │  │
│  │  - query-state (Indexer GraphQL) [planned]            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
     ┌────────────────────────┼────────────────────────┐
     ▼                        ▼                        ▼
┌──────────────┐       ┌──────────────┐        ┌──────────────┐
│ Compact      │       │ Proof Server │        │ Midnight     │
│ Compiler     │       │ (Docker)     │        │ Indexer      │
│              │       │              │        │              │
│ .compact →   │       │ ZK proof     │        │ GraphQL API  │
│ ZK circuits  │       │ generation   │        │ for state    │
└──────────────┘       └──────────────┘        └──────────────┘
```

## Key Differences from EVM Agents

| Aspect | EVM (somnia-agent) | Midnight (midnight-agent) |
|--------|-------------------|---------------------------|
| Contract Language | Solidity | Compact |
| SDK | viem | Midnight.js |
| Wallet | MetaMask | Lace Midnight |
| Transaction Model | EVM bytecode | ZK circuits + witnesses |
| State Model | Account-based | UTXO + dual ledger |
| Privacy | Public by default | Private by default |
| Proofs | None | ZK proofs required |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MIDNIGHT_AGENT_HOST` | localhost | Server bind address |
| `MIDNIGHT_AGENT_PORT` | 4003 | Server port |
| `MIDNIGHT_AGENT_URL` | http://localhost:4003 | Public URL for A2A |
| `MIDNIGHT_AGENT_LLM_PROJECT` | kunal-scratch | GCP project for Vertex AI |
| `MIDNIGHT_AGENT_LLM_LOCATION` | us-central1 | GCP region |
| `MIDNIGHT_AGENT_LLM_MODEL` | gemini-2.0-flash | LLM model |

### config.toml

```toml
[default.services.midnight-agent]
host = "localhost"
port = 4003

[default.agents.midnight]
name = "Midnight Agent"
description = "Privacy-preserving blockchain with ZK proofs and Compact language."
service = "midnight-agent"
chain_id = 0
keywords = ["midnight", "privacy", "zk", "zero-knowledge", "compact"]
enabled = true
```

## Development

### Running Locally

```bash
# From project root
pnpm --filter @coding-labs/midnight-agent dev

# Or via make
make run  # Starts all agents including midnight-agent
```

### Testing

```bash
# Health check
curl http://localhost:4003/health

# Agent card
curl http://localhost:4003/.well-known/agent.json

# Send A2A message
AGENT=midnight ./scripts/a2a.sh send "Create a simple counter contract"
```

## Future Roadmap

### Phase B: Compilation
- Install Compact compiler in container
- Implement `compile` skill
- Add syntax validation

### Phase C: Network Integration
- Add Midnight.js SDK packages
- Implement `query-state` skill
- Integrate with Indexer GraphQL

### Phase D: Wallet & Deployment
- Proof Server sidecar container
- Lace wallet connector
- `deploy` and `call` skills
- Private state management

## References

- [Midnight Docs](https://docs.midnight.network)
- [Compact Language Reference](https://docs.midnight.network/next/compact/reference/lang-ref)
- [Midnight.js GitHub](https://github.com/midnightntwrk/midnight-js)
- [Midnight SDK](https://github.com/midnightntwrk/midnight-sdk)
- [Release Notes](https://docs.midnight.network/next/relnotes/overview)
