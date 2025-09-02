# MCP EVM

This project contains a Model-Context-Protocol (MCP) server and an AI agent to interact with decentralized exchanges (DEX) and DeFi protocols on Ethereum.

## Project Structure

- `agent/`: Contains the AI agent implementation.
- `server/`: Contains the MCP server implementation in Rust.
- `Makefile`: Contains commands for building, running, and deploying the project.
- `cloudbuild.yaml`: Google Cloud Build configuration for remote builds.
- `cloudrun.yaml`: Google Cloud Run configuration for remote deployment.

## Prerequisites

- Rust and Cargo
- Google Cloud SDK

## Local Development

### Build

```bash
make build
```

### Run

```bash
make run
```

## Remote Deployment

### Build

```bash
gcloud builds submit --config cloudbuild.yaml
```

### Deploy

```bash
gcloud run deploy --config cloudrun.yaml
```
