# Blockchain A2A Agent Quickstart

This agent provides real-time block information for Bitcoin, Ethereum, and Solana via the **Agent-to-Agent (A2A)** protocol.

## Architecture

The agent is built in Rust using Axum and is designed to be called by Vertex AI Studio as a peer agent.

## Deployment Steps

### 1. Create Artifact Registry

```bash
gcloud artifacts repositories create rust-agents \
    --repository-format=docker \
    --location=us-central1 \
    --description="Rust-based AI Agents"
```

### 2. Build and Push Container

```bash
gcloud builds submit --tag us-central1-docker.pkg.dev/sol-grpc/rust-agents/blockchain-a2a-agent .
```

### 3. Deploy to Cloud Run

```bash
gcloud run deploy blockchain-a2a-agent \
    --image us-central1-docker.pkg.dev/sol-grpc/rust-agents/blockchain-a2a-agent \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated
```

## Vertex AI Studio Integration

1. Copy the **Service URL** from the Cloud Run deployment.
2. In Vertex AI Studio (Agent Builder), create a new **Tool**.
3. Set the type to **OpenAPI/Remote Agent**.
4. Provide the URL: `<YOUR_CLOUD_RUN_URL>/.well-known/agent.json`.

## Testing your Working Agent Locally

1. Run the agent: \`cargo run\`
2. In a new terminal, simulate an A2A call:

```bash
curl -X POST http://localhost:8080/v1/messages \\
  -H "Content-Type: application/json" \\
  -d '{"jsonrpc":"2.0","id":"123","params":{"message":{"parts":[{"text":"latest blocks"}]}}}'
```
