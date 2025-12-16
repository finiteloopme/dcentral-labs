# Midnight GenAI Development Platform

A cloud-native development environment for building applications on the [Midnight](https://midnight.network) blockchain network.

## Features

- **Browser-based IDE** - VS Code (Code OSS) accessible from anywhere
- **Compact Compiler** - Pre-installed Midnight smart contract toolchain
- **Midnight CLI** - Project scaffolding, compilation, and service management
- **Managed Services** - Blockchain node, proof server, and indexer running on Cloud Run
- **Multi-network Support** - Switch between standalone, testnet, and mainnet

## Quick Start

### Prerequisites

**For local development:**
- [Podman](https://podman.io/getting-started/installation) installed

**For cloud deployment:**
- Google Cloud project with billing enabled
- `gcloud` CLI installed and authenticated
- GCS bucket for Terraform state

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
#    Required: PROJECT_ID, STATE_BUCKET

# 3. Validate configuration
make check-env

# 4. Deploy to GCP
make deploy
```

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
│   │   ├── workstations/         # Cloud Workstations
│   │   └── midnight-services/    # Cloud Run services
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

# Switch networks
midnightctl env switch testnet
```

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
# Required for cloud deployment
PROJECT_ID=your-gcp-project-id
STATE_BUCKET=your-terraform-state-bucket

# Optional
REGION=us-central1
CLUSTER_NAME=midnight-dev
MACHINE_TYPE=e2-standard-4
```

## Network Modes

| Mode | Description |
|------|-------------|
| `standalone` | Local development network (Cloud Run services) |
| `testnet` | Midnight public testnet |
| `mainnet` | Midnight mainnet (production) |

Switch networks with:
```bash
midnightctl env switch <mode>
```

## Architecture

The platform deploys:

1. **Cloud Workstations** - Managed dev environment with persistent storage
2. **Artifact Registry** - Private Docker repository for container images
3. **Cloud Run Services**:
   - `midnight-node` - Blockchain node (port 9944)
   - `proof-server` - Zero-knowledge proof generation (port 6300)
   - `indexer` - Blockchain data indexer with PostgreSQL (port 8081)

All infrastructure is managed via Terraform, deployed through Cloud Build.

## Development

See [GenAI-Dev.md](GenAI-Dev.md) for detailed technical documentation.

## License

[Add license information]
