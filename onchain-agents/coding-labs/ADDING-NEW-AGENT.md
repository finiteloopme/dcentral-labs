# Adding a New Agent to Coding Labs

This guide walks through adding a new blockchain agent to the Coding Labs multi-agent platform. We'll use the Midnight Agent as a reference implementation.

## Overview

Each agent in Coding Labs is:
- A TypeScript A2A server in `packages/<chain>-agent/`
- Registered in `config.toml` for discovery
- Added to `compose.yaml` for container deployment
- Included in build scripts for development

## Step-by-Step Guide

### 1. Create the Agent Package

Create a new directory under `packages/`:

```bash
mkdir -p packages/<chain>-agent/src/skills
```

#### 1.1 package.json

```json
{
  "name": "@coding-labs/<chain>-agent",
  "version": "0.1.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/index.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@a2a-js/sdk": "^0.3.10",
    "@genkit-ai/vertexai": "^1.8.0",
    "genkit": "^1.8.0"
  },
  "devDependencies": {
    "tsx": "^4.7.0",
    "typescript": "^5.7.3"
  }
}
```

**Note:** Only include chain-specific SDKs. For EVM chains, add `viem`. For non-EVM chains like Midnight, use the chain's native SDK.

#### 1.2 tsconfig.json

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

### 2. Create Source Files

#### 2.1 src/index.ts - A2A Server Entry Point

```typescript
import { A2AServer, InMemoryTaskStore } from '@a2a-js/sdk';
import { agentCard } from './agent-card.js';
import { AgentExecutor } from './executor.js';

const PORT = parseInt(process.env.<CHAIN>_AGENT_PORT || '400X', 10);
const HOST = process.env.<CHAIN>_AGENT_HOST || '0.0.0.0';

async function main() {
  const taskStore = new InMemoryTaskStore();
  const executor = new AgentExecutor();

  const server = new A2AServer({
    port: PORT,
    host: HOST,
    agentCard,
    taskStore,
    taskHandler: executor,
  });

  // Health endpoint
  server.app.get('/health', (_, res) => {
    res.json({ status: 'ok', agent: '<chain>-agent', timestamp: new Date().toISOString() });
  });

  await server.start();
  console.log(`<Chain> Agent running at http://${HOST}:${PORT}`);
}

main().catch(console.error);
```

#### 2.2 src/agent-card.ts - Agent Definition

```typescript
import type { AgentCard } from '@a2a-js/sdk';

export const agentCard: AgentCard = {
  name: '<Chain> Agent',
  description: 'AI-powered assistant for <Chain> blockchain development',
  url: process.env.<CHAIN>_AGENT_URL || `http://localhost:400X`,
  version: '0.1.0',
  capabilities: {
    streaming: true,
    pushNotifications: false,
  },
  skills: [
    {
      id: '<skill-id>',
      name: '<Skill Name>',
      description: 'Description of what this skill does',
      tags: ['<chain>', '<category>'],
      examples: [
        'Example prompt 1',
        'Example prompt 2',
      ],
    },
    // Add more skills...
  ],
  defaultInputModes: ['text'],
  defaultOutputModes: ['text'],
};
```

#### 2.3 src/executor.ts - Request Handler

```typescript
import type { AgentExecutor as IAgentExecutor, Message, TaskYieldUpdate } from '@a2a-js/sdk';
import { detectSkill, skillHandlers } from './skills/index.js';

export class AgentExecutor implements IAgentExecutor {
  async *execute(message: Message): AsyncGenerator<TaskYieldUpdate, void, unknown> {
    // Extract text from message
    const textPart = message.parts.find((p): p is { kind: 'text'; text: string } => p.kind === 'text');
    const userText = textPart?.text || '';

    // Detect skill
    const skillId = detectSkill(userText);
    const handler = skillHandlers[skillId];

    if (!handler) {
      yield {
        state: 'failed',
        message: {
          role: 'agent',
          parts: [{ kind: 'text', text: `Unknown skill: ${skillId}` }],
        },
      };
      return;
    }

    // Execute skill
    for await (const event of handler(message)) {
      if (event.type === 'status') {
        yield { state: 'working', message: { role: 'agent', parts: [{ kind: 'text', text: event.message }] } };
      } else if (event.type === 'artifact') {
        yield { state: 'working', artifacts: [{ name: event.name, parts: [{ kind: 'text', text: event.content }] }] };
      } else if (event.type === 'result') {
        yield {
          state: 'completed',
          message: { role: 'agent', parts: [{ kind: 'text', text: JSON.stringify(event.data, null, 2) }] },
        };
      }
    }
  }
}
```

#### 2.4 src/genkit.ts - LLM Initialization

```typescript
import { genkit } from 'genkit';
import { vertexAI } from '@genkit-ai/vertexai';

const project = process.env.<CHAIN>_AGENT_LLM_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || 'kunal-scratch';
const location = process.env.<CHAIN>_AGENT_LLM_LOCATION || process.env.GOOGLE_CLOUD_LOCATION || 'us-central1';

export const ai = genkit({
  plugins: [
    vertexAI({
      projectId: project,
      location: location,
    }),
  ],
});

export const defaultModel = process.env.<CHAIN>_AGENT_LLM_MODEL || 'gemini-2.0-flash';

console.log(`[genkit] Configured Vertex AI: project=${project}, location=${location}, model=${defaultModel}`);
```

#### 2.5 src/skills/index.ts - Skill Registry

```typescript
import type { Message } from '@a2a-js/sdk';
import { mySkill } from './my-skill.js';

export interface SkillEvent {
  type: 'status' | 'artifact' | 'result';
  message?: string;
  name?: string;
  content?: string;
  data?: unknown;
}

export type SkillHandler = (message: Message) => AsyncGenerator<SkillEvent, void, unknown>;

export const skillHandlers: Record<string, SkillHandler> = {
  '<skill-id>': mySkill,
  // Add more skills here
};

export function detectSkill(text: string): string {
  const lower = text.toLowerCase();
  
  // Skill detection logic
  if (lower.includes('keyword')) return '<skill-id>';
  
  return '<default-skill-id>';
}
```

#### 2.6 src/skills/my-skill.ts - Skill Implementation

```typescript
import type { Message } from '@a2a-js/sdk';
import type { SkillEvent } from './index.js';
import { ai, defaultModel } from '../genkit.js';

export async function* mySkill(message: Message): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Processing your request...' };

  const textPart = message.parts.find((p): p is { kind: 'text'; text: string } => p.kind === 'text');
  const userText = textPart?.text || '';

  // Call LLM
  const result = await ai.generate({
    model: `vertexai/${defaultModel}`,
    prompt: `Your prompt here: ${userText}`,
  });

  const response = result.text;

  yield { type: 'artifact', name: 'output.txt', content: response };
  yield { type: 'result', data: { success: true } };
}
```

### 3. Create SKILLS.md - LLM Context Document

Create `packages/<chain>-agent/SKILLS.md` with comprehensive documentation for the LLM:

```markdown
# <Chain> Agent Skills Reference

This document provides context for the LLM to generate accurate code.

## Language/Framework Reference

[Include syntax, types, examples, common patterns, etc.]

## Best Practices

[Include optimization tips, security considerations, etc.]

## Example Code

[Include working examples the LLM can reference]
```

This file is loaded as context when the LLM generates code. Make it comprehensive (~200-500 lines).

### 4. Create Containerfile

```dockerfile
# Build stage
FROM node:20-slim AS builder
WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@9

# Copy workspace files
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY packages/shared/package.json packages/shared/
COPY packages/<chain>-agent/package.json packages/<chain>-agent/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source
COPY packages/shared packages/shared
COPY packages/<chain>-agent packages/<chain>-agent

# Build
RUN pnpm --filter @coding-labs/shared build
RUN pnpm --filter @coding-labs/<chain>-agent build

# Runtime stage
FROM node:20-slim
WORKDIR /app

COPY --from=builder /app/packages/<chain>-agent/dist ./dist
COPY --from=builder /app/packages/<chain>-agent/package.json ./
COPY --from=builder /app/node_modules ./node_modules

# Copy SKILLS.md for LLM context
COPY packages/<chain>-agent/SKILLS.md ./SKILLS.md

ENV NODE_ENV=production
EXPOSE 400X

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:400X/health || exit 1

CMD ["node", "dist/index.js"]
```

### 5. Update config.toml

Add the agent to the configuration:

```toml
# Agent configuration
[default.agents.<chain>]
enabled = true
host = "localhost"
port = 400X

# Container/Cloud URL override
[production.agents.<chain>]
url = "http://<chain>-agent:400X"

# LLM assignment (optional, defaults to default provider)
[default.llm.components]
<chain>-agent = "vertex-gemini"

# Network endpoints (if applicable)
[default.networks.<chain>]
testnet = "https://testnet-rpc.<chain>.network"
mainnet = "https://mainnet-rpc.<chain>.network"
```

### 6. Update compose.yaml

Add the agent service:

```yaml
services:
  <chain>-agent:
    build:
      context: .
      dockerfile: packages/<chain>-agent/Containerfile
    container_name: <chain>-agent
    ports:
      - "400X:400X"
    environment:
      - NODE_ENV=production
      - <CHAIN>_AGENT_PORT=400X
      - <CHAIN>_AGENT_HOST=0.0.0.0
      - GOOGLE_APPLICATION_CREDENTIALS=/creds/application_default_credentials.json
    volumes:
      - ${HOME}/.config/gcloud:/creds:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:400X/health"]
      interval: 30s
      timeout: 3s
      start_period: 10s
      retries: 3
    restart: unless-stopped
```

### 7. Update scripts/common.sh

Add fallback port configuration:

```bash
readonly <CHAIN>_AGENT_PORT="${<CHAIN>_AGENT_PORT:-400X}"
readonly <CHAIN>_AGENT_HOST="${<CHAIN>_AGENT_HOST:-localhost}"
```

Update `get_agent_url()` function:

```bash
get_agent_url() {
  local agent_id="${1:-$DEFAULT_AGENT}"
  
  # ... existing code ...
  
  case "$agent_id" in
    somnia)
      echo "http://${SOMNIA_AGENT_HOST}:${SOMNIA_AGENT_PORT}"
      ;;
    <chain>)
      echo "http://${<CHAIN>_AGENT_HOST}:${<CHAIN>_AGENT_PORT}"
      ;;
    # ... other agents ...
  esac
}
```

Update `list_agents()` fallback:

```bash
list_agents() {
  curl -s "${AGENT_REGISTRY_URL}/agents" 2>/dev/null | jq -r '.agents[] | "\(.id): \(.url)"' 2>/dev/null || {
    log_warn "Could not reach registry, using static agent list"
    echo "somnia: http://${SOMNIA_AGENT_HOST}:${SOMNIA_AGENT_PORT}"
    echo "<chain>: http://${<CHAIN>_AGENT_HOST}:${<CHAIN>_AGENT_PORT}"
  }
}
```

### 8. Update scripts/dev.sh

Add the agent to build, typecheck, clean, and run commands:

```bash
cmd_build() {
  log_header "Building all packages"
  run_pnpm --filter @coding-labs/shared build
  run_pnpm --filter @coding-labs/somnia-agent build
  run_pnpm --filter @coding-labs/<chain>-agent build  # ADD THIS
  log_success "Build complete"
}

cmd_typecheck() {
  log_header "Running TypeScript type checking"
  run_pnpm --filter @coding-labs/shared typecheck
  run_pnpm --filter @coding-labs/somnia-agent typecheck
  run_pnpm --filter @coding-labs/<chain>-agent typecheck  # ADD THIS
  log_success "Type checking passed"
}

cmd_run_all() {
  # Update npx concurrently to include new agent
  npx concurrently \
    --names "registry,somnia,<chain>,opencode" \
    --prefix-colors "blue,green,magenta,yellow" \
    --prefix "[{name}]" \
    --kill-others-on-fail \
    "cd packages/agent-registry && npx tsx src/index.ts" \
    "cd packages/somnia-agent && npx tsx src/index.ts" \
    "cd packages/<chain>-agent && npx tsx src/index.ts" \  # ADD THIS
    "cd opencode && bun run dev -- web --hostname 0.0.0.0 --port 4097"
}

cmd_clean() {
  log_header "Cleaning build artifacts"
  rm -rf packages/shared/dist
  rm -rf packages/somnia-agent/dist
  rm -rf packages/<chain>-agent/dist  # ADD THIS
  rm -rf node_modules/.cache
  log_success "Clean complete"
}

cmd_clean_all() {
  log_header "Cleaning all (including node_modules)"
  cmd_clean
  rm -rf node_modules
  rm -rf packages/shared/node_modules
  rm -rf packages/somnia-agent/node_modules
  rm -rf packages/<chain>-agent/node_modules  # ADD THIS
  log_success "Full clean complete"
}
```

### 9. Update scripts/a2a.sh (Optional)

Add the agent to the usage examples:

```bash
show_usage "a2a.sh" "
  ...
Environment Variables:
  AGENT         Target agent (default: somnia, options: somnia, <chain>)

Examples:
  ./scripts/a2a.sh health                          # Check somnia agent
  AGENT=<chain> ./scripts/a2a.sh health            # Check <chain> agent
  AGENT=<chain> ./scripts/a2a.sh send \"Your prompt\""
```

### 10. Build and Test

```bash
# Install dependencies
pnpm install

# Build
pnpm --filter @coding-labs/<chain>-agent build

# Run locally
pnpm --filter @coding-labs/<chain>-agent dev

# Test health endpoint
curl http://localhost:400X/health

# Test with a2a.sh
AGENT=<chain> ./scripts/a2a.sh health
AGENT=<chain> ./scripts/a2a.sh send "Your test prompt"

# Run all services together
./scripts/dev.sh run-all
```

### 11. Update Documentation

1. **README.md** - Add agent to the architecture diagram and agent table
2. **.context.md** - Document the session where the agent was added
3. **packages/<chain>-agent/README.md** (optional) - Agent-specific documentation

## Port Allocation

| Agent | Port |
|-------|------|
| Agent Registry | 4000 |
| Somnia Agent | 4001 |
| Sonic Agent | 4002 |
| Midnight Agent | 4003 |
| Next Agent | 4004 |

## File Checklist

```
packages/<chain>-agent/
├── package.json           ✅ Dependencies and scripts
├── tsconfig.json          ✅ Extends base config
├── Containerfile          ✅ Multi-stage container build
├── SKILLS.md              ✅ LLM context document
├── <CHAIN>-AGENT.md       ✅ Human documentation (optional)
└── src/
    ├── index.ts           ✅ A2A server entry point
    ├── agent-card.ts      ✅ Agent card definition
    ├── executor.ts        ✅ Request handler
    ├── genkit.ts          ✅ LLM initialization
    └── skills/
        ├── index.ts       ✅ Skill registry
        └── <skill>.ts     ✅ Skill implementation(s)

config.toml                ✅ Agent registration
compose.yaml               ✅ Container service block
scripts/common.sh          ✅ Fallback port config
scripts/dev.sh             ✅ Build/run/clean commands
scripts/a2a.sh             ✅ Usage examples (optional)
README.md                  ✅ Architecture diagram update
.context.md                ✅ Session documentation
```

## Example: Midnight Agent

The Midnight Agent implementation can be found at `packages/midnight-agent/`. Key differences from EVM agents:

1. **No viem** - Midnight is not EVM-compatible
2. **Compact language** - Uses Midnight's purpose-built DSL instead of Solidity
3. **Midnight.js SDK** - Uses `@midnight-ntwrk/*` packages
4. **SKILLS.md** - Contains comprehensive Compact language reference (~400 lines)

Refer to `packages/midnight-agent/MIDNIGHT-AGENT.md` for Midnight-specific documentation including version compatibility matrix.
