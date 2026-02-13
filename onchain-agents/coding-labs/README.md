# Coding Labs

Multi-agent platform for on-chain development using the [A2A (Agent-to-Agent) protocol](https://a2a-protocol.org).

## Overview

Coding Labs provides AI agents specialized for blockchain development. Each agent understands chain-specific nuances, gas optimization patterns, and unique features.

### Architecture

```
┌──────────────────────┐         ┌─────────────────────────────────────────────┐
│   opencode-login     │         │           opencode-web (port 3000)          │
│   (port 4098)        │         │  ┌─────────────────────────────────────┐    │
│                      │         │  │            OpenCode Web             │    │
│   dCoder Landing     │  ──→    │  │       (Primary User Interface)      │    │
│   "Sign in with      │  click  │  │                                     │    │
│    Google" button    │         │  │  - Browser-based coding session     │    │
│                      │         │  │  - Wallet connection (MetaMask)     │    │
│   (Public)           │         │  │  - A2A Client integrated            │    │
└──────────────────────┘         │  │  - Routes to chain agents           │    │
                                 │  └──────────────────┬──────────────────┘    │
                                 │    (IAP Protected)  │                       │
                                 └─────────────────────┼───────────────────────┘
                                                       │ A2A Protocol (HTTP+JSON)
                          ┌────────────────────────────┼────────────────────────┐
                          ▼                            ▼                        ▼
                ┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
                │   Somnia Agent    │   │  Midnight Agent   │   │   Sonic Agent     │
                │   (port 4001)     │   │  (port 4003)      │   │   (future)        │
                ├───────────────────┤   ├───────────────────┤   ├───────────────────┤
                │ - Solidity Gen    │   │ - Compact Gen     │   │ - Solidity Gen    │
                │ - Deploy          │   │ - (compile)       │   │ - FeeM Optimize   │
                │ - Query State     │   │ - (deploy)        │   │ - Deploy          │
                │ - Reactivity      │   │ - (call)          │   │                   │
                │ - Data Streams    │   │ - (query-state)   │   │                   │
                └───────────────────┘   └───────────────────┘   └───────────────────┘
```

### Current Agents

| Agent | Chain | Status | Description |
|-------|-------|--------|-------------|
| **Somnia Agent** | [Somnia](https://somnia.network) | Active | High-performance EVM L1 (1M+ TPS) |
| **Midnight Agent** | [Midnight](https://midnight.network) | Active | Privacy-focused blockchain with Compact language |
| Sonic Agent | Sonic | Planned | - |

### Somnia Agent Skills

| Skill | Status | Description |
|-------|--------|-------------|
| `solidity-gen` | Active | Generate Solidity contracts optimized for Somnia gas model |
| `deploy` | Active | Prepare unsigned deployment transactions |
| `tx-status` | Active | Check transaction status on Somnia |
| `query-state` | Active | Query on-chain state (balances, contract calls) |
| `reactivity-setup` | Planned | Generate Somnia Reactivity code |
| `data-streams` | Planned | Generate Data Streams schemas |

## Quick Start

### Prerequisites

- Node.js 20+
- pnpm (or use npx)
- Podman (for containers)
- Google Cloud credentials (for Vertex AI)

### Installation

```bash
# Clone the repository
git clone https://github.com/dcentral-labs/onchain-agents.git
cd onchain-agents/coding-labs

# Install dependencies
make install

# Build all packages
make build
```

### Run Locally

```bash
# Start all services with hot reload (recommended for development)
./scripts/dev.sh run-all

# Check health of all services
make health

# Send a message to the agent
make send MSG="Create an ERC-20 token called TestCoin with symbol TST"
```

Then open http://localhost:3000 in your browser.

#### Run Modes

| Command | Frontend | Access URL | Use Case |
|---------|----------|------------|----------|
| `run-all` | Vite dev server | http://localhost:3000 | Development (hot reload) |
| `run-all-built` | Pre-built static | http://localhost:4097 | Production-like testing |
| `run-all-with-login` | Vite + login page | http://localhost:4098 | Dev with login flow |
| `run-all-with-login-built` | Built + login | http://localhost:4098 | Prod-like with login |

#### Service Ports

| Service | Port | Description |
|---------|------|-------------|
| Agent Registry | 4000 | Central directory of agents |
| Somnia Agent | 4001 | A2A server for Somnia blockchain |
| Midnight Agent | 4003 | A2A server for Midnight blockchain |
| OpenCode Backend | 4097 | API server with A2A plugin |
| OpenCode Frontend | 3000 | Vite dev server (in `run-all` mode) |
| Login Page | 4098 | dCoder landing page (optional) |

### Run with Containers

```bash
# Build and start all containers
make rebuild

# Start containers (no rebuild)
make up

# View logs
make logs

# Stop all containers
make down
```

| Container | Port | Description |
|-----------|------|-------------|
| agent-registry | 4000 | Central directory of agents |
| somnia-agent | 4001 | A2A server for Somnia blockchain |
| midnight-agent | 4003 | A2A server for Midnight blockchain |
| opencode-web | 3000 | Web UI with wallet integration |

#### When to Rebuild

| Scenario | Command |
|----------|---------|
| First time setup | `make rebuild` |
| Changed TypeScript code | `make rebuild` |
| Changed Containerfile | `make rebuild` |
| Changed compose.yaml | `make up` (restart only) |
| Changed config.toml | `make up` (env vars regenerated) |

#### GCloud Credentials

The compose.yaml mounts `~/.config/gcloud` into containers for Vertex AI access. Ensure you have run:

```bash
gcloud auth application-default login
```

#### Verify Containers

```bash
curl http://localhost:4000/health  # agent-registry
curl http://localhost:4001/health  # somnia-agent
curl http://localhost:3000/global/health  # opencode-web

# Test somnia-agent skill
./scripts/a2a.sh send "Create a simple counter contract"
```

## Development

### Project Structure

```
coding-labs/
├── Makefile                    # All common operations
├── compose.yaml                # Podman compose for local dev
├── .context.md                 # Session context (read between sessions)
│
├── scripts/                    # Modular shell scripts
│   ├── common.sh               # Shared utilities
│   ├── dev.sh                  # Development tasks
│   ├── test.sh                 # Testing
│   ├── container.sh            # Podman operations
│   └── a2a.sh                  # A2A agent interactions
│
├── packages/
│   ├── shared/                 # Shared types and utilities
│   │   └── src/
│   │       ├── types.ts        # Network configs, common types
│   │       ├── wallet/         # Wallet context types
│   │       └── llm/            # LLM config types
│   │
│   └── somnia-agent/           # Somnia chain agent
│       ├── SKILLS.md           # Agent skills documentation
│       ├── Containerfile       # Container build
│       └── src/
│           ├── index.ts        # Express server entry
│           ├── agent-card.ts   # A2A agent card
│           ├── executor.ts     # Request handler
│           └── skills/         # Skill implementations
│               └── solidity-gen.ts
│
└── opencode/                   # Forked OpenCode (branch: feature/a2a-wallet-integration)
    └── packages/
        ├── opencode/src/plugin/a2a/  # A2A plugin
        │   ├── agents.ts             # Agent registry
        │   ├── router.ts             # Intent routing
        │   └── index.ts              # Plugin with tools
        └── app/                      # Web frontend
            ├── config.toml           # Frontend configuration
            └── src/
                ├── lib/config.ts     # Config loader
                ├── context/wallet.tsx # Wallet context
                └── components/wallet-button.tsx
```

### Available Make Targets

```bash
make help  # Show all available targets
```

#### Local
| Target | Description |
|--------|-------------|
| `install` | Install dependencies |
| `clean` | Clean build artifacts and node_modules |
| `build` | Build all packages |
| `test` | Run all tests |
| `run` / `dev` | Run all services (registry + agent + opencode) |
| `lint` | Lint and format code |

#### Container
| Target | Description |
|--------|-------------|
| `rebuild` | Build and start all containers |
| `up` | Start containers (no rebuild) |
| `down` | Stop containers |
| `logs` | View container logs |
| `container-build` | Build images only |
| `container-clean` | Remove containers and images |

#### Cloud
| Target | Description |
|--------|-------------|
| `cloud-build` | Build for Cloud Run (stub) |
| `cloud-deploy` | Deploy to Cloud Run (stub) |

#### Utilities
| Target | Description |
|--------|-------------|
| `config` | Generate .env.generated from config.toml |
| `health` | Check health of all services |
| `send MSG="..."` | Send A2A message to agent |

### Adding a New Skill

1. Create skill file in `packages/somnia-agent/src/skills/`:

```typescript
// packages/somnia-agent/src/skills/my-skill.ts
import type { Message } from '@a2a-js/sdk';
import type { SkillEvent } from './index.js';

export async function* mySkill(
  userMessage: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Processing...' };
  
  // Your skill logic here
  
  yield { type: 'artifact', name: 'output.txt', content: 'Result' };
  yield { type: 'result', data: { success: true } };
}
```

2. Register in `packages/somnia-agent/src/skills/index.ts`:

```typescript
export const skillHandlers: Record<string, SkillHandler> = {
  'solidity-gen': generateSolidity,
  'my-skill': mySkill,  // Add here
};
```

3. Add to agent card in `packages/somnia-agent/src/agent-card.ts`

4. Document in `packages/somnia-agent/SKILLS.md`

### Adding a New Agent

See [ADDING-NEW-AGENT.md](./ADDING-NEW-AGENT.md) for a comprehensive step-by-step guide.

Quick overview:
1. Create new package: `packages/<chain>-agent/`
2. Copy structure from `somnia-agent` or `midnight-agent`
3. Create `SKILLS.md` with chain-specific LLM context
4. Add to `config.toml`, `compose.yaml`, and scripts
5. Update this README

## Testing

```bash
# Run all tests
make test
```

### Writing Tests

Tests are located alongside source files in `__tests__` directories:

```typescript
// packages/somnia-agent/src/__tests__/agent-card.test.ts
import { describe, it, expect } from 'vitest';
import { somniaAgentCard } from '../agent-card.js';

describe('somniaAgentCard', () => {
  it('should have required fields', () => {
    expect(somniaAgentCard.name).toBe('Somnia Agent');
    expect(somniaAgentCard.skills).toHaveLength(6);
  });
});
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SOMNIA_AGENT_PORT` | `4001` | Agent HTTP port |
| `SOMNIA_AGENT_HOST` | `localhost` | Agent host |
| `GOOGLE_CLOUD_PROJECT` | `kunal-scratch` | GCP project for Vertex AI |
| `GOOGLE_CLOUD_LOCATION` | `global` | GCP region |

### Centralized Configuration

All configuration is managed via `config.toml` at the project root:

```toml
# config.toml - services, agents, networks, LLM providers

[default.services.somnia-agent]
host = "localhost"
port = 4001

[default.llm.providers.vertex-gemini]
type = "vertex"
project = "kunal-scratch"
location = "us-central1"
model = "gemini-2.0-flash"
```

Run `make config` to generate `.env.generated` for containers.

### Vertex AI Setup

The agent uses Google Vertex AI (Gemini) for LLM capabilities. Ensure you have:

1. A GCP project with Vertex AI API enabled
2. Application default credentials configured:

```bash
gcloud auth application-default login
```

Or set `GOOGLE_APPLICATION_CREDENTIALS` to a service account key file.

## Session Context

The `.context.md` file maintains context between coding sessions. Read it at the start of each session to understand:

- Current project status
- Recent decisions and rationale
- Next steps

## Contributing

1. Read `.context.md` for current status
2. Create a feature branch
3. Make changes with tests
4. Run `make lint` and `make test`
5. Submit PR

## License

MIT

## Links

- [A2A Protocol](https://a2a-protocol.org)
- [A2A JS SDK](https://github.com/a2aproject/a2a-js)
- [Somnia Documentation](https://docs.somnia.network)
