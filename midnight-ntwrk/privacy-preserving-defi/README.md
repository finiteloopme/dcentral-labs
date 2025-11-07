# Privacy-Preserving DeFi Risk Management MVP

A privacy-preserving DeFi transaction system demonstrating confidential risk management on Midnight.network with public enforcement on Arc.network.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   TEE Service   │    │ Midnight Int.   │    │ Midnight Proof  │
│   (Port 3000)   │◄──►│   (Port 8080)   │◄──►│   (Port 3001)   │◄──►│   Server        │
│                 │    │                 │    │                 │    │   (Port 6300)   │
│  User Interface │    │  ZK Proofs      │    │  Compact        │    │  Proof Gen      │
│  Deposit Flow   │    │  Risk Checks    │    │  Integration     │    │  Verification   │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        ▲
┌─────────────────┐    ┌─────────────────┐              │
│ Arc Blockchain  │    │ Smart Contracts │              │
│ (Port 8545)    │◄──►│   Organized     │──────────────┘
│                 │    │   by Ecosystem  │
│  Public State   │    │                 │
└─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```
privacy-preserving-defi/
├── README.md                   # This file - Project overview and setup
├── Makefile                    # Build and deployment commands
├── smart-contracts/           # 🆕 All smart contracts organized by ecosystem
│   ├── README.md             # Smart contracts overview and guide
│   ├── addresses.json         # Contract addresses for all networks
│   ├── evm/                 # Ethereum Virtual Machine contracts
│   │   ├── README.md         # EVM contract documentation
│   │   ├── *.sol            # Solidity contract sources
│   │   ├── script/           # Foundry deployment scripts
│   │   ├── test/            # Contract tests
│   │   └── foundry.toml      # Foundry configuration
│   └── midnight/             # Midnight Compact contracts
│       ├── README.md         # Midnight contract documentation
│       ├── *.compact         # Compact contract sources
│       ├── witnesses.ts      # Witness definitions
│       └── package.json     # NPM configuration
├── midnight-integration/       # Midnight.js integration service
│   ├── src/                  # TypeScript source files
│   ├── package.json          # Node.js service configuration
│   └── Dockerfile            # Container configuration
├── tee-service/               # TEE application (Rust)
│   ├── src/                  # Rust source files
│   ├── Cargo.toml           # Rust dependencies
│   └── config.toml          # Service configuration
├── frontend/                  # User interface
│   └── index.html           # Simple web UI
├── scripts/                   # Development and deployment scripts
│   ├── dev.sh               # Local development commands
│   ├── cloud.sh             # Cloud deployment commands
│   └── README.md            # Script documentation
├── cicd/                      # CI/CD and Docker configurations
│   ├── docker-compose.yml   # Local development services
│   ├── docker-compose.prod.yml # Production services
│   └── *.yaml               # Cloud Build configurations
├── terraform/                 # Infrastructure as Code
│   ├── *.tf                 # GCP resources definition
│   └── scripts/             # Setup scripts
└── docs/                      # Documentation files
    ├── CURRENT_STATUS.md    # Current system status
    ├── REQUIREMENTS.md      # Detailed requirements
    └── *.md                 # Additional documentation
```

## 🚀 Quick Start

### Prerequisites

- **Node.js 20+** - For Midnight integration service
- **Rust 1.70+** - For TEE service
- **Docker/Podman** - For containerized services
- **Make** - For build automation
- **Foundry** - For EVM contract development (optional)

### 🏠 Local Development

#### Start All Services (Recommended)
```bash
# Start development environment with mock proofs
make dev-start

# Check service status
make dev-status

# View logs
make dev-logs

# Stop all services
make dev-stop
```

#### Build Components
```bash
# Build Midnight Compact contract structure
make build-compact

# Build Midnight integration service
make build-midnight-integration

# Run tests
make test
```

#### Service URLs (Local)
- **Frontend**: http://localhost:3000
- **TEE Service**: http://localhost:8080
- **Midnight Integration**: http://localhost:3001
- **Arc Blockchain**: http://localhost:8545
- **Midnight Proof Server**: http://localhost:6300

### 🌩️ Cloud Deployment

#### Deploy to Google Cloud
```bash
# Build and push application image
make cloud-build

# Deploy infrastructure and application
make cloud-deploy

# Check deployment status
make cloud-status

# View service logs
make cloud-logs

# Test deployed service
make cloud-test
```

#### Cleanup Cloud Resources
```bash
# Destroy all cloud infrastructure
make cloud-destroy
```

### 🧪 Testing the System

#### Test API Endpoints
```bash
# Health check
curl http://localhost:8080/healthz

# Create session
curl -X POST http://localhost:8080/api/v1/session \
  -H "Content-Type: application/json" \
  -d '{"user_address":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8","signature":"0x1234567890abcdef"}'

# Process deposit
curl -X POST http://localhost:8080/api/v1/deposit \
  -H "Content-Type: application/json" \
  -d '{"user_address":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8","user_pubkey":"midnight1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz3fzypf","amount":"1000","asset":"USDC"}'
```

#### Test Midnight Integration
```bash
# Test Midnight integration service directly
curl -X POST http://localhost:3001/generate-concentration-proof \
  -H "Content-Type: application/json" \
  -d '{"userAmount":"1000","currentTvl":"100000","limit":"10000"}'
```

## 🎯 User Journey Demo

1. **Access Frontend**: Open http://localhost:3000
2. **Initiate Deposit**: Submit deposit request (e.g., 1,000 USDC)
3. **Compliance Check**: TEE verifies user KYC status on Arc
4. **Risk Check**: TEE privately validates 10% TVL concentration limit
5. **ZK Proof Generation**: Midnight integration creates ZK proofs
6. **Settlement**: TEE executes deposit on Arc with ZK proof attachment
7. **Cross-chain Reference**: Midnight transaction reference created

## ✨ Key Features Demonstrated

- **🔒 Privacy**: User balances remain confidential on Midnight network
- **⚖️ Risk Management**: 10% TVL concentration limit enforced privately
- **🔄 Atomicity**: Cross-chain transaction coordination via TEE
- **🧮 Zero Knowledge**: ZK proofs of private state transitions
- **🛡️ TEE Security**: Intel TDX enclave for trusted computation
- **🏗️ Modular Architecture**: Clean separation of blockchain ecosystems

## 📋 Available Commands

### Development Commands
```bash
make help           # Show all available commands
make dev-start      # Start local development services
make dev-stop       # Stop local services
make dev-restart    # Restart local services
make dev-status     # Show service status
make dev-logs       # View service logs
make dev-clean      # Clean local resources
```

### Build Commands
```bash
make build-compact           # Build Compact contract structure
make build-midnight-integration # Build Midnight integration service
make test                    # Run all tests
```

### Cloud Commands
```bash
make cloud-build    # Build and push application image
make cloud-deploy   # Deploy to Google Cloud
make cloud-destroy  # Destroy cloud infrastructure
make cloud-status   # Check deployment status
make cloud-logs     # View cloud service logs
make cloud-test     # Test deployed service
```

### Production Demo
```bash
make demo-start     # Start production demo (real proofs)
make demo-stop      # Stop production demo
```

## 🏗️ Architecture Components

### Smart Contracts
- **EVM Contracts** (`smart-contracts/evm/`):
  - `DeFiVault.sol` - Arc contract accepting ZK proofs
  - `MockUSDC.sol` - ERC20 token for testing
  - `ComplianceRegistry.sol` - KYC/compliance verification

- **Midnight Contracts** (`smart-contracts/midnight/`):
  - `defi-vault.compact` - Private balance management
  - `witnesses.ts` - Witness function definitions

### Services
- **TEE Service** (`tee-service/`): Rust-based trusted execution environment
- **Midnight Integration** (`midnight-integration/`): Node.js ZK proof service
- **Frontend** (`frontend/`): Simple web interface

### API Endpoints
- `GET /healthz` - Service health check
- `POST /api/v1/session` - Establish secure session
- `POST /api/v1/deposit` - Execute private deposit flow
- `POST /generate-concentration-proof` - Generate concentration limit proof

## 🔧 Development Workflow

### Smart Contract Development
```bash
# EVM contracts
cd smart-contracts/evm
forge test                    # Run tests
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Midnight contracts
cd smart-contracts/midnight
npm install                   # Install dependencies
compact compile defi-vault.compact  # Compile contract
```

### Service Development
```bash
# TEE service (Rust)
cd tee-service
cargo run                     # Run service
cargo test                    # Run tests
cargo watch -x run           # Run with hot reload

# Midnight integration (Node.js)
cd midnight-integration
npm run dev                   # Run development server
npm run build                 # Build for production
npm test                      # Run tests
```

## 📊 Current Status

### ✅ Working Components
- **Local Development**: All services running with mock proofs
- **Smart Contract Organization**: Clean structure by ecosystem
- **API Integration**: Complete REST API functionality
- **Build Processes**: Automated building and testing
- **Documentation**: Comprehensive guides and API docs

### ⚠️ Limitations
- **Mock ZK Proofs**: Using deterministic mock proofs (Midnight packages not public)
- **Midnight Node**: Blocked by upstream chain_spec issues
- **Single TEE Instance**: Not decentralized in current MVP

### 🚧 Production Path
When Midnight ecosystem dependencies become available:
1. Replace mock proofs with real Compact compiler output
2. Connect to working Midnight node
3. Deploy to production TEE infrastructure
4. Implement hardware wallet integration

## 🧹 Cleanup

```bash
# Clean local development environment
make dev-clean

# Destroy cloud deployment
make cloud-destroy

# Remove all build artifacts
make clean
```