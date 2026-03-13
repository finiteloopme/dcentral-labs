#!/bin/bash

# Configuration
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
REPO_NAME="rust-agents"
IMAGE_NAME="blockchain-a2a-agent"

echo "🚀 Starting environment setup for $IMAGE_NAME..."

# 1. Create the Dockerfile
cat <<EOF > Dockerfile
# Build Stage
FROM rust:1.75-slim as builder
WORKDIR /app
COPY . .
RUN cargo build --release

# Runtime Stage
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/blockchain-a2a-agent .
EXPOSE 8080
CMD ["./blockchain-a2a-agent"]
EOF

# 2. Generate the Markdown Guide
cat <<EOF > QUICKSTART.md
# Blockchain A2A Agent Quickstart

This agent provides real-time block information for Bitcoin, Ethereum, and Solana via the **Agent-to-Agent (A2A)** protocol.

## Architecture
The agent is built in Rust using Axum and is designed to be called by Vertex AI Studio as a peer agent.



## Deployment Steps

### 1. Create Artifact Registry
\`\`\`bash
gcloud artifacts repositories create $REPO_NAME \\
    --repository-format=docker \\
    --location=$REGION \\
    --description="Rust-based AI Agents"
\`\`\`

### 2. Build and Push Container
\`\`\`bash
gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME .
\`\`\`

### 3. Deploy to Cloud Run
\`\`\`bash
gcloud run deploy $IMAGE_NAME \\
    --image $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME \\
    --platform managed \\
    --region $REGION \\
    --allow-unauthenticated
\`\`\`

## Vertex AI Studio Integration
1. Copy the **Service URL** from the Cloud Run deployment.
2. In Vertex AI Studio (Agent Builder), create a new **Tool**.
3. Set the type to **OpenAPI/Remote Agent**.
4. Provide the URL: \`<YOUR_CLOUD_RUN_URL>/.well-known/agent.json\`.
EOF

echo "✅ Dockerfile and QUICKSTART.md have been created."
echo "👉 Next step: Run the 'gcloud' commands inside QUICKSTART.md to deploy."
