# Blockchain A2A Agent — Quick Start

A Rust/Axum agent that exposes live blockchain data (BTC, ETH, SOL) via the
[A2A protocol](https://google.github.io/A2A/). Features AI-powered smart
routing using Google Gemini 3.0 Flash with graceful keyword fallback.

## Prerequisites

- **Rust** 1.85+ (edition 2024)
- **Google Cloud project** (optional — needed for LLM routing)

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `GOOGLE_CLOUD_PROJECT` | No | — | GCP project ID. Enables LLM routing via Vertex AI. |
| `VERTEX_LOCATION` | No | `us-central1` | Vertex AI region. |
| `GEMINI_MODEL` | No | `gemini-3.0-flash` | Gemini model to use for classification. |
| `AGENT_URL` | No | `http://0.0.0.0:8080` | Public URL for the agent card. |

> **Note:** The agent works without any GCP configuration. When
> `GOOGLE_CLOUD_PROJECT` is not set, it degrades gracefully to keyword-based
> routing.

## Build & Run

```bash
# Build
cd blockchain-a2a-agent
cargo build --release

# Run without LLM (keyword routing only)
cargo run

# Run with LLM routing
export GOOGLE_CLOUD_PROJECT="my-project-id"
cargo run
```

## Endpoints

### Discovery

```bash
curl http://localhost:8080/.well-known/agent.json | jq .
```

### Per-Network Endpoints

Each endpoint accepts an A2A JSON-RPC request and returns only the
requested network's data.

```bash
# Bitcoin block height
curl -X POST http://localhost:8080/v1/bitcoin \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"1","method":"message/send","params":{"message":{"role":"user","parts":[{"text":"block height"}]}}}'

# Ethereum block number
curl -X POST http://localhost:8080/v1/ethereum \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"2","method":"message/send","params":{"message":{"role":"user","parts":[{"text":"block number"}]}}}'

# Solana slot number
curl -X POST http://localhost:8080/v1/solana \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"3","method":"message/send","params":{"message":{"role":"user","parts":[{"text":"slot number"}]}}}'
```

### Smart Routing (LLM-powered)

The `/v1/messages` endpoint uses Gemini to classify which network(s) the
user is asking about, then fetches only the relevant data.

```bash
# Ask about a specific network — routes to Bitcoin only
curl -X POST http://localhost:8080/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"4","method":"message/send","params":{"message":{"role":"user","parts":[{"text":"What is the current Bitcoin block height?"}]}}}'

# Ask about multiple networks — routes to ETH + SOL
curl -X POST http://localhost:8080/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"5","method":"message/send","params":{"message":{"role":"user","parts":[{"text":"Compare Ethereum and Solana"}]}}}'

# General question — routes to all 3
curl -X POST http://localhost:8080/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"6","method":"message/send","params":{"message":{"role":"user","parts":[{"text":"Show me all block heights"}]}}}'
```

## Deploy to Cloud Run

```bash
# Build and deploy with LLM routing enabled
gcloud run deploy blockchain-a2a-agent \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project),VERTEX_LOCATION=us-central1"
```

## Architecture

```
POST /v1/messages
  │
  ├─ Gemini available? ──yes──> LLM classifies networks
  │                               │
  │                               ├─ Parse JSON {"networks": [...]}
  │                               │
  │                               └─ On error ──> keyword fallback
  │
  └─ No Gemini ──> keyword fallback
                     │
                     ├─ "btc" / "bitcoin"  → Bitcoin
                     ├─ "eth" / "ethereum" → Ethereum
                     ├─ "sol" / "solana"   → Solana
                     └─ no match           → all 3

POST /v1/bitcoin    → fetch_bitcoin()
POST /v1/ethereum   → fetch_ethereum()
POST /v1/solana     → fetch_solana()
```
