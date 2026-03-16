# Blockchain A2A Agent Quickstart

This agent provides real-time block information for Bitcoin, Ethereum, and Solana via the **Agent-to-Agent (A2A)** protocol.

## Architecture

The agent is built in Rust using Axum and is designed to be called by Vertex AI Studio as a peer agent. It supports two deployment runtimes:

| Runtime | Default | Description |
|---------|---------|-------------|
| **Vertex AI Prediction** | Yes | Native Vertex AI Studio integration via `gcloud ai models upload`. Query with `rawPredict`. |
| **Cloud Run** | No | Full A2A protocol support (all routes, Agent Card discovery). |

## Prerequisites

- [Rust 1.85+](https://www.rust-lang.org/tools/install)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- Authenticated: `gcloud auth login && gcloud auth application-default login`
- Project set: `gcloud config set project YOUR_PROJECT_ID`

## Local Development

```bash
cd blockchain-a2a-agent

# Run with LLM-powered smart routing
make run-llm

# Run with keyword fallback only (no GCP needed)
make run-keyword

# Test locally
curl -X POST http://localhost:8080/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"id":"1","params":{"message":{"parts":[{"text":"latest blocks"}]}}}'
```

## Deployment

### One-time setup: Create Artifact Registry

```bash
gcloud artifacts repositories create rust-agents \
    --repository-format=docker \
    --location=us-central1 \
    --description="Rust-based AI Agents"
```

### Deploy (Vertex AI — default)

```bash
cd blockchain-a2a-agent
make deploy
```

This runs `push` (Cloud Build) then `deploy-vertex-ai`, which:
1. Uploads the container as a Vertex AI model
2. Creates a Vertex AI endpoint
3. Deploys the model to the endpoint (~15-20 min)

Query the deployed agent:
```bash
ENDPOINT_ID=<from deploy output>
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://us-central1-aiplatform.googleapis.com/v1/projects/$(gcloud config get-value project)/locations/us-central1/endpoints/${ENDPOINT_ID}:rawPredict" \
  -d '{"jsonrpc":"2.0","id":"1","params":{"message":{"role":"user","parts":[{"text":"Bitcoin block height"}]}}}'
```

### Deploy (Cloud Run)

```bash
cd blockchain-a2a-agent
make deploy RUNTIME=cloud-run
```

The Agent Card URL is printed after deployment:
```
https://blockchain-a2a-agent-HASH.a.run.app/.well-known/agent.json
```

### Undeploy

```bash
make undeploy                    # Vertex AI (default)
make undeploy RUNTIME=cloud-run  # Cloud Run
```

## Vertex AI Studio Integration

### Via Vertex AI Prediction (automated)

After `make deploy`, the agent is already registered in Vertex AI's model registry and accessible via endpoints. No additional registration needed.

### Via Cloud Run (manual)

1. Deploy with `make deploy RUNTIME=cloud-run`
2. Copy the Agent Card URL from the output
3. In Vertex AI Studio > Agent Builder > Add Tool > Remote Agent
4. Paste the Agent Card URL

## Configuration

Override any variable via environment or command line:

```bash
make deploy RUNTIME=cloud-run REGION=europe-west1 GEMINI_MODEL=gemini-2.0-flash
```

| Variable | Default | Description |
|----------|---------|-------------|
| `RUNTIME` | `vertex-ai` | Deployment runtime: `vertex-ai` or `cloud-run` |
| `REGION` | `us-central1` | GCP region |
| `GEMINI_MODEL` | `gemini-3.1-flash-lite-preview` | Gemini model for LLM routing |
| `VERTEX_LOCATION` | `global` | Vertex AI model endpoint location |
| `MACHINE_TYPE` | `e2-standard-2` | VM type for Vertex AI Prediction |
| `MIN_REPLICAS` | `1` | Min replicas for Vertex AI |
| `MAX_REPLICAS` | `3` | Max replicas for Vertex AI |
