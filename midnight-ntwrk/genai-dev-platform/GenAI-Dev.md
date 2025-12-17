# Midnight GenAI Development Platform

## Overview

A cloud-native development environment for building applications on the Midnight blockchain network. The platform provides:

- **Cloud Workstations** - Browser-based VS Code (Code OSS) IDE
- **Compact Compiler** - Midnight's smart contract language toolchain
- **Midnight CLI** (`midnightctl`) - Project scaffolding, compilation, and service management
- **Cloud Run Services** - Managed Midnight node, proof server, and indexer

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Cloud Build                              │
│  - Builds container image → Artifact Registry                   │
│  - Runs Terraform → Deploys infrastructure                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Per-Cluster Resources                         │
│                    (labeled: cluster=<name>)                     │
│                                                                  │
│  ┌──────────────────────┐    ┌────────────────────────────┐     │
│  │  Cloud Workstations   │    │      Cloud Run Services    │     │
│  │  - Cluster            │    │  - midnight-node           │     │
│  │  - Config             │    │  - proof-server            │     │
│  │  - Dev Container      │    │  - indexer + postgres      │     │
│  └──────────────────────┘    └────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
.
├── Dockerfile                    # Dev container image
├── Makefile                      # Build/run/deploy targets
├── .env.example                  # Configuration template
│
├── cli/                          # Midnight CLI (midnightctl)
│   ├── src/
│   │   ├── commands/
│   │   │   ├── init.ts           # Project scaffolding
│   │   │   ├── compile.ts        # Compact compilation
│   │   │   ├── env.ts            # Environment management
│   │   │   └── services/
│   │   │       └── index.ts      # Cloud Run service management
│   │   ├── utils/
│   │   │   └── logger.ts
│   │   └── index.ts
│   ├── package.json
│   └── tsconfig.json
│
├── container-scripts/            # Container setup scripts
│   ├── main.sh                   # Orchestrator (called from Dockerfile)
│   ├── bin/
│   │   ├── midnightctl           # CLI wrapper
│   │   └── welcome               # Welcome message
│   ├── configure/
│   │   └── codeoss.sh            # Code OSS port detection
│   ├── install/
│   │   └── compact.sh            # Compact compiler installation
│   └── profile.d/
│       ├── compact.sh            # PATH setup
│       └── welcome.sh            # Auto-welcome on login
│
├── scripts/                      # Local development scripts
│   ├── common.sh                 # Shared utilities
│   ├── build-local.sh            # Build with Podman
│   ├── run-local.sh              # Run with Podman
│   ├── clean.sh                  # Container cleanup
│   └── cloud.sh                  # GCP deployment commands
│
├── cicd-pipelines/               # Cloud Build configurations
│   ├── cloudbuild.yaml           # Full deploy
│   ├── cloudbuild-plan.yaml      # Terraform plan only
│   └── cloudbuild-destroy.yaml   # Terraform destroy
│
├── terraform/                    # Infrastructure as Code
│   ├── backend.tf                # GCS backend
│   ├── main.tf                   # Root module
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── versions.tf               # Provider versions
│   └── modules/
│       ├── artifact-registry/    # Container image repo
│       ├── workstations/         # Cloud Workstations
│       └── midnight-services/    # Cloud Run services
│
└── .devcontainer/
    ├── devcontainer.json         # VS Code devcontainer config
    └── setup-env.sh              # Runtime environment setup
```

## Key Components

### 1. Dev Container (Dockerfile)

Base image: `us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest`

Includes:
- Node.js 20 LTS + npm (latest)
- TypeScript, ts-node
- Compact compiler (v0.26.0)
- Midnight CLI (`midnightctl`)
- gcloud SDK (from base image)

### 2. Midnight CLI (`midnightctl`)

TypeScript CLI built with Commander.js.

Commands:
- `midnightctl init <name>` - Scaffold new project with counter template
- `midnightctl compile` - Compile Compact contracts
- `midnightctl services status` - Check Cloud Run service health
- `midnightctl services logs [service]` - View service logs
- `midnightctl services urls` - Show service URLs
- `midnightctl env show|switch|list` - Manage network environments

### 3. Cloud Run Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| midnight-node | midnightntwrk/midnight-node:0.18.0-rc.9 | 9944 | Blockchain node |
| proof-server | midnightnetwork/proof-server:6.2.0-rc.1 | 6300 | ZK proof generation |
| indexer | midnightntwrk/indexer-standalone:3.0.0-alpha.20 | 8088 | Blockchain indexer |

All services run in the `midnight-services` namespace on GKE Autopilot.

### 4. Terraform Modules

- **artifact-registry**: Docker repo for dev container images
- **workstations**: Cloud Workstation cluster, config, and IAM
- **gke-cluster**: GKE Autopilot cluster for Midnight services
- **midnight-k8s-services**: Kubernetes deployments for node, proof-server, indexer

Service URLs are injected into the workstation container via environment variables.

## Configuration

### Environment Variables

Required for cloud deployment:
```bash
PROJECT_ID=your-gcp-project-id
STATE_BUCKET=your-terraform-state-bucket
```

Optional:
```bash
REGION=us-central1
CLUSTER_NAME=midnight-dev
ENVIRONMENT=dev
MACHINE_TYPE=e2-standard-4
MIN_INSTANCES=1
```

### Network Modes

| Mode | Node | Indexer | Proof Server |
|------|------|---------|--------------|
| standalone | Cloud Run | Cloud Run | Cloud Run |
| testnet | wss://testnet-node.midnight.network | https://testnet-indexer.midnight.network | Cloud Run |
| mainnet | wss://mainnet-node.midnight.network | https://mainnet-indexer.midnight.network | Cloud Run |

## Usage

### Local Development (Podman)

```bash
# Build container
make build

# Run interactively
make run

# Run detached
make run-detach

# Cleanup
make clean
```

### Cloud Deployment (GCP)

```bash
# Configure
cp .env.example .env
# Edit .env with PROJECT_ID and STATE_BUCKET

# Validate configuration
make check-env

# Preview changes
make plan

# Deploy everything
make deploy

# Destroy infrastructure
make destroy
```

### Inside the Container

```bash
# Create a new project
midnightctl init my-dapp
cd my-dapp

# Compile contracts
midnightctl compile

# Check service status
midnightctl services status

# View service logs
midnightctl services logs node
midnightctl services logs proof
midnightctl services logs indexer

# Switch networks
midnightctl env switch testnet
```

## Docker Hub Images

| Namespace | Images |
|-----------|--------|
| midnightntwrk | midnight-node, indexer-standalone, indexer-api, chain-indexer, wallet-indexer |
| midnightnetwork | proof-server, compactc (older namespace) |

## Key Technical Decisions

1. **Cloud Run over podman-in-podman**: Nested containers in Cloud Workstations were unreliable. Cloud Run provides managed, always-on services.

2. **Ephemeral PostgreSQL sidecar**: Data doesn't need to persist for standalone dev network. Simplifies infrastructure.

3. **min_instances=1**: Services are always warm, no cold start latency.

4. **Service discovery via env vars**: Terraform outputs Cloud Run URLs, injects them into workstation container config.

5. **Cluster labeling**: All resources labeled with `cluster=<name>` for multi-cluster support.

6. **No local Terraform dependency**: All Terraform runs in Cloud Build, state in GCS.

## Future Considerations

- [ ] Node 22 LTS upgrade when base image supports it
- [ ] Custom domain for Cloud Run services
- [ ] Workload identity for service-to-service auth
- [ ] Persistent storage option for indexer data
- [ ] Multi-region deployment
- [ ] Cost optimization (scale-to-zero for non-prod)

## Troubleshooting

### mandb permission errors during build
These are harmless warnings from the base image. Suppressed via `grep -v "mandb"` in Dockerfile.

### Services not responding
1. Check `midnightctl services status`
2. View logs: `midnightctl services logs <service>`
3. Verify Cloud Run services in GCP Console

### Environment variables not set
Run `source /etc/profile.d/midnight-env.sh` or start a new shell.

### gcloud not authenticated
The workstation uses workload identity. If issues persist:
```bash
gcloud auth login
gcloud config set project $PROJECT_ID
```
