# Coding Labs

Multi-agent platform for on-chain development using the [A2A (Agent-to-Agent) protocol](https://a2a-protocol.org).

## Overview

Coding Labs provides AI agents specialized for blockchain development. Each agent understands chain-specific nuances, gas optimization patterns, and unique features.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│           Container: opencode-web (port 3000)                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    OpenCode Web                               │  │
│  │              (Primary User Interface)                         │  │
│  │                                                               │  │
│  │  - Browser-based coding session                               │  │
│  │  - Wallet connection (MetaMask / injected provider)           │  │
│  │  - A2A Client integrated                                      │  │
│  │  - Routes to chain agents based on user intent                │  │
│  └───────────────────────────┬───────────────────────────────────┘  │
└──────────────────────────────┼──────────────────────────────────────┘
                               │ A2A Protocol (HTTP+JSON)
          ┌────────────────────┼────────────────────────────────┐
          ▼                    ▼                                ▼
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│   Somnia Agent    │   │   Sonic Agent     │   │  Midnight Agent   │
│   (port 4001)     │   │   (future)        │   │  (future)         │
├───────────────────┤   ├───────────────────┤   ├───────────────────┤
│ - Solidity Gen    │   │ - Solidity Gen    │   │ - Compact Gen     │
│ - Deploy          │   │ - FeeM Optimize   │   │ - ZK Proofs       │
│ - Query State     │   │ - Deploy          │   │ - Privacy         │
│ - Reactivity      │   │                   │   │                   │
│ - Data Streams    │   │                   │   │                   │
└───────────────────┘   └───────────────────┘   └───────────────────┘
```

### Current Agents

| Agent | Chain | Status | Description |
|-------|-------|--------|-------------|
| **Somnia Agent** | [Somnia](https://somnia.network) | Active | High-performance EVM L1 (1M+ TPS) |
| Sonic Agent | Sonic | Planned | - |
| Midnight Agent | Midnight | Planned | Privacy-focused, Compact language |

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

### Run Locally (Agent Only)

```bash
# Start the agent in dev mode
make dev

# In another terminal, check health
make health

# View the agent card
make agent-card

# Send a message
make send MSG="Create an ERC-20 token called TestCoin with symbol TST"
```

### Run with OpenCode Web UI (Full Integration)

Run in 3 separate terminals:

```bash
# Terminal 1: Start Somnia Agent
make dev

# Terminal 2: Start OpenCode server (backend with A2A plugin)
make opencode-server

# Terminal 3: Start OpenCode frontend (web UI with wallet)
make opencode-frontend
```

Then open http://localhost:3000 in your browser.

| Service | Port | Description |
|---------|------|-------------|
| Somnia Agent | 4001 | A2A server for blockchain operations |
| OpenCode Server | 4097 | Backend API with A2A plugin |
| OpenCode Frontend | 3000 | Web UI with wallet integration |

### Run with Containers

```bash
# Build container image
make container-build

# Start container
make up

# View logs
make logs

# Stop container
make down
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

#### Development
| Target | Description |
|--------|-------------|
| `install` | Install dependencies |
| `build` | Build all packages |
| `dev` | Run agent in dev mode |
| `typecheck` | TypeScript type checking |
| `lint` | Run ESLint |
| `format` | Format with Prettier |
| `clean` | Clean build artifacts |

#### Testing
| Target | Description |
|--------|-------------|
| `test` | Run all tests |
| `test-unit` | Run unit tests |
| `test-coverage` | Run tests with coverage |
| `test-integration` | Run integration tests |

#### Containers
| Target | Description |
|--------|-------------|
| `container-build` | Build images |
| `up` | Start containers |
| `down` | Stop containers |
| `logs` | View logs |
| `shell` | Shell into container |

#### A2A Agent
| Target | Description |
|--------|-------------|
| `health` | Check agent health |
| `agent-card` | Show agent card |
| `skills` | List agent skills |
| `send MSG="..."` | Send message to agent |

#### OpenCode (Forked)
| Target | Description |
|--------|-------------|
| `opencode-server` | Run OpenCode backend (port 4097) |
| `opencode-frontend` | Run OpenCode web UI (port 3000) |
| `opencode-typecheck` | Typecheck OpenCode fork |

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

1. Create new package: `packages/<chain>-agent/`
2. Copy structure from `somnia-agent`
3. Update `SKILLS.md` with chain-specific capabilities
4. Add to `compose.yaml`
5. Update this README

## Testing

```bash
# Run all tests
make test

# Run unit tests in watch mode
make test-unit-watch

# Run with coverage
make test-coverage
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

### OpenCode Frontend Configuration

The frontend uses `config.toml` for configuration with environment-specific sections:

```toml
# opencode/packages/app/config.toml

[default.server]
host = "localhost"
port = 4097

[production.server]
host = "0.0.0.0"
port = 443
```

**Config resolution order** (later overrides earlier):
1. `config.toml` `[default]` section
2. `config.toml` `[env]` section (dev/test/production)
3. CLI environment variables

**Override via Makefile:**
```bash
# Change backend port
make opencode-server OPENCODE_PORT=4098
make opencode-frontend PORT=4098

# Switch environment
make opencode-frontend ENV=production
```

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
