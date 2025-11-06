# Privacy-Preserving DeFi Risk Management MVP

A privacy-preserving DeFi transaction system demonstrating confidential risk management on Midnight.network with public enforcement on Arc.network.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Operator      │    │   Mock Server   │    │   TEE Service   │
│   (Local)       │    │   (GCP VM)      │    │   (GCP TDX)     │
│                 │    │                 │    │                 │
│  make commands  │◄──►│  Anvil (Arc)    │◄──►│  ZK Proofs      │
│  Frontend UI    │    │  Midnight Node  │    │  Risk Checks    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Project Structure

```
privacy-preserving-defi/
├── README.md                   # This file
├── REQUIREMENTS.md             # Detailed requirements
├── cicd/                       # CI/CD and Docker configurations
│   ├── cloudbuild-infra.yaml  # CI/CD for infrastructure deployment
│   ├── cloudbuild-app.yaml    # CI/CD for application build and deploy
│   ├── cloudbuild-destroy.yaml # CI/CD for infrastructure destruction
│   ├── docker-compose.yml     # Local development services
│   ├── Dockerfile             # TEE service container
│   └── nginx.conf            # Frontend configuration
├── scripts/                    # Deployment and utility scripts
│   ├── cloud-deploy.sh        # Cloud deployment via Cloud Build
│   ├── cloud-destroy.sh       # Cloud destruction via Cloud Build
│   └── setup-mock-server.sh   # Mock server setup (Terraform)
│   └── setup-tee-service.sh  # TEE service setup (Terraform)
├── terraform/                  # Infrastructure as Code (Cloud Build only)
│   └── main.tf               # GCP infrastructure definition
├── terraform/                  # Infrastructure as Code
│   └── main.tf                # GCP resources (VPC, VMs, IAM)
├── contracts/                  # Smart contracts
│   ├── DeFiVault.sol          # Arc DeFi vault contract
│   ├── MockUSDC.sol           # Mock USDC token
│   ├── ComplianceRegistry.sol # KYC/compliance stub
│   └── PrivateLedger.compact  # Midnight private ledger
├── tee-service/               # TEE application
│   ├── src/
│   │   └── main.rs           # Rust service implementation
│   └── Cargo.toml
├── frontend/                  # User interface
│   └── index.html
└── scripts/                   # Setup and deployment scripts
    ├── setup-mock-server.sh
    ├── setup-tee-service.sh
    └── seed-contracts.sh
```

## Prerequisites

- Google Cloud SDK installed and authenticated
- Docker/Podman installed locally
- SSH key pair for GCP VM access
- GCP project with billing enabled

## Quick Start

### 1. Bootstrap the Project

```bash
# Set up GCP project and enable APIs
make bootstrap
```

### 2. Local Development (Recommended)

#### Option 1: Automated Setup (Recommended)
```bash
# One-command local development setup (includes all services)
make local-dev
```

#### Option 2: Manual Setup
```bash
# Start core services
make local-start

# Deploy contracts
cd build && $COMPOSE_CMD --profile deploy up --build contract-deployer

# Add optional services
$COMPOSE_CMD --profile frontend up frontend      # Frontend dev server
$COMPOSE_CMD --profile explorer up blockscout     # Block explorer
$COMPOSE_CMD --profile tools run dev-tools         # Dev tools container

# Test system
curl http://localhost:8080/healthz
```

#### Local Development Commands
```bash
# Full setup (prerequisites + services + contracts)
make local-dev

# Service management
make local-start      # Start all services
make local-stop       # Stop all services
make local-restart    # Restart all services
make local-logs       # Follow service logs
make local-clean      # Clean containers and volumes

# With Podman (if preferred)
COMPOSE_CMD=podman-compose make local-start
COMPOSE_CMD=podman-compose make local-stop
```

#### Option 2: Manual Setup
```bash
# Start core services
cd build && docker-compose up -d

# Deploy contracts
docker-compose --profile deploy up --build contract-deployer

# Add optional services
docker-compose --profile frontend up frontend      # Frontend dev server
docker-compose --profile explorer up blockscout     # Block explorer
docker-compose --profile tools run dev-tools         # Dev tools container

# Test system
curl http://localhost:8080/healthz
```

### 3. Cloud Deployment

#### Deploy Infrastructure
```bash
# Deploy VPC, VMs, and networking
make infra-up
```

#### Start Mock Blockchains
```bash
# Start Anvil and Midnight nodes on mock server
make mocks-up
```

#### Deploy Smart Contracts
```bash
# Deploy contracts and store addresses in Secret Manager
make seed-mocks
```

#### Deploy TEE Application
```bash
# Build and deploy TEE service
make deploy-app
```

#### Verify Deployment
```bash
# Check TEE service health
make status

# View TEE service logs
make logs
```

## User Journey Demo

1. **Access Frontend**: Open the web interface (URL provided after deployment)
2. **Initiate Deposit**: Submit a deposit request (e.g., 1M USDC)
3. **Compliance Check**: TEE verifies user is KYC-approved
4. **Risk Check**: TEE privately validates 10% TVL concentration limit
5. **ZK Proof Generation**: TEE generates proof of successful risk check
6. **Settlement**: TEE executes deposit on Arc with ZK proof
7. **Atomicity**: If Arc fails, TEE rolls back Midnight state change

## Key Features Demonstrated

- **Privacy**: User balances remain confidential on Midnight
- **Risk Management**: 10% TVL concentration limit enforced privately
- **Atomicity**: Cross-chain transaction atomicity via TEE rollback
- **Zero Knowledge**: ZK proofs of private state transitions
- **TEE Security**: Intel TDX enclave for trusted computation

## Development Commands

### Local Development

#### Prerequisites
- Docker & Docker Compose
- Node.js (for Midnight Compact compiler)
- Rust (for TEE service)
- Foundry (for Arc contracts)

#### Quick Start
```bash
# 1. Start all services locally
cd build && docker-compose up -d

# 2. Verify services are running
docker-compose ps

# 3. Deploy Arc contracts
make seed-mocks

# 4. Deploy Midnight contract
midnight deploy --network testnet ../contracts/PrivateLedger.compact

# 5. Test the system
curl http://localhost:8080/healthz
```

#### Development Workflow
```bash
# Start services in development mode
cd build && docker-compose up

# Build TEE service with hot reload
cd tee-service && cargo watch -x run

# Compile Midnight contract
compact compile ../contracts/PrivateLedger.compact --output ../contracts/dist/

# Deploy Arc contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Test frontend
open frontend/index.html
```

#### Service URLs
- **TEE Service**: http://localhost:8080
- **Arc RPC**: http://localhost:8545
- **Midnight RPC**: http://localhost:9944
- **Proof Server**: http://localhost:6300
- **Block Explorer**: http://localhost:4000 (optional)

#### Debugging
```bash
# View logs
docker-compose logs -f tee-service
docker-compose logs -f anvil
docker-compose logs -f midnight-node

# Access containers
docker-compose exec tee-service bash
docker-compose exec anvil bash

# Reset environment
docker-compose down -v
docker-compose up -d
```

### 3. Cloud Deployment

#### Deploy Infrastructure
```bash
# Deploy VPC, VMs, and networking via Terraform
make infra-up

# Or plan/apply manually
make tf-plan      # Review changes
make tf-apply     # Apply changes
```

#### Start Mock Blockchains
```bash
# Start Anvil and Midnight nodes on remote VM
make mocks-up
```

#### Deploy Smart Contracts
```bash
# Deploy contracts to remote infrastructure and store in Secret Manager
make seed-mocks
```

#### Deploy TEE Application
```bash
# Build and deploy TEE service via Cloud Build
make deploy-app
```

#### Verify Deployment
```bash
# Check TEE service health on remote VM
make status

# View TEE service logs from Cloud Logging
make logs
```

#### Destroy Infrastructure
```bash
# Clean up all GCP resources
make infra-destroy
```

## Architecture Components

### TEE Service API Endpoints

- `GET /healthz` - Service health check
- `POST /api/v1/session` - Establish secure session
- `POST /api/v1/deposit` - Execute private deposit flow

### Smart Contracts

- **DeFiVault.sol**: Arc contract accepting ZK proofs for deposits
- **PrivateLedger.compact**: Midnight contract managing private balances
- **MockUSDC.sol**: ERC20 token for testing
- **ComplianceRegistry.sol**: KYC/compliance verification

### Security Features

- Intel TDX confidential computing
- Workload Identity Federation
- Network isolation via private VPC
- Attestation-based access control

## Monitoring and Debugging

```bash
# Check VM status
gcloud compute instances list

# SSH into mock server
gcloud compute ssh mock-server

# SSH into TEE service
gcloud compute ssh tee-service

# View logs
make logs

# Check contract addresses
gcloud secrets versions list arc-contracts
gcloud secrets versions list midnight-contracts
```

## MVP Limitations

- TEE-based rollback (vs cryptographic 2PC)
- Mock ZK verification in Arc contracts
- Ephemeral user keys (no hardware wallet integration)
- Single TEE instance (not decentralized)

## Cleanup

```bash
# Destroy all infrastructure
cd terraform && terraform destroy

# Clean local resources
make clean
```