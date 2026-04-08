# Security Agent

A2A agent for **smart contract security auditing**, **vulnerability scanning**, and **protocol risk assessment** across Solidity (EVM) and Compact (Midnight) ecosystems.

## Overview

The Security Agent provides AI-powered security analysis for smart contracts and blockchain protocols. Unlike chain-specific agents (somnia-agent, sonic-agent, midnight-agent), the Security Agent operates cross-chain and does not interact with any blockchain directly — it is purely analytical, powered by LLM via Vertex AI.

**Key characteristics:**
- **LLM-powered analysis only** — no external scanning tools (Slither, Mythril)
- **No MCP dependency** — unlike chain agents, this agent is analysis-only
- **Cross-chain** — supports Solidity (Somnia/Sonic) and Compact (Midnight)
- **Dual scope** — code-level smart contract audit + protocol/ecosystem risk assessment

## Skills

| Skill | Status | Description |
|-------|--------|-------------|
| `audit-contract` | **Active** | Comprehensive security audit of Solidity or Compact contracts |
| `scan-vulnerabilities` | **Active** | Quick targeted vulnerability pattern scan |
| `assess-risk` | **Active** | Protocol/ecosystem risk assessment (not code-level) |
| `explain-finding` | **Active** | Deep-dive explanation of a specific vulnerability type |
| `compare-protocols` | **Active** | Compare security posture of different protocols/chains |

### audit-contract

The primary skill. Accepts Solidity or Compact contract code and performs a comprehensive security audit with severity-rated findings, impact analysis, and remediation guidance.

**Example prompts:**
- "Audit this Solidity contract for security vulnerabilities"
- "Review my Compact contract for ZK-specific issues"
- "Check this ERC-20 token for common exploits"

**Output:** `audit-report.md` + `audit-report.json` artifacts

### scan-vulnerabilities

Quick targeted scan for known vulnerability patterns. Faster and less comprehensive than a full audit — produces a checklist-style report.

**Example prompts:**
- "Scan this contract for reentrancy bugs"
- "Check for common vulnerability patterns"
- "Find potential security issues in this code"

**Output:** `vulnerability-scan.md` artifact

### assess-risk

Protocol/ecosystem-level risk assessment. Does NOT analyze code — evaluates a protocol's security posture across dimensions like maturity, audit history, governance, and incident history.

**Example prompts:**
- "What are the security risks of using Somnia?"
- "Assess the risk profile of the Midnight protocol"
- "How safe is the Sonic ecosystem for DeFi?"

**Output:** `risk-assessment.md` + `risk-assessment.json` artifacts

### explain-finding

Educational deep-dive on a specific vulnerability type. Includes real-world examples, step-by-step attack scenarios, vulnerable/fixed code examples, and references.

**Example prompts:**
- "Explain reentrancy attacks with examples"
- "What is a flash loan attack and how to prevent it?"
- "Deep dive into Compact witness validation vulnerabilities"

**Output:** `finding-explanation.md` artifact

### compare-protocols

Compare the security characteristics of different blockchain protocols or chains across multiple dimensions.

**Example prompts:**
- "Compare security of Somnia vs Sonic"
- "Which chain has better security guarantees: Midnight or Sonic?"
- "Compare the audit history of these protocols"

**Output:** `protocol-comparison.md` + `protocol-comparison.json` artifacts

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    security-agent                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Skills                                                 │  │
│  │  - audit-contract (LLM-powered code audit)            │  │
│  │  - scan-vulnerabilities (pattern-based scan)          │  │
│  │  - assess-risk (protocol risk assessment)             │  │
│  │  - explain-finding (vulnerability deep-dive)          │  │
│  │  - compare-protocols (comparative analysis)           │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │                                   │
│                    ┌─────┴─────┐                            │
│                    │ SKILLS.md │                            │
│                    │ (context) │                            │
│                    └─────┬─────┘                            │
│                          │                                   │
│                    ┌─────┴─────┐                            │
│                    │ Vertex AI │                            │
│                    │ (Claude)  │                            │
│                    └───────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

No external dependencies (no MCP servers, no blockchain nodes, no compilers).

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SECURITY_AGENT_HOST` | localhost | Server bind address |
| `SECURITY_AGENT_PORT` | 4006 | Server port |
| `SECURITY_AGENT_LLM_PROJECT` | kunal-scratch | GCP project for Vertex AI |
| `SECURITY_AGENT_LLM_LOCATION` | global | GCP region for Vertex AI |
| `SECURITY_AGENT_LLM_MODEL` | claude-opus-4-5 | LLM model ID |

### config.toml

```toml
[default.services.security-agent]
host = "localhost"
port = 4006

[default.agents.security]
name = "Security Agent"
description = "Security auditing, vulnerability scanning, and protocol risk assessment."
service = "security-agent"
chain_id = 0
keywords = ["security", "audit", "vulnerability", "risk", "exploit", "reentrancy", "scan", "safety", "assessment"]
enabled = true

[default.llm.components]
security-agent = "vertex-anthropic"
```

## Development

### Running Locally

```bash
# From project root
pnpm --filter @coding-labs/security-agent dev

# Or build and run
pnpm --filter @coding-labs/security-agent build
pnpm --filter @coding-labs/security-agent start
```

### Testing Endpoints

```bash
# Health check
curl http://localhost:4006/health

# Agent card
curl http://localhost:4006/.well-known/agent.json

# Send A2A message (audit a contract)
AGENT=security ./scripts/a2a.sh send "Audit this contract: pragma solidity ^0.8.0; contract Token { ... }"
```

### Type Checking

```bash
pnpm --filter @coding-labs/security-agent typecheck
```

### Building

```bash
pnpm --filter @coding-labs/security-agent build
```

## References

- [OWASP Smart Contract Top 10](https://owasp.org/www-project-smart-contract-top-10/)
- [SWC Registry](https://swcregistry.io/)
- [Solidity Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)
- [Midnight Docs](https://docs.midnight.network)
- [Compact Language Reference](https://docs.midnight.network/next/compact/reference/lang-ref)
