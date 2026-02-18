# Sonic Agent Implementation Plan

> **Status**: Planning  
> **Last Updated**: 2026-02-18  
> **Depends on**: `packages/evm-mcp` (see [EVM MCP README](packages/evm-mcp/README.md))

## Overview

Create a **Sonic Agent** that provides:
1. **Standard EVM skills** via `evm-mcp` (compile, deploy, call, tx-status)
2. **LLM-based code generation** (solidity-gen with Sonic/FeeM context)
3. **FeeM capabilities** (contract registration guidance, rewards info)
4. **Future: Flying Tulip integration** (full DeFi suite)

## Architecture

Sonic Agent is a **thin wrapper** that:
- Uses LLM for Solidity code generation (with Sonic-specific `SKILLS.md`)
- Delegates all Foundry operations to `evm-mcp` via MCP protocol
- Handles FeeM-specific guidance and information

```
┌─────────────────────────────────────────────────────────────────┐
│                       sonic-agent                                │
│                       Port: 4002                                 │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ SKILLS.md                                                 │  │
│  │ - Sonic network info (Chain ID 146, RPC, Explorer)        │  │
│  │ - FeeM documentation (90% fee share, registration)        │  │
│  │ - Solidity best practices for Sonic                       │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Skills:                                                         │
│  ├── solidity-gen   → LLM generates code (uses SKILLS.md)       │
│  ├── compile        → Calls evm-mcp forge_compile               │
│  ├── deploy         → Calls evm-mcp forge_deploy                │
│  ├── call           → Calls evm-mcp cast_call                   │
│  ├── tx-status      → Calls evm-mcp cast_receipt                │
│  └── feem-info      → Returns FeeM guidance (no MCP needed)     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ MCP over HTTP/SSE
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         evm-mcp                                  │
│                         Port: 4011                               │
│                                                                  │
│  - Foundry toolchain (Anvil, Forge, Cast)                       │
│  - Local Anvil fork by default                                  │
│  - Unsigned tx for mainnet deployments                          │
└─────────────────────────────────────────────────────────────────┘
```

## Sonic Blockchain

| Property | Value |
|----------|-------|
| **Chain ID** | 146 (mainnet) |
| **RPC** | https://rpc.soniclabs.com |
| **Explorer** | https://sonicscan.org |
| **Native Token** | S (Sonic) |
| **Performance** | 400,000 TPS, sub-second finality |
| **EVM Compatible** | Full Solidity/Vyper support |

## FeeM (Fee Monetization)

Sonic's unique developer incentive system:

| Feature | Description |
|---------|-------------|
| **Fee Share** | Developers earn **90%** of network fees their apps generate |
| **Validator Share** | 10% goes to validators |
| **Tracking** | Off-chain oracles track gas consumption per contract |
| **Distribution** | Rewards distributed via FeeM contract |
| **Proxy Support** | Works with upgradeable (proxy) contracts |
| **Dashboard** | https://feem.soniclabs.com/ |

### FeeM Registration Notes
- Only need to register **proxy address** for upgradeable contracts
- Gas consumed via delegate-call attributed to proxy
- No deadline for claiming rewards
- Rewards processed after epoch is sealed

---

## Package Structure

```
packages/sonic-agent/
├── package.json
├── tsconfig.json
├── Containerfile
├── SKILLS.md                    # LLM context (Sonic + FeeM)
└── src/
    ├── index.ts                 # A2A server entry point
    ├── agent-card.ts            # Agent card definition
    ├── executor.ts              # Request handler
    ├── genkit.ts                # LLM initialization (Vertex AI)
    ├── mcp-client.ts            # MCP client for evm-mcp
    └── skills/
        ├── index.ts             # Skill registry + detectSkill()
        ├── solidity-gen.ts      # LLM-based code generation
        ├── compile.ts           # → evm-mcp forge_compile
        ├── deploy.ts            # → evm-mcp forge_deploy
        ├── call.ts              # → evm-mcp cast_call
        ├── tx-status.ts         # → evm-mcp cast_receipt
        └── feem.ts              # FeeM info/guidance (no MCP)
```

---

## Implementation Phases

### Phase 0: Prerequisites
- [x] `evm-mcp` README documented
- [ ] `evm-mcp` implementation complete

### Phase 1: Core Agent Setup (~1.5 hours)

| Task | Status |
|------|--------|
| Create `packages/sonic-agent/` directory | ⬜ |
| Create `package.json` | ⬜ |
| Create `tsconfig.json` | ⬜ |
| Create `Containerfile` | ⬜ |
| Implement `src/index.ts` (A2A server) | ⬜ |
| Implement `src/agent-card.ts` | ⬜ |
| Implement `src/executor.ts` | ⬜ |
| Implement `src/genkit.ts` | ⬜ |
| Implement `src/mcp-client.ts` | ⬜ |

### Phase 2: Skills Implementation (~2.5 hours)

| Task | Status |
|------|--------|
| Implement `skills/index.ts` | ⬜ |
| Implement `skills/solidity-gen.ts` (LLM) | ⬜ |
| Implement `skills/compile.ts` (→ evm-mcp) | ⬜ |
| Implement `skills/deploy.ts` (→ evm-mcp) | ⬜ |
| Implement `skills/call.ts` (→ evm-mcp) | ⬜ |
| Implement `skills/tx-status.ts` (→ evm-mcp) | ⬜ |
| Implement `skills/feem.ts` | ⬜ |

### Phase 3: SKILLS.md (~45 min)

| Task | Status |
|------|--------|
| Network information section | ⬜ |
| FeeM documentation section | ⬜ |
| Skill examples and prompts | ⬜ |
| Chain keyword detection guidance | ⬜ |

### Phase 4: Configuration & Deployment (~1 hour)

| Task | Status |
|------|--------|
| Update `config.toml` (`enabled = true`) | ⬜ |
| Add to `compose.yaml` | ⬜ |
| Add to `cloudbuild.yaml` | ⬜ |
| Update `pnpm-workspace.yaml` | ⬜ |
| Update agent-registry | ⬜ |
| Test locally | ⬜ |
| Deploy to Cloud Run | ⬜ |

**Total Estimated Time: ~5-6 hours** (after evm-mcp is complete)

---

## Skill Implementations

### solidity-gen (LLM-based)

```typescript
// Uses SKILLS.md context + LLM to generate Solidity code
async function* generateSolidity(userMessage: Message) {
  yield { type: 'status', message: 'Generating Solidity code...' };
  
  const result = await streamText({
    model,
    system: loadSkillsContext(),  // SKILLS.md
    prompt: extractText(userMessage),
  });
  
  yield { type: 'artifact', name: 'Contract.sol', content: result };
}
```

### compile (→ evm-mcp)

```typescript
async function* compile(source: string, sessionId: string) {
  const mcp = await getMcpClient();
  
  const result = await mcp.callTool('forge_compile', {
    source,
    solcVersion: '0.8.28',
  });
  
  yield { 
    type: 'artifact', 
    name: 'compilation-result.json', 
    content: JSON.stringify(result) 
  };
}
```

### deploy (→ evm-mcp)

```typescript
async function* deploy(bytecode: string, abi: object[], sessionId: string) {
  const mcp = await getMcpClient();
  
  // Default: local Anvil fork
  // If user said "mainnet", returns unsigned tx
  const result = await mcp.callTool('forge_deploy', {
    bytecode,
    abi,
    network: 'local',  // or 'sonic-mainnet'
    sessionId,
  });
  
  if (result.unsignedTx) {
    yield { type: 'artifact', name: 'unsigned-tx.json', content: JSON.stringify(result.unsignedTx) };
  } else {
    yield { type: 'result', data: { address: result.contractAddress, txHash: result.txHash } };
  }
}
```

### feem-info (no MCP)

```typescript
async function* feemInfo() {
  yield {
    type: 'result',
    data: {
      message: `
## FeeM (Fee Monetization)

Sonic's unique developer incentive: **earn 90% of gas fees** your contracts generate!

### How It Works
1. Deploy your contract to Sonic mainnet
2. Register at https://feem.soniclabs.com/
3. Start earning fees automatically

### Key Points
- 90% to developers, 10% to validators
- For upgradeable contracts, register the **proxy address**
- No deadline for claiming rewards
- Rewards processed after each epoch

### Registration Checklist
- [ ] Contract deployed to Sonic mainnet
- [ ] Contract address verified on SonicScan
- [ ] Ownership/control verified
- [ ] Application submitted at feem.soniclabs.com
      `,
    },
  };
}
```

---

## Agent Card

```typescript
export const sonicAgentCard: AgentCard = {
  name: 'Sonic Agent',
  description: 'High-performance EVM chain with FeeM (Fee Monetization). ' +
    'Generate, compile, and deploy Solidity contracts. Earn 90% of gas fees!',
  url: process.env.SONIC_AGENT_URL || 'http://localhost:4002',
  version: '0.1.0',
  capabilities: {
    streaming: true,
    pushNotifications: false,
  },
  skills: [
    {
      id: 'solidity-gen',
      name: 'Generate Solidity',
      description: 'Generate Solidity smart contracts for Sonic',
      tags: ['solidity', 'contract', 'generate', 'code', 'erc20', 'nft'],
      examples: [
        'Create an ERC-20 token for Sonic',
        'Generate a simple NFT contract',
        'Build a staking contract',
      ],
    },
    {
      id: 'compile',
      name: 'Compile Contract',
      description: 'Compile Solidity source code using Foundry',
      tags: ['compile', 'build', 'solidity', 'forge'],
      examples: ['Compile this contract', 'Build my Solidity code'],
    },
    {
      id: 'deploy',
      name: 'Deploy Contract',
      description: 'Deploy a contract to Sonic (local fork by default)',
      tags: ['deploy', 'publish', 'mainnet', 'fork'],
      examples: ['Deploy this contract', 'Deploy to Sonic mainnet'],
    },
    {
      id: 'call',
      name: 'Call Contract',
      description: 'Call a view function on a deployed contract',
      tags: ['call', 'read', 'view', 'query'],
      examples: ['Get balance of 0x...', 'Call totalSupply on 0x...'],
    },
    {
      id: 'tx-status',
      name: 'Transaction Status',
      description: 'Check the status of a transaction',
      tags: ['transaction', 'status', 'receipt', 'tx'],
      examples: ['Check status of 0x...', 'What happened to tx 0x...'],
    },
    {
      id: 'feem-info',
      name: 'FeeM Information',
      description: 'Learn about Fee Monetization on Sonic',
      tags: ['feem', 'fees', 'monetization', 'rewards', 'earnings'],
      examples: [
        'How does FeeM work?',
        'How do I register for fee monetization?',
        'How much can I earn from FeeM?',
      ],
    },
  ],
};
```

---

## Configuration

### config.toml

```toml
[default.agents.sonic]
name = "Sonic Agent"
description = "High-performance EVM chain with FeeM. Earn 90% of gas fees!"
service = "sonic-agent"
chain_id = 146
keywords = ["sonic", "ftm", "fantom", "feem", "fee monetization", "s token"]
enabled = true
```

### compose.yaml

```yaml
sonic-agent:
  build:
    context: .
    dockerfile: packages/sonic-agent/Containerfile
  container_name: sonic-agent
  ports:
    - "${SONIC_AGENT_PORT:-4002}:8080"
  environment:
    - NODE_ENV=development
    - SONIC_AGENT_PORT=8080
    - SONIC_AGENT_HOST=0.0.0.0
    - EVM_MCP_URL=http://evm-mcp:8080
    - GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}
    - GOOGLE_CLOUD_LOCATION=${GOOGLE_CLOUD_LOCATION:-us-central1}
  depends_on:
    evm-mcp:
      condition: service_healthy
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SONIC_AGENT_HOST` | Host to bind | `0.0.0.0` |
| `SONIC_AGENT_PORT` | Port to listen | `4002` |
| `EVM_MCP_URL` | EVM MCP server URL | `http://evm-mcp:8080` |

---

## Dependencies

```json
{
  "dependencies": {
    "@a2a-js/sdk": "^0.3.10",
    "@coding-labs/shared": "workspace:*",
    "@ai-sdk/google-vertex": "^3.0.98",
    "@modelcontextprotocol/sdk": "^1.0.0",
    "ai": "^5.0.0",
    "express": "^4.21.0",
    "uuid": "^11.0.0"
  }
}
```

Note: No `viem` or `solc` - all EVM operations delegated to `evm-mcp`.

---

## Testing

### Local Testing

```bash
# 1. Start evm-mcp
cd packages/evm-mcp && bun dev

# 2. Start sonic-agent
cd packages/sonic-agent && bun dev

# 3. Test health
curl http://localhost:4002/health

# 4. Test agent card
curl http://localhost:4002/.well-known/agent.json

# 5. Test via A2A
curl -X POST http://localhost:4002/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"message/send","id":"1","params":{
    "message":{"messageId":"m1","role":"user","parts":[
      {"type":"text","text":"Create an ERC-20 token called SonicToken"}
    ]}
  }}'
```

### Container Testing

```bash
docker compose up sonic-agent evm-mcp
curl http://localhost:4002/health
```

---

## Future: Flying Tulip Integration

Flying Tulip is a comprehensive DeFi ecosystem on Sonic. To be implemented in a future iteration.

### Products

| Product | Description |
|---------|-------------|
| **ft-spot** | Trading (swaps, LP provision) via hybrid AMM + CLOB |
| **ft-lend** | Lending/borrowing with cross-collateral |
| **ft-futures** | Oracle-free perpetual futures |
| **ft-ftusd** | Delta-neutral stablecoin with 7-8% APY |
| **ft-insurance** | On-demand asset protection |

### Key Contracts (Sonic Mainnet)

| Contract | Address |
|----------|---------|
| **FT Token** | `0x5DD1A7A369e8273371d2DBf9d83356057088082c` |
| **FT Oracle** | `0xC8C895E2be9511006287Ce02E51B5B198AB36793` |
| **ftPUT (Proxy)** | `0xa4215Daaf3745E14E96E169E0E7706c479Ce04F2` |
| **PutManager (Proxy)** | `0xbA49d0AC42f4fBA4e24A8677a22218a4dF75ebaA` |
| **Circuit Breaker** | `0xCb170bc873b3a1F69F433C25a4b6d0fd4D4D90De` |

---

## References

- [EVM MCP README](packages/evm-mcp/README.md) - Foundry toolchain server
- [Sonic Docs](https://docs.soniclabs.com/)
- [FeeM Documentation](https://docs.soniclabs.com/funding/fee-monetization)
- [FeeM Dashboard](https://feem.soniclabs.com/)
- [Flying Tulip Docs](https://docs.flyingtulip.com/)
- [SonicScan Explorer](https://sonicscan.org/)
- [Somnia Agent](packages/somnia-agent/) - Reference implementation
