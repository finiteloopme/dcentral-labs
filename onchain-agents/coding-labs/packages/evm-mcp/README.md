# EVM MCP Server

> Shared Foundry toolchain for all EVM chain agents

## Overview

The `evm-mcp` package provides a Model Context Protocol (MCP) server that wraps the Foundry toolchain (Anvil, Forge, Cast). EVM chain agents (sonic-agent, somnia-agent, etc.) call this server for compilation, deployment, and chain interactions.

This follows the same pattern as `midnight-mcp` for the Compact compiler.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Session Boundary                                │
│                                                                              │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                       │
│   │sonic-agent  │   │somnia-agent │   │ base-agent  │  (future)             │
│   │ Port: 4002  │   │ Port: 4001  │   │ Port: 4005  │                       │
│   │             │   │             │   │             │                       │
│   │ SKILLS.md:  │   │ SKILLS.md:  │   │ SKILLS.md:  │                       │
│   │ - Sonic     │   │ - Somnia    │   │ - Base      │                       │
│   │ - FeeM      │   │ - Reactivity│   │ - L2        │                       │
│   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘                       │
│          │                 │                 │                               │
│          └────────────────┬┴─────────────────┘                               │
│                           │                                                  │
│                           │ MCP over HTTP/SSE                               │
│                           │ + sessionId (for locking)                       │
│                           │ + network (optional)                            │
│                           ▼                                                  │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         evm-mcp                                      │   │
│   │                         Port: 4011                                   │   │
│   │                                                                      │   │
│   │  Session: locked by {agent} (one EVM agent per session)             │   │
│   │                                                                      │   │
│   │  ┌─────────────────────────────────────────────────────────────┐    │   │
│   │  │ Anvil (started when user indicates chain)                   │    │   │
│   │  │ - Forks from real chain RPC (has real state)               │    │   │
│   │  │ - Pre-funded test accounts                                  │    │   │
│   │  │ - Instant blocks, no gas costs                              │    │   │
│   │  │ - Port 8545                                                 │    │   │
│   │  └─────────────────────────────────────────────────────────────┘    │   │
│   │                                                                      │   │
│   │  Foundry Tools:                                                      │   │
│   │  ├── forge   - Compile, test, deploy                                │   │
│   │  ├── cast    - Chain interaction CLI                                │   │
│   │  └── anvil   - Local EVM node                                       │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Session Locking

Only **one EVM agent** can use `evm-mcp` per session. If another agent tries to use it:

```
Error: EVM MCP is currently locked by sonic-agent (session: abc123).
Only one EVM agent can use evm-mcp per session.
```

### 2. Local Dev by Default

All environments (local, container, Cloud Run) default to **local Anvil fork**:

| Environment | Default Behavior |
|-------------|------------------|
| Local (`bun dev`) | Anvil fork of specified chain |
| Container (`docker compose`) | Anvil fork of specified chain |
| Cloud Run | Ephemeral Anvil per request |

Real network deployment requires **explicit user confirmation**.

### 3. Anvil Fork (Not Standalone)

When user indicates a chain (e.g., "Sonic"), Anvil **forks from mainnet RPC**:
- Has real contract state, balances, bytecode
- Can interact with existing deployed contracts
- More realistic testing environment

### 4. Lazy Anvil Startup

Anvil starts when user **indicates usage for a specific chain**:

```
User: "Create a Sonic counter contract"
       └─ "Sonic" detected → Fork Sonic mainnet to local Anvil

User: "Create a counter contract"  
       └─ No chain specified → Agent asks which chain
```

### 5. Network Detection with Confirmation

When agent detects network-specific keywords ("mainnet", "production", "deploy to Sonic"):

```
Agent: "Did you mean:
1. Sonic Mainnet (real network, requires S tokens) → unsigned tx
2. Local Sonic fork (dev mode, test accounts) → direct deploy

I'll use local fork by default for testing."
```

## MCP Tools

### forge_compile

Compile Solidity source code using Foundry.

```typescript
{
  name: 'forge_compile',
  input: {
    source: string,           // Solidity source code
    filename?: string,        // Contract filename (default: Contract.sol)
    solcVersion?: string,     // Solidity version (default: 0.8.28)
  },
  output: {
    success: boolean,
    contractName: string,
    abi: object[],
    bytecode: string,
    deployedBytecode: string,
    errors?: string,
  }
}
```

### forge_deploy

Deploy a compiled contract.

```typescript
{
  name: 'forge_deploy',
  input: {
    bytecode: string,
    abi: object[],
    constructorArgs?: unknown[],
    network?: string,         // 'local' (default), 'sonic-mainnet', 'somnia-testnet'
    sessionId: string,
  },
  output: {
    // If local (dev mode):
    success: boolean,
    contractAddress: string,
    txHash: string,
    
    // If mainnet (production):
    success: boolean,
    unsignedTx: {
      to: null,
      data: string,
      chainId: number,
      gasLimit: string,
    },
  }
}
```

### cast_call

Call a view/pure function on a contract.

```typescript
{
  name: 'cast_call',
  input: {
    contractAddress: string,
    functionSig: string,      // e.g., "balanceOf(address)"
    args?: string[],
    network?: string,
    sessionId: string,
  },
  output: {
    success: boolean,
    result: string,           // Raw hex result
    decoded?: unknown,        // Decoded value if ABI provided
  }
}
```

### cast_send

Send a state-changing transaction.

```typescript
{
  name: 'cast_send',
  input: {
    contractAddress: string,
    functionSig: string,
    args?: string[],
    value?: string,           // ETH value in wei
    network?: string,
    sessionId: string,
  },
  output: {
    // If local:
    success: boolean,
    txHash: string,
    
    // If mainnet:
    success: boolean,
    unsignedTx: object,
  }
}
```

### cast_receipt

Get transaction receipt.

```typescript
{
  name: 'cast_receipt',
  input: {
    txHash: string,
    network?: string,
    sessionId: string,
  },
  output: {
    success: boolean,
    status: 'success' | 'failed',
    blockNumber: number,
    gasUsed: string,
    logs: object[],
    contractAddress?: string,  // If deployment
  }
}
```

## Chain Presets

```typescript
const CHAIN_PRESETS = {
  'sonic-mainnet': {
    name: 'Sonic Mainnet',
    chainId: 146,
    rpcUrl: 'https://rpc.soniclabs.com',
    explorerUrl: 'https://sonicscan.org',
    nativeCurrency: { name: 'Sonic', symbol: 'S', decimals: 18 },
  },
  'somnia-testnet': {
    name: 'Somnia Shannon Testnet',
    chainId: 50312,
    rpcUrl: 'https://dream-rpc.somnia.network/',
    explorerUrl: 'https://shannon-explorer.somnia.network',
    nativeCurrency: { name: 'Somnia Test Token', symbol: 'STT', decimals: 18 },
  },
  // Add more as needed
};
```

## Session Management

```typescript
interface SessionState {
  sessionId: string;
  agentId: string;           // 'sonic-agent', 'somnia-agent', etc.
  chainId: number;           // Which chain is forked
  anvilProcess: ChildProcess | null;
  anvilRpcUrl: string;
  lockedAt: Date;
}

// Only one session at a time
let currentSession: SessionState | null = null;
```

### Session Lifecycle

1. **Acquire**: First tool call with `sessionId` + chain context locks the session
2. **Use**: All subsequent calls must use same `sessionId`
3. **Release**: Explicit release or container/instance termination

### Chain Switch Prevention

```typescript
if (currentSession && currentSession.chainId !== requestedChainId) {
  throw new Error(
    `Cannot switch chains mid-session. ` +
    `Current: ${currentSession.chainId}, Requested: ${requestedChainId}. ` +
    `Start a new session to use a different chain.`
  );
}
```

## Package Structure

```
packages/evm-mcp/
├── package.json
├── tsconfig.json
├── Containerfile
├── README.md                    # This file
└── src/
    ├── index.ts                 # MCP server entry point (HTTP + SSE)
    ├── config.ts                # Chain presets, env vars
    ├── session.ts               # Session management
    ├── foundry/
    │   ├── anvil.ts             # Anvil process management
    │   ├── forge.ts             # Forge command wrappers
    │   └── cast.ts              # Cast command wrappers
    └── tools/
        ├── index.ts             # Tool registration
        ├── forge-compile.ts
        ├── forge-deploy.ts
        ├── cast-call.ts
        ├── cast-send.ts
        └── cast-receipt.ts
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `EVM_MCP_PORT` | Server port | `4011` |
| `EVM_MCP_HOST` | Server host | `0.0.0.0` |
| `ANVIL_PORT` | Local Anvil port | `8545` |

## Containerfile

```dockerfile
FROM node:22-slim

# Install dependencies for Foundry
RUN apt-get update && apt-get install -y curl git && rm -rf /var/lib/apt/lists/*

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Verify installation
RUN forge --version && cast --version && anvil --version

WORKDIR /app

# Copy built package
COPY packages/evm-mcp/dist ./dist
COPY packages/evm-mcp/package.json ./

# Install production dependencies
RUN npm install --omit=dev

EXPOSE 8080

CMD ["node", "dist/index.js"]
```

## Implementation Checklist

### Phase 1: evm-mcp Server (~6 hours)

| # | Task | Status |
|---|------|--------|
| 1.1 | Create `packages/evm-mcp/` directory structure | ✅ |
| 1.2 | Create `package.json` with dependencies | ⬜ |
| 1.3 | Create `tsconfig.json` | ⬜ |
| 1.4 | Create `Containerfile` with Foundry | ⬜ |
| 1.5 | Implement `src/index.ts` (MCP server + health) | ⬜ |
| 1.6 | Implement `src/config.ts` (chain presets) | ⬜ |
| 1.7 | Implement `src/session.ts` (session management) | ⬜ |
| 1.8 | Implement `foundry/anvil.ts` (process management) | ⬜ |
| 1.9 | Implement `foundry/forge.ts` (compile, deploy) | ⬜ |
| 1.10 | Implement `foundry/cast.ts` (call, send, receipt) | ⬜ |
| 1.11 | Implement `tools/forge-compile.ts` | ⬜ |
| 1.12 | Implement `tools/forge-deploy.ts` | ⬜ |
| 1.13 | Implement `tools/cast-call.ts` | ⬜ |
| 1.14 | Implement `tools/cast-send.ts` | ⬜ |
| 1.15 | Implement `tools/cast-receipt.ts` | ⬜ |
| 1.16 | Implement `tools/index.ts` (registration) | ⬜ |
| 1.17 | Add to `config.toml` | ⬜ |
| 1.18 | Add to `compose.yaml` | ⬜ |
| 1.19 | Test locally | ⬜ |

### Phase 2: sonic-agent (~4.5 hours)

| # | Task | Status |
|---|------|--------|
| 2.1 | Create `packages/sonic-agent/` structure | ⬜ |
| 2.2 | Create `package.json` | ⬜ |
| 2.3 | Create `tsconfig.json` | ⬜ |
| 2.4 | Create `Containerfile` | ⬜ |
| 2.5 | Create `SKILLS.md` (Sonic + FeeM) | ⬜ |
| 2.6 | Implement `src/index.ts` (A2A server) | ⬜ |
| 2.7 | Implement `src/agent-card.ts` | ⬜ |
| 2.8 | Implement `src/executor.ts` | ⬜ |
| 2.9 | Implement `src/genkit.ts` | ⬜ |
| 2.10 | Implement `src/mcp-client.ts` | ⬜ |
| 2.11 | Implement `skills/index.ts` | ⬜ |
| 2.12 | Implement `skills/solidity-gen.ts` | ⬜ |
| 2.13 | Implement `skills/compile.ts` | ⬜ |
| 2.14 | Implement `skills/deploy.ts` | ⬜ |
| 2.15 | Implement `skills/call.ts` | ⬜ |
| 2.16 | Implement `skills/tx-status.ts` | ⬜ |
| 2.17 | Implement `skills/feem.ts` | ⬜ |
| 2.18 | Update `config.toml` | ⬜ |
| 2.19 | Add to `compose.yaml` | ⬜ |
| 2.20 | Add to `cloudbuild.yaml` | ⬜ |
| 2.21 | Update agent-registry | ⬜ |
| 2.22 | Test locally | ⬜ |
| 2.23 | Deploy to Cloud Run | ⬜ |

**Total Estimated Time: ~10-11 hours**

## Service Map (Updated)

| Service | Port | Purpose |
|---------|------|---------|
| agent-registry | 4000 | Agent discovery |
| somnia-agent | 4001 | Somnia chain |
| **sonic-agent** | **4002** | **Sonic chain (NEW)** |
| midnight-agent | 4003 | Midnight chain |
| github-agent | 4004 | Git operations (planned) |
| midnight-mcp | 4010 | Compact compiler + Midnight tools |
| **evm-mcp** | **4011** | **Foundry toolchain (NEW)** |

## User Flow Examples

### Example 1: Local Development (Default)

```
User: "Create an ERC-20 token for Sonic"

Agent: "Creating ERC-20 token for Sonic...

Starting local Sonic fork from https://rpc.soniclabs.com...
✓ Forked at block 12,345,678
✓ Test accounts ready (10000 S each)

Generating SonicToken.sol...
✓ Generated ERC-20 with 1 million supply

Compiling...
✓ Compiled successfully

Deploying to local fork...
✓ Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3

Your token is live on the local Sonic fork!
Try: 'Check balance of 0xf39F...' or 'Transfer 100 tokens to 0x...'

Ready for mainnet? Say 'deploy to Sonic mainnet'"
```

### Example 2: Mainnet Deployment (Explicit)

```
User: "Deploy this to Sonic mainnet"

Agent: "⚠️ Deploying to Sonic Mainnet (Chain ID 146)

This is a production deployment that requires:
• S tokens for gas (~0.01 S estimated)
• Your wallet to sign the transaction

Confirm deployment to Sonic Mainnet?
1. Yes, prepare unsigned transaction
2. No, stay on local fork"

User: "Yes"

Agent: "Preparing deployment transaction...

Unsigned Transaction:
{
  "to": null,
  "data": "0x608060405234801561001057600080fd5b50...",
  "chainId": 146,
  "gasLimit": "1500000",
  "value": "0x0"
}

To deploy:
1. Import this transaction into your wallet
2. Sign and broadcast to Sonic RPC: https://rpc.soniclabs.com
3. Share the transaction hash and I'll track it for you

💡 After deployment, register for FeeM at https://feem.soniclabs.com/ 
   to earn 90% of gas fees your contract generates!"
```

## Future Enhancements

1. **forge_test**: Run Foundry tests
2. **forge_verify**: Verify contracts on block explorers  
3. **anvil_snapshot**: Save/restore Anvil state
4. **Multi-session support**: Multiple Anvil instances for different sessions
5. **somnia-agent migration**: Refactor to use evm-mcp
