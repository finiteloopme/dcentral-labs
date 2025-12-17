# Midnight GenAI Development Platform

A cloud-native development environment for building applications on the [Midnight](https://midnight.network) blockchain network.

## Features

- **Browser-based IDE** - VS Code (Code OSS) accessible from anywhere
- **Compact Compiler** - Pre-installed Midnight smart contract toolchain
- **Midnight CLI** - Project scaffolding, compilation, and service management
- **Managed Services** - Blockchain node, proof server, and indexer running on GKE Autopilot
- **Multi-chain Support** - Switch between standalone, testnet, and mainnet environments

## Quick Start

### Prerequisites

**For local development:**
- [Podman](https://podman.io/getting-started/installation) installed

**For cloud deployment:**
- Google Cloud project with billing enabled
- `gcloud` CLI installed and authenticated
- GCS bucket for Terraform state
- A user-managed service account for Cloud Build (see Cloud Deployment below)

### Local Development

```bash
# Clone the repository
git clone <repo-url>
cd genai-dev-platform

# Build the container
make build

# Run interactively
make run
```

### Cloud Deployment

```bash
# 1. Configure environment
cp .env.example .env

# 2. Edit .env with your settings
#    Required: PROJECT_ID, STATE_BUCKET, STATE_PREFIX, CLOUDBUILD_SA_EMAIL

# 3. Bootstrap Cloud Build service account (one-time setup)
#    See "Bootstrapping the Cloud Build Service Account" section below

# 4. Validate configuration
make check-env

# 5. Deploy to GCP
make deploy
```

### Bootstrapping the Cloud Build Service Account

Terraform manages IAM roles for the Cloud Build service account, but it needs initial permissions to run. This is a **one-time setup** before the first deployment.

```bash
# Set your project ID
export PROJECT_ID=your-gcp-project-id

# Create the service account
gcloud iam service-accounts create midnight-cloudbuild-sa \
  --display-name="Midnight Cloud Build SA" \
  --project=$PROJECT_ID

# Grant bootstrap roles required for Terraform to manage IAM and resources
# These roles allow Terraform to assign the full set of roles on first apply

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:midnight-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.builder"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:midnight-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:midnight-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:midnight-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:midnight-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.projectIamAdmin"
```

After the first successful `make deploy`, Terraform will manage the complete set of IAM roles for the service account. The bootstrap roles above are the minimum required to:
- Run Cloud Build jobs (`cloudbuild.builds.builder`)
- Access Terraform state in GCS (`storage.admin`)
- Enable required GCP APIs (`serviceusage.serviceUsageAdmin`)
- Act as service accounts during deployment (`iam.serviceAccountUser`)
- Manage IAM bindings for the service account itself (`resourcemanager.projectIamAdmin`)

## Project Structure

```
.
├── Dockerfile                    # Dev container definition
├── Makefile                      # Build and deploy targets
├── .env.example                  # Configuration template
│
├── cli/                          # Midnight CLI (midnightctl)
│   └── src/
│       ├── commands/             # CLI commands
│       └── utils/                # Shared utilities
│
├── container-scripts/            # Container setup
│   ├── main.sh                   # Setup orchestrator
│   ├── bin/                      # CLI tools (midnightctl, welcome)
│   ├── configure/                # Service configuration
│   ├── install/                  # Tool installers
│   └── profile.d/                # Shell profile scripts
│
├── scripts/                      # Development scripts
│   ├── build-local.sh            # Local container build
│   ├── run-local.sh              # Local container run
│   ├── clean.sh                  # Container cleanup
│   └── cloud.sh                  # GCP deployment
│
├── cicd-pipelines/               # Cloud Build configs
│   ├── cloudbuild.yaml           # Full deployment
│   ├── cloudbuild-plan.yaml      # Terraform plan
│   └── cloudbuild-destroy.yaml   # Infrastructure teardown
│
├── terraform/                    # Infrastructure as Code
│   ├── modules/
│   │   ├── artifact-registry/    # Container registry
│   │   ├── gke-cluster/          # GKE Autopilot cluster
│   │   ├── midnight-k8s-services/# Kubernetes services (node, proof, indexer)
│   │   └── workstations/         # Cloud Workstations
│   └── *.tf                      # Root module
│
└── .devcontainer/                # VS Code devcontainer
    ├── devcontainer.json
    └── setup-env.sh
```

## Usage

### Make Targets

| Target | Description |
|--------|-------------|
| `make build` | Build container locally with Podman |
| `make run` | Run container interactively |
| `make run-detach` | Run container in background |
| `make clean` | Stop and remove container |
| `make deploy` | Deploy to GCP via Cloud Build |
| `make plan` | Preview deployment changes |
| `make destroy` | Tear down cloud infrastructure |
| `make check-env` | Validate GCP configuration |

### Midnight CLI

Once inside the container:

```bash
# Create a new project
midnightctl init my-dapp

# Compile Compact contracts
cd my-dapp
midnightctl compile

# Check service status
midnightctl services status

# View service logs
midnightctl services logs node

# Switch chain environments
midnightctl env switch testnet
```

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
# Required for cloud deployment
PROJECT_ID=your-gcp-project-id
STATE_BUCKET=your-terraform-state-bucket
STATE_PREFIX=terraform/state
CLOUDBUILD_SA_EMAIL=midnight-cloudbuild-sa@your-project.iam.gserviceaccount.com

# Optional
REGION=us-central1
CLUSTER_NAME=midnight-dev
GKE_CLUSTER_NAME=midnight-dev-gke
CHAIN_ENVIRONMENT=standalone
MACHINE_TYPE=e2-standard-4
```

## Chain Environments

The platform supports multiple chain environments for different stages of development:

| Environment | Description | Use Case |
|-------------|-------------|----------|
| `standalone` | Isolated dev network with ephemeral state | Local development, testing, rapid iteration |
| `devnet` | Midnight shared development network | Integration testing with other developers |
| `testnet` | Midnight public testnet | Pre-production testing, staging |
| `mainnet` | Midnight mainnet | Production deployments |

### Environment Mapping

The `chain_environment` setting is mapped to service-specific configurations:

| Chain Environment | Node Mode | Proof Server | Indexer |
|-------------------|-----------|--------------|---------|
| `standalone` | `CFG_PRESET=dev` (ephemeral, local chain) | Auto-configured | Auto-configured |
| `devnet` | `CFG_PRESET=devnet` | Auto-configured | Auto-configured |
| `testnet` | `CFG_PRESET=testnet` | Auto-configured | Auto-configured |
| `mainnet` | `CFG_PRESET=mainnet` | Auto-configured | Auto-configured |

### Switching Environments

```bash
# Check current environment
midnightctl env status

# Switch to a different environment
midnightctl env switch testnet
```

### Standalone Mode Details

In `standalone` mode (default):
- The midnight-node runs with `CFG_PRESET=dev`, which:
  - Enables a local development chain
  - Uses ephemeral storage (resets on restart)
  - Requires no external bootnodes or peer connections
- The proof-server auto-starts and downloads required ZK key material
- The indexer connects to the local node via WebSocket

**Required configuration:**
- `INDEXER_SECRET` - A 32-byte hex string for encryption (generate with `openssl rand -hex 32`)

This is ideal for rapid development and testing without external dependencies.

**Pre-funded wallets:** In standalone mode, several genesis wallets are pre-funded for development. See [FUNDING.md](FUNDING.md) for details on wallet creation and funding.

## Architecture

The platform deploys:

1. **Cloud Workstations** - Managed dev environment with persistent storage
2. **Artifact Registry** - Private Docker repository for container images
3. **GKE Autopilot Cluster** (`midnight-dev-gke`) with Kubernetes services:
   - `midnight-node` - Blockchain node (StatefulSet, port 9944)
   - `proof-server` - Zero-knowledge proof generation (Deployment, port 6300)
   - `indexer` - Blockchain data indexer with SQLite (StatefulSet, port 8088)

All services run in the `midnight-services` namespace and are exposed via External Load Balancers.

Infrastructure is managed via Terraform and deployed through Cloud Build.

## Development

- [GenAI-Dev.md](GenAI-Dev.md) - Detailed technical documentation
- [FUNDING.md](FUNDING.md) - Wallet creation and funding guide
- [WALLET-INTEGRATION-REQ.md](WALLET-INTEGRATION-REQ.md) - Wallet CLI integration requirements

## License

[Add license information]
