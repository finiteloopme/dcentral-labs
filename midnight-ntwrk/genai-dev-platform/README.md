# Midnight GenAI Development Platform

A cloud-native development environment for building applications on the [Midnight](https://midnight.network) blockchain network.

## Features

- **Browser-based IDE** - VS Code (Code OSS) accessible from anywhere
- **Compact Compiler** - Pre-installed Midnight smart contract toolchain
- **Midnight CLI** - Project scaffolding, compilation, and service management
- **Managed Services** - Blockchain node, proof server, and indexer running on GKE Autopilot
- **Multi-chain Support** - Switch between standalone, testnet, and mainnet environments

## Midnight Token Model

| Token | Description | Transferable |
|-------|-------------|--------------|
| **NIGHT** | Native token (shielded or unshielded) | Yes |
| **DUST** | Fee resource (regenerates over time) | No |

- **Shielded NIGHT** (`mn_shield-addr_...`): Private transactions using ZK proofs
- **Unshielded NIGHT** (`mn_addr_...`): Public transactions visible on-chain
- **DUST**: Non-transferable resource for transaction fees, regenerates based on NIGHT holdings

For details, see [WALLET-HOW-TO.md](WALLET-HOW-TO.md).

## Quick Start

### Prerequisites

**For local development:**
- [Podman](https://podman.io/getting-started/installation) installed

**For cloud deployment:**
- Google Cloud project with billing enabled
- `gcloud` CLI installed and authenticated
- GCS bucket for Terraform state
- A user-managed service account for Cloud Build (see Cloud Deployment below)
- `INDEXER_SECRET` environment variable set (32-byte hex string for encryption)
  - Generate with: `openssl rand -hex 32`
  - A default development value is provided, but **must be replaced for production**

### Local Development

```bash
# Clone the repository
git clone <repo-url>
cd genai-dev-platform

# Build SDK image (one-time, ~30 min)
make build-sdk

# Build the container (uses SDK image)
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
│   ├── cloudbuild.yaml           # Full deployment pipeline
│   ├── cloudbuild-plan.yaml      # Terraform plan only
│   ├── cloudbuild-destroy.yaml   # Infrastructure teardown
│   └── cloudbuild-state-cleanup.yaml  # State management
│
├── charts/                       # Helm charts
│   └── midnight-services/        # K8s services (node, proof-server, indexer)
│
├── terraform/                    # Infrastructure as Code
│   ├── modules/
│   │   ├── artifact-registry/    # Container registry
│   │   ├── gke-cluster/          # GKE Autopilot cluster
│   │   └── workstations/         # Cloud Workstations
│   └── *.tf                      # Root module (includes helm_release)
│
└── .devcontainer/                # VS Code devcontainer
    ├── devcontainer.json
    └── setup-env.sh
```

## Usage

### Make Targets

| Target | Description |
|--------|-------------|
| `make build-sdk` | Build SDK image from source (~30 min, one-time) |
| `make build` | Build container (requires SDK image) |
| `make run` | Run container interactively |
| `make run-detach` | Run container in background |
| `make clean` | Stop and remove container |
| `make deploy` | Deploy to GCP via Cloud Build |
| `make plan` | Preview deployment changes |
| `make destroy` | Tear down cloud infrastructure |
| `make check-env` | Validate GCP configuration |

### Build Flags

Control what gets built during cloud deployment:

| Flag | Default | Description |
|------|---------|-------------|
| `BUILD_SDK` | `true` | Build the Midnight SDK image from source (~30 min) |
| `BUILD_IMAGE` | `true` | Build the platform container image (~5 min) |

**Examples:**

```bash
# Full build (default)
make deploy

# Skip SDK build (use existing SDK image from registry)
make deploy BUILD_SDK=false

# Skip both builds (Terraform-only, fastest)
make deploy BUILD_SDK=false BUILD_IMAGE=false
```

**Note:** When `BUILD_IMAGE=false`, the platform image must already exist in the Artifact Registry.

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

### Wallet Management

```bash
# Create a wallet
midnightctl wallet create my-wallet

# Check balance (shielded + unshielded NIGHT)
midnightctl wallet balance

# Check balance including DUST resource
midnightctl wallet balance --include-dust

# View all addresses (unshielded, shielded, DUST)
midnightctl wallet address --all

# Fund from genesis (standalone mode only)
midnightctl wallet fund my-wallet 10000

# Send NIGHT (auto-detects address type)
midnightctl wallet send my-wallet <destination-address> 100

# Register for DUST generation
midnightctl wallet register-dust
```

See [FUNDING.md](FUNDING.md) for detailed wallet operations.

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
MACHINE_TYPE=n2-standard-8
```

### Workstation Management

Workstation instances are configured via Terraform variables file:

```bash
# Copy the example file
cp terraform/workstations.auto.tfvars.example terraform/workstations.auto.tfvars

# Edit with your workstation configuration
```

Example `terraform/workstations.auto.tfvars`:
```hcl
# Create workstations (name = email)
workstations = {
  "alice" = "alice@company.com"
  "bob"   = "bob@company.com"
}

# Admin access to all workstations
workstation_admins = [
  "admin@company.com"
]
```

This creates:

| Workstation ID | Owner | Access |
|----------------|-------|--------|
| `midnight-workstation-alice` | alice@company.com | alice@, admin@ |
| `midnight-workstation-bob` | bob@company.com | bob@, admin@ |

**Features:**
- **Auto-start**: Workstations automatically start when users connect
- **Consistent config**: All workstations use the same machine type and container image
- **IAM-based access**: Users can only access their assigned workstation(s)

**Manual workstation creation** (if not using tfvars):
```bash
gcloud workstations create my-workstation \
  --cluster=midnight-dev \
  --config=midnight-dev-config \
  --region=us-central1
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
| `standalone` | Dev mode with mock chain follower | Auto-configured | Auto-configured |
| `devnet` | External devnet connection | Auto-configured | Auto-configured |
| `testnet` | External testnet connection | Auto-configured | Auto-configured |
| `mainnet` | External mainnet connection | Auto-configured | Auto-configured |

**Component Versions (0.18.0 stack):**
- Node: `midnightntwrk/midnight-node:0.18.0`
- Proof Server: `midnightnetwork/proof-server:6.1.0-alpha.6`
- Indexer: `midnightntwrk/indexer-standalone:3.0.0-alpha.20`

### Switching Environments

```bash
# Check current environment
midnightctl env status

# Switch to a different environment
midnightctl env switch testnet
```

### Standalone Mode Details

In `standalone` mode (default):
- The midnight-node runs with dev mode configuration (0.18.0+):
  - Uses `USE_MAIN_CHAIN_FOLLOWER_MOCK=true` to mock the Cardano chain follower
  - Runs with `--dev --rpc-external --rpc-cors=all` command args
  - Enables a local development chain with ephemeral storage (resets on restart)
  - Requires no external bootnodes or peer connections
- The proof-server auto-starts and downloads required ZK key material (~1GB, takes 5-10 min)
- The indexer connects to the local node via WebSocket
  - API endpoint: `/api/v3/graphql` (v1 redirects to v3)
  - Configuration is managed via ConfigMap

**Required configuration:**
- `INDEXER_SECRET` - A 32-byte hex string for encryption (generate with `openssl rand -hex 32`)
  - A default development value is provided in Terraform variables
  - **Must be replaced with a secure value for production deployments**

This is ideal for rapid development and testing without external dependencies.

**Pre-funded wallets:** In standalone mode, several genesis wallets are pre-funded for development. See [WALLET-HOW-TO.md](WALLET-HOW-TO.md) for details on wallet creation and funding.

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

## Midnight SDK 3.x Dependency

The Midnight CLI requires SDK 3.x packages which are currently only available via a private GitHub npm registry. Until they are published to public npm, we build them from source as a separate container image.

### How It Works

The SDK is built as a separate container image (`midnight-sdk`) that the main container depends on:

1. **`Dockerfile.sdk`**: Builds SDK packages from source
   - **ledger-builder** (Nix): Builds WASM packages from [midnight-ledger](https://github.com/midnightntwrk/midnight-ledger)
   - **ts-builder** (Node): Builds TypeScript packages from [midnight-wallet](https://github.com/midnightntwrk/midnight-wallet) and [midnight-js](https://github.com/midnightntwrk/midnight-js)
   - Output: `/opt/vendor/` with all built packages

2. **`Dockerfile`**: Uses pre-built SDK image
   - `COPY --from=midnight-sdk:latest /opt/vendor /opt/vendor`
   - Builds CLI using vendor packages

### Pinned Versions

Versions are controlled by ARGs in `Dockerfile.sdk`:

| Repository | ARG | Current Version |
|------------|-----|-----------------|
| midnight-ledger | `LEDGER_TAG` | `ledger-6.1.0-alpha.6` |
| midnight-wallet | `WALLET_COMMIT` | `6bf9fe8` |
| midnight-js | `JS_TAG` | `v3.0.0-alpha.11` |

### Local Development Workflow

```bash
# 1. Build SDK image (one-time, ~30 min)
make build-sdk

# 2. Build main container (uses SDK image)
make build

# 3. Run container
make run
```

### Cloud Deployment Workflow

```bash
# Full deployment (builds SDK and platform image)
make deploy

# Skip SDK build (faster, uses existing SDK image)
make deploy BUILD_SDK=false

# Terraform-only (fastest, uses existing images)
make deploy BUILD_SDK=false BUILD_IMAGE=false
```

### Upgrading SDK Versions

1. Edit the version ARGs in `Dockerfile.sdk`
2. Rebuild SDK: `make build-sdk`
3. Rebuild container: `make build`

For cloud deployment:
1. Edit versions in `cicd-pipelines/cloudbuild.yaml` (substitutions section)
2. Run full deploy: `make deploy` (or `make deploy BUILD_SDK=true` to force SDK rebuild)

### When SDK 3.x is Published

Once the SDK is available on public npm:

1. Update `cli/package.json` - replace `file:/opt/vendor/...` with `^3.0.0`
2. Update `Dockerfile` - remove `COPY --from=sdk` and SDK_IMAGE ARG
3. Delete `Dockerfile.sdk`
4. Remove SDK build steps from `cicd-pipelines/cloudbuild.yaml`

See [vendor/README.md](vendor/README.md) for detailed documentation.

## Development

- [GenAI-Dev.md](GenAI-Dev.md) - Detailed technical documentation
- [WALLET-HOW-TO.md](WALLET-HOW-TO.md) - Wallet creation and funding guide
- [WALLET-INTEGRATION-REQ.md](WALLET-INTEGRATION-REQ.md) - Wallet CLI integration requirements

## License

[Add license information]
