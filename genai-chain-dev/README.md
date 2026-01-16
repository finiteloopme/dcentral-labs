# genai-chain-dev

A modular framework for creating GenAI-enabled blockchain development platforms.

## Features

- **Browser-based IDE** - VS Code (Code OSS) via Cloud Workstations
- **AI Coding Assistant** - OpenCode with chain-specific context (Gemini/Claude via Vertex AI)
- **Chain-specific CLI** - Wallet management, contract development, local nodes
- **Pre-installed Toolchain** - Foundry (forge, cast, anvil) for EVM chains
- **Podman-based Local Dev** - Build and run containers locally

## Prerequisites

### For Local Development

- [Podman](https://podman.io/getting-started/installation) installed
- [Earthly](https://earthly.dev/get-earthly) 0.8+ installed (optional - can use containerized version)
- Node.js 20+ (for CLI development)

### For Cloud Deployment

1. **Google Cloud project** with billing enabled
2. **`gcloud` CLI** installed and authenticated
3. **GCS bucket** for Terraform state (created automatically via `make check-env`)
4. **User-managed service account** for Cloud Build (see bootstrap section below)

## Quick Start

### Local Development

```bash
# Clone and enter directory
git clone <repo-url>
cd genai-chain-dev

# Build the Somnia dev image
make build CHAIN=somnia

# Run locally with podman
make run CHAIN=somnia
```

#### Building Without Local Earthly

If you don't have Earthly installed locally, use the containerized version:

```bash
make build-container CHAIN=somnia
```

This runs Earthly inside a Podman container (`--privileged` required for BuildKit).

#### OpenCode Vertex AI Setup (Local)

For OpenCode AI assistant to work locally, you need gcloud Application Default Credentials:

```bash
# Authenticate with gcloud (one-time)
gcloud auth application-default login

# Verify credentials exist
ls ~/.config/gcloud/application_default_credentials.json
```

When you run `make run CHAIN=somnia`, the credentials are automatically mounted into the container.

#### Overriding Chain Configuration

You can override the baked-in chain configuration for local development:

```bash
# Use a local Anvil fork
RPC_URL=http://localhost:8545 make run CHAIN=somnia

# Or set in .env file
echo "RPC_URL=http://localhost:8545" >> .env
make run CHAIN=somnia
```

Available overrides: `RPC_URL`, `CHAIN_ID`, `EXPLORER_URL`, `FAUCET_URL`

### Cloud Deployment

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with PROJECT_ID, STATE_BUCKET, CLOUDBUILD_SA_EMAIL

# 2. Bootstrap service account (one-time, see section below)

# 3. Validate configuration (creates state bucket if needed)
make check-env CHAIN=somnia

# 4. Deploy to GCP
make cloud-deploy CHAIN=somnia
```

## Bootstrapping the Cloud Build Service Account

Terraform manages IAM roles for the Cloud Build service account, but it needs initial permissions to run. This is a **one-time setup** before the first deployment.

```bash
# Set your project ID
export PROJECT_ID=your-gcp-project-id

# Create the service account
gcloud iam service-accounts create chain-dev-cloudbuild-sa \
  --display-name="Chain Dev Cloud Build SA" \
  --project=$PROJECT_ID

# Grant bootstrap roles required for Terraform to manage IAM and resources
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chain-dev-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.builder"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chain-dev-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chain-dev-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chain-dev-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chain-dev-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.projectIamAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chain-dev-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"
```

After the first successful deployment, Terraform manages the complete set of IAM roles. The bootstrap roles are the minimum required to:

- Run Cloud Build jobs (`cloudbuild.builds.builder`)
- Access Terraform state in GCS (`storage.admin`)
- Enable required GCP APIs (`serviceusage.serviceUsageAdmin`)
- Act as service accounts during deployment (`iam.serviceAccountUser`)
- Manage IAM bindings (`resourcemanager.projectIamAdmin`, `iam.serviceAccountAdmin`)

## Project Structure

```
genai-chain-dev/
├── Makefile                 # Root Makefile (use CHAIN= argument)
├── cloudbuild.yaml          # Cloud Build configuration
├── .env.example             # Configuration template
│
├── terraform/               # Shared Terraform configuration
│   ├── main.tf             # Workstations + Artifact Registry
│   ├── variables.tf        # Variables with sane defaults
│   └── workstations.auto.tfvars.example
│
├── scripts/                 # Build and deployment scripts
│   ├── build.sh            # Build images locally
│   ├── earthly-container.sh # Run Earthly via Podman (no local install)
│   ├── run-local.sh        # Run with podman
│   ├── cloud.sh            # Cloud Build operations
│   ├── deploy.sh           # Local Terraform
│   └── new-chain.sh        # Scaffold new chain
│
├── core/                    # Shared framework
│   ├── cli/                # CLI framework (TypeScript)
│   ├── scripts/            # Installation scripts
│   └── terraform/modules/  # Reusable Terraform modules
│
└── chains/
    ├── evm/                # EVM chain type (Foundry-based)
    └── somnia/             # Somnia chain implementation
        ├── Earthfile       # Container build
        ├── chain.config.toml
        └── AGENTS.md       # AI context
```

## Usage

### Make Targets

```bash
# Local Development
make build CHAIN=somnia           # Build container image (requires local Earthly)
make build-container CHAIN=somnia # Build using containerized Earthly (no local install)
make run CHAIN=somnia             # Run with podman
make stop CHAIN=somnia            # Stop running container
make shell CHAIN=somnia           # Interactive shell
make test CHAIN=somnia            # Run CLI tests
make clean CHAIN=somnia           # Stop container + clean build artifacts

# Cloud Operations
make check-env CHAIN=somnia  # Validate config, create bucket
make cloud-deploy CHAIN=somnia   # Full deployment
make cloud-plan CHAIN=somnia     # Preview changes
make cloud-destroy CHAIN=somnia  # Tear down

# Chain Management
make new-chain NAME=polygon TYPE=evm
make list-chains
```

### CLI Commands

Inside the development environment:

```bash
# Project scaffolding
somniactl init my-project

# Contract development
somniactl compile
somniactl test
somniactl deploy MyContract

# Wallet management
somniactl wallet create dev
somniactl wallet balance
somniactl wallet send 0x... 1.0

# Local node
somniactl node start
somniactl node status
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env`:

```bash
# Required
PROJECT_ID=your-gcp-project-id
STATE_BUCKET=your-terraform-state-bucket
CLOUDBUILD_SA_EMAIL=chain-dev-cloudbuild-sa@your-project.iam.gserviceaccount.com

# Optional
REGION=us-central1
TAG=latest
```

### Workstation Users

Copy `terraform/workstations.auto.tfvars.example` to `terraform/workstations.auto.tfvars`:

```hcl
workstations = {
  "alice" = "alice@company.com"
  "bob"   = "bob@company.com"
}

workstation_admins = [
  "admin@company.com"
]
```

### Chain Configuration

Each chain has a `chain.config.toml`:

```toml
[chain]
name = "Somnia"
type = "evm"

[cli]
name = "somniactl"

[networks.testnet]
chain_id = 50311
rpc_url = "https://dream-rpc.somnia.network"
native_currency = "STT"
is_default = true
```

## Adding New Chains

```bash
# Scaffold a new EVM chain
make new-chain NAME=polygon TYPE=evm

# Or with more options
./scripts/new-chain.sh polygon \
    --type=evm \
    --chain-id=137 \
    --rpc-url=https://polygon-rpc.com \
    --native-currency=MATIC
```

This creates:
- `chains/polygon/Earthfile`
- `chains/polygon/chain.config.toml`
- `chains/polygon/AGENTS.md`

Then build and deploy:

```bash
make build CHAIN=polygon
make cloud-deploy CHAIN=polygon
```

## Architecture

The framework uses a layered Earthly build system:

```
core/Earthfile (base image, OpenCode)
       │
       ▼
chains/evm/Earthfile (Foundry, EVM CLI)
       │
       ▼
chains/somnia/Earthfile (chain configuration)
```

See [docs/FRAMEWORK.md](docs/FRAMEWORK.md) for details.

## Chain Types

### EVM

For Ethereum-compatible chains:

- **Toolchain**: Foundry (forge, cast, anvil)
- **CLI**: viem-based wallet, Foundry wrappers
- **Local Node**: Anvil
- **Chains**: Somnia, Polygon, Arbitrum, etc.

## Documentation

- [docs/FRAMEWORK.md](docs/FRAMEWORK.md) - Architecture documentation
- [docs/ADDING-CHAIN.md](docs/ADDING-CHAIN.md) - Guide for adding new chains
- [docs/TOML-REFERENCE.md](docs/TOML-REFERENCE.md) - Configuration reference

## License

MIT
