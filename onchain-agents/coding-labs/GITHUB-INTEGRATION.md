# GitHub Integration Plan

> **Status**: Planning  
> **Created**: 2026-02-18  
> **Last Updated**: 2026-02-18

## Overview

Integrate GitHub with the dCoder platform to allow users to save, list, and load their smart contract projects. All generated code is stored in a public monorepo (`finiteloopme/dcoder`) with each user getting their own project folders.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           User Request Flow                               │
│                                                                          │
│  "Create a counter contract and save to GitHub as my-counter"            │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          agent-registry                                   │
│                                                                          │
│  Routes to: midnight-agent (keywords: "counter", "contract")              │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          midnight-agent                                   │
│                                                                          │
│  1. compact-gen: Generate Compact code                                    │
│  2. compile: Compile via MCP                                              │
│  3. Detect "save to GitHub" intent                                        │
│  4. Delegate to github-agent via A2A                                      │
│     └─ Pass: userEmail, projectName, chain, artifacts (as file parts)   │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ A2A message/send
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          github-agent (NEW)                               │
│                          Port: 4004                                       │
│                                                                          │
│  Skills:                                                                  │
│  - git-save: Save artifacts to finiteloopme/dcoder                        │
│  - git-list: List projects in repo                                        │
│  - git-load: Load project from repo                                       │
│                                                                          │
│  Auth: Developer Connect Proxy (Workload Identity)                        │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Developer Connect Proxy
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    GitHub: finiteloopme/dcoder                            │
│                                                                          │
│  ├── alice-my-counter/                                                    │
│  │   ├── README.md                                                        │
│  │   ├── Makefile                                                         │
│  │   ├── .dcoder.json                                                     │
│  │   └── midnight/                                                        │
│  │       ├── contract.compact                                             │
│  │       └── compiled/                                                    │
│  └── bob-voting-app/                                                      │
│      └── ...                                                              │
└──────────────────────────────────────────────────────────────────────────┘
```

## Design Decisions

### 1. Project Naming Convention

**Format**: `{username}-{project-name}`

- Username derived from IAP email: `alice@gmail.com` → `alice`
- Project name sanitized: `My Counter!` → `my-counter`
- Collision handling: Append suffix (`-2`, `-3`) if exists

```typescript
function extractUsername(email: string): string {
  // alice@gmail.com → alice
  // bob.smith@example.com → bob-smith
  const local = email.split('@')[0];
  return local.replace(/[^a-z0-9]/gi, '-').toLowerCase();
}
```

### 2. User Email Source

The user email comes from:
- **Cloud Run (Production)**: IAP header `X-Goog-Authenticated-User-Email`
- **Local Development**: `gcloud config get account` or environment variable

### 3. Authentication

Uses **GCP Developer Connect** with Git Proxy:
- No PAT or GitHub App credentials to manage
- Cloud Run service account authenticates via Workload Identity
- Service account needs `roles/developerconnect.gitProxyUser` IAM role

### 4. Repository Structure

All projects stored in a single public monorepo:

```
finiteloopme/dcoder/
├── README.md                    # Repo overview
├── .dcoder/
│   └── projects.json            # Index of all projects
│
├── alice-counter/               # alice@gmail.com's "counter" project
│   ├── README.md
│   ├── Makefile
│   ├── .dcoder.json
│   └── midnight/
│       ├── contract.compact
│       └── compiled/
│
├── alice-voting-app/            # alice@gmail.com's "voting-app" project
│   └── ...
│
└── bob-nft-marketplace/         # bob@example.com's "nft-marketplace"
    ├── README.md
    ├── Makefile
    ├── .dcoder.json
    └── somnia/
        ├── NFT.sol
        └── abi/
```

## GitHub Agent

### Agent Card

```typescript
const githubAgentCard: AgentCard = {
  name: 'GitHub Agent',
  description: 'Save, list, and load smart contract projects from GitHub.',
  url: 'http://github-agent:8080/',
  version: '0.1.0',
  capabilities: {
    streaming: false,
    pushNotifications: false,
  },
  skills: [
    {
      id: 'git-save',
      name: 'Save to GitHub',
      description: 'Save contract code and artifacts to GitHub repository',
      tags: ['github', 'git', 'save', 'commit', 'push'],
      examples: [
        'Save this as my-counter',
        'Push to GitHub as voting-app',
        'Save my contract to GitHub'
      ]
    },
    {
      id: 'git-list',
      name: 'List Projects',
      description: 'List all saved projects in the repository',
      tags: ['github', 'git', 'list', 'projects'],
      examples: [
        'Show my projects',
        'List saved contracts',
        'What projects do I have?'
      ]
    },
    {
      id: 'git-load',
      name: 'Load Project',
      description: 'Load a previously saved project from GitHub',
      tags: ['github', 'git', 'load', 'open'],
      examples: [
        'Load my-counter',
        'Open voting-app project',
        'Get my token contract'
      ]
    }
  ]
};
```

### Package Structure

```
packages/github-agent/
├── package.json
├── tsconfig.json
├── Containerfile
├── src/
│   ├── index.ts                    # Entry point (Express + A2A)
│   ├── agent-card.ts               # Agent card definition
│   ├── executor.ts                 # Main executor
│   ├── skills/
│   │   ├── index.ts                # Skill registry
│   │   ├── git-save.ts             # Save to GitHub
│   │   ├── git-list.ts             # List projects
│   │   └── git-load.ts             # Load project
│   ├── lib/
│   │   ├── developer-connect.ts    # Developer Connect proxy client
│   │   ├── repo-structure.ts       # Repo layout helpers
│   │   └── username.ts             # Email → username extraction
│   └── templates/
│       ├── readme.ts               # README.md template
│       └── makefile.ts             # Makefile template
```

## A2A Integration

### Message Format: Chain Agent → GitHub Agent

```typescript
// midnight-agent or somnia-agent calls github-agent
{
  message: {
    messageId: "uuid",
    role: "user",
    parts: [
      {
        type: "text",
        text: JSON.stringify({
          action: "git-save",
          userEmail: "alice@gmail.com",
          projectName: "my-counter",
          chain: "midnight",
          description: "Simple counter contract with increment circuit"
        })
      },
      // File parts with artifacts
      { 
        type: "file", 
        file: { 
          name: "contract.compact", 
          mimeType: "text/plain",
          bytes: "<base64-encoded-content>" 
        } 
      },
      { 
        type: "file", 
        file: { 
          name: "compiled/zkir/increment.zkir", 
          mimeType: "application/octet-stream",
          bytes: "<base64-encoded-content>" 
        } 
      },
      // ... more artifacts
    ]
  }
}
```

### Response Format: GitHub Agent → Chain Agent

```typescript
{
  result: {
    status: { state: "completed" },
    artifacts: [{
      artifactId: "github-result",
      name: "GitHub URL",
      parts: [{
        kind: "text",
        text: "https://github.com/finiteloopme/dcoder/tree/main/alice-my-counter"
      }]
    }]
  }
}
```

### Chain Agent Integration

Both `midnight-agent` and `somnia-agent` need to:

1. Detect "save to GitHub" intent in user message
2. Call `github-agent` via A2A with artifacts

```typescript
// In midnight-agent/src/executor.ts
import { A2AClient } from './a2a-client';

const GITHUB_AGENT_URL = process.env.GITHUB_AGENT_URL || 'http://github-agent:8080';

async function delegateToGitHub(
  userEmail: string,
  projectName: string,
  artifacts: SessionArtifact[],
  description: string
): Promise<string> {
  const client = new A2AClient(GITHUB_AGENT_URL);
  
  const response = await client.sendMessage({
    message: {
      messageId: crypto.randomUUID(),
      role: 'user',
      parts: [
        {
          type: 'text',
          text: JSON.stringify({
            action: 'git-save',
            userEmail,
            projectName,
            chain: 'midnight',
            description
          })
        },
        // Convert artifacts to file parts
        ...artifacts.map(a => ({
          type: 'file',
          file: {
            name: a.name,
            mimeType: 'application/octet-stream',
            bytes: Buffer.from(a.content).toString('base64')
          }
        }))
      ]
    }
  });
  
  // Extract GitHub URL from response
  const urlArtifact = response.result?.artifacts?.find(a => a.name === 'GitHub URL');
  return urlArtifact?.parts?.[0]?.text || '';
}
```

## Developer Connect Setup

### Why Developer Connect?

| Feature | PAT Approach | Developer Connect |
|---------|--------------|-------------------|
| Token management | Manual rotation | None - uses IAM |
| Auth type | Static PAT | Workload Identity |
| Access control | PAT scoped to repo | IAM roles |
| Audit logging | GitHub only | GCP + GitHub |

### Proxy URL Format

```
https://{REGION}-git.developerconnect.dev/{PROJECT}/{CONNECTION}/{REPO_LINK}
```

Example:
```
https://us-central1-git.developerconnect.dev/kunal-scratch/github-dcoder/dcoder
```

### Client Implementation

```typescript
// lib/developer-connect.ts
import { GoogleAuth } from 'google-auth-library';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const PROJECT_ID = process.env.DEVELOPER_CONNECT_PROJECT || 'kunal-scratch';
const REGION = process.env.DEVELOPER_CONNECT_REGION || 'us-central1';
const CONNECTION = process.env.DEVELOPER_CONNECT_CONNECTION || 'github-dcoder';
const REPO_LINK = process.env.DEVELOPER_CONNECT_REPO || 'dcoder';

function getProxyUrl(token: string): string {
  return `https://unused:${token}@${REGION}-git.developerconnect.dev/${PROJECT_ID}/${CONNECTION}/${REPO_LINK}`;
}

export async function cloneRepo(workDir: string, options?: { depth?: number }): Promise<void> {
  const auth = new GoogleAuth();
  const token = await auth.getAccessToken();
  
  const depthArg = options?.depth ? `--depth=${options.depth}` : '';
  const url = getProxyUrl(token);
  
  await execAsync(`git clone ${depthArg} ${url} ${workDir}`);
}

export async function gitPush(workDir: string): Promise<void> {
  const auth = new GoogleAuth();
  const token = await auth.getAccessToken();
  
  const url = getProxyUrl(token);
  
  await execAsync(`git remote set-url origin ${url}`, { cwd: workDir });
  await execAsync('git push', { cwd: workDir });
}
```

## Generated Files

### `.dcoder.json` (Project Metadata)

```json
{
  "name": "my-counter",
  "user": "alice",
  "email": "alice@gmail.com",
  "chain": "midnight",
  "created": "2026-02-18T19:30:00Z",
  "updated": "2026-02-18T19:30:00Z",
  "description": "Simple counter contract with increment circuit",
  "version": "1"
}
```

### `README.md` (Auto-Generated)

```markdown
# my-counter

> Generated by [dCoder](https://dcoder.example.com) on 2026-02-18

## Overview

Simple counter contract with increment circuit

## Chain

- **Network**: Midnight (Preview Testnet)
- **Language**: Compact v0.21

## Quick Start

\```bash
# Install dependencies
make install

# Compile the contract
make compile

# Deploy to Preview testnet
make deploy
\```

## Project Structure

\```
my-counter/
├── midnight/
│   ├── contract.compact    # Main contract source
│   └── compiled/           # Compiled artifacts (ZK circuits, keys)
├── Makefile                # Build & deploy commands
├── .dcoder.json            # Project metadata
└── README.md               # This file
\```

## Contract

### Circuits

| Circuit | Description |
|---------|-------------|
| `increment` | Increments the counter by 1 |

### Ledger State

| Field | Type | Visibility |
|-------|------|------------|
| `counter` | `Counter` | Public |

---

*Generated by dCoder • [View on GitHub](https://github.com/finiteloopme/dcoder/tree/main/alice-my-counter)*
```

### `Makefile` (Simplified)

```makefile
# my-counter - Makefile
# Generated by dCoder

.PHONY: help install compile deploy clean

NETWORK ?= preview

help:
	@echo "Available commands:"
	@echo "  make install  - Install Compact compiler"
	@echo "  make compile  - Compile the contract"
	@echo "  make deploy   - Deploy to $(NETWORK) network"
	@echo "  make clean    - Remove compiled artifacts"

install:
	@echo "Installing Compact devtools..."
	@curl --proto '=https' --tlsv1.2 -LsSf https://github.com/midnightntwrk/compact/releases/download/compact-v0.4.0/compact-installer.sh | sh
	@compact update

compile:
	@cd midnight && compactc contract.compact --output compiled/

deploy:
	@echo "Deploy via dCoder or use Midnight.js SDK"
	@echo "See: https://docs.midnight.network/develop/tutorial/deploy"

clean:
	@rm -rf midnight/compiled/*
```

## Service Configuration

### Port Assignment

| Service | Port |
|---------|------|
| agent-registry | 4000 |
| somnia-agent | 4001 |
| sonic-agent | 4002 |
| midnight-agent | 4003 |
| **github-agent** | **4004** |
| midnight-mcp | 4010 |

### config.toml

```toml
[services.github-agent]
host = "localhost"
port = 4004

[default.llm.components]
github-agent = "vertex-gemini"
```

### compose.yaml

```yaml
github-agent:
  build:
    context: .
    dockerfile: packages/github-agent/Containerfile
  ports:
    - "${GITHUB_AGENT_PORT:-4004}:8080"
  environment:
    - NODE_ENV=development
    - GITHUB_AGENT_PORT=8080
    - GITHUB_AGENT_HOST=0.0.0.0
    - DEVELOPER_CONNECT_PROJECT=kunal-scratch
    - DEVELOPER_CONNECT_REGION=us-central1
    - DEVELOPER_CONNECT_CONNECTION=github-dcoder
    - DEVELOPER_CONNECT_REPO=dcoder
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### cloudbuild.yaml (addition)

```yaml
# Build github-agent
- name: 'gcr.io/cloud-builders/docker'
  id: 'build-github'
  waitFor: ['-']
  args:
    - 'build'
    - '-t'
    - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/github-agent:${_TAG}'
    - '-f'
    - 'packages/github-agent/Containerfile'
    - '.'

# Deploy github-agent
- name: 'gcr.io/cloud-builders/gcloud'
  id: 'deploy-github'
  waitFor: ['push-github']
  args:
    - 'run'
    - 'deploy'
    - 'github-agent'
    - '--image=${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/github-agent:${_TAG}'
    - '--region=${_REGION}'
    - '--platform=managed'
    - '--allow-unauthenticated'
    - '--port=8080'
    - '--memory=512Mi'
    - '--set-env-vars=NODE_ENV=production,DEVELOPER_CONNECT_PROJECT=${PROJECT_ID},DEVELOPER_CONNECT_REGION=${_REGION},DEVELOPER_CONNECT_CONNECTION=github-dcoder,DEVELOPER_CONNECT_REPO=dcoder'
```

## Prerequisites

### 1. Create GitHub Repository

Create `finiteloopme/dcoder` on GitHub:
- Public repository
- Initialize with README
- Add topics: `dcoder`, `smart-contracts`

### 2. Enable Developer Connect API

```bash
gcloud services enable developerconnect.googleapis.com --project=kunal-scratch
```

### 3. Create Developer Connect Connection

```bash
# Create connection (requires browser auth)
gcloud developer-connect connections create github-dcoder \
  --location=us-central1 \
  --github-config-app=DEVELOPER-CONNECT \
  --git-proxy-config-enabled \
  --project=kunal-scratch

# Get authorization URL
gcloud developer-connect connections describe github-dcoder \
  --location=us-central1 \
  --project=kunal-scratch

# Complete browser authorization, then link repository
gcloud developer-connect connections git-repository-links create dcoder \
  --clone-uri=https://github.com/finiteloopme/dcoder.git \
  --connection=github-dcoder \
  --location=us-central1 \
  --project=kunal-scratch
```

### 4. Grant IAM Permissions

```bash
PROJECT_NUMBER=$(gcloud projects describe kunal-scratch --format='value(projectNumber)')

# Grant Git Proxy User role to Cloud Run default SA
gcloud projects add-iam-policy-binding kunal-scratch \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/developerconnect.gitProxyUser"
```

## Implementation Checklist

### Prerequisites (User)

- [ ] Create `finiteloopme/dcoder` repo on GitHub (public)
- [ ] Enable Developer Connect API
- [ ] Create Developer Connect connection (browser auth required)
- [ ] Link repository to connection

### Implementation

| # | Task | Status |
|---|------|--------|
| 1 | Create `packages/github-agent/` scaffolding | ⬜ |
| 2 | Implement agent entry point + agent card | ⬜ |
| 3 | Implement executor | ⬜ |
| 4 | Implement Developer Connect client | ⬜ |
| 5 | Implement `git-save` skill | ⬜ |
| 6 | Implement `git-list` skill | ⬜ |
| 7 | Implement `git-load` skill | ⬜ |
| 8 | Create README/Makefile templates | ⬜ |
| 9 | Create Containerfile | ⬜ |
| 10 | Update config.toml | ⬜ |
| 11 | Update compose.yaml | ⬜ |
| 12 | Update cloudbuild.yaml | ⬜ |
| 13 | Add A2A client to midnight-agent | ⬜ |
| 14 | Add A2A client to somnia-agent | ⬜ |
| 15 | Update agent-registry | ⬜ |
| 16 | Grant IAM permissions | ⬜ |
| 17 | Test locally | ⬜ |
| 18 | Deploy to Cloud Run | ⬜ |

**Estimated time**: ~7-8 hours

## Future Enhancements (Parked)

1. **Chain-specific Makefiles**: Different targets for Midnight (Compact) vs Somnia (Hardhat/Foundry)
2. **Additional quickstart files**: `package.json`, `.gitignore`, deploy scripts
3. **Project deletion**: Allow users to delete their projects
4. **Project updates**: Handle saving to existing project (overwrite vs version)
5. **GitLab/Bitbucket support**: Extend to other Git providers
6. **Private repos**: Support for private repositories with user auth

---

*Document created: 2026-02-18*
