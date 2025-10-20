# 🌙 Midnight Development Platform

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/terraform-1.5.0-purple.svg)](https://www.terraform.io/)
[![GCP](https://img.shields.io/badge/GCP-Cloud%20Workstations-blue.svg)](https://cloud.google.com/workstations)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen.svg)](https://www.docker.com/)

A cloud-native development platform for building privacy-preserving DApps on the Midnight Network. Features integrated proof generation, AI-powered coding assistance, and comprehensive tooling for zero-knowledge application development.

## ✨ Key Features

- **🔐 Integrated Proof Server**: Built-in Midnight proof server with local/external modes
- **🤖 AI-Powered Development**: OpenCode with Vertex AI (Claude, Gemini models)
- **⚡ Circuit-Enabled Contracts**: Templates with ZK proof circuits
- **☁️ Cloud-Native**: Google Cloud Workstations with Terraform automation
- **🚀 Simplified CI/CD**: Streamlined Cloud Build in `cicd/` directory
- **🧪 Comprehensive Testing**: Integration tests for all components
- **🛠️ Complete Toolchain**: Compiler, proof tools, and deployment automation

## 📋 Prerequisites

- Google Cloud Project with billing enabled
- `gcloud` CLI installed and authenticated
- Terraform 1.5.0+ (optional, can use Cloud Build)
- Docker or Podman (for local testing)

## 🚀 Quick Start

### One-Command Cloud Deployment

```bash
# Clone the repository
git clone https://github.com/midnight-network/coding-platform
cd coding-platform

# Setup and deploy (choose one method)

# Option 1: Traditional setup with local Terraform
make setup PROJECT_ID=your-project-id

# Option 2: Cloud Build setup (recommended)
make cloud-setup PROJECT_ID=your-project-id
make cloud-deploy-plan  # Review changes first
make cloud-deploy       # Apply changes
```

### Local Development

```bash
# Build and run locally (works with both Docker and Podman)
make build
make run-local

# Or use the convenience script
cd docker
./run-local-simple.sh

# Access services
# Code OSS IDE: http://localhost:8080
# Proof Service: http://localhost:8081
```

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────┐
│                   Google Cloud Platform                │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Cloud      │  │   Cloud      │  │  Artifact    │  │
│  │   Build      │──│ Workstations │  │  Registry    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │        │
│         ▼                  ▼                  ▼        │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Midnight Workstation Container           │  │
│  ├──────────────────────────────────────────────────┤  │
│  │  • Proof Server (Local/External)                 │  │
│  │  • OpenCode AI (Vertex AI Integration)           │  │
│  │  • Midnight Compiler & Tools                     │  │
│  │  • Circuit Development Environment               │  │
│  │  • Web Terminal & VS Code                        │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │          CI/CD Pipelines (cicd/cloudbuild/)      │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

## 📦 What Gets Deployed

1. **Infrastructure** (via Terraform)
   - VPC Network and Subnets
   - Cloud Workstations Cluster
   - Artifact Registry Repository
   - IAM Roles and Service Accounts
   - GCS Bucket for Terraform State

2. **Container Image** (Midnight Workstation)
   - Midnight proof server (v4.0.0 API)
   - OpenCode AI with Vertex AI integration
   - Compact compiler and tools
   - Circuit templates and examples
   - Web-based development environment
   - Midnight Compact VSCode extension (v0.2.13)

3. **Automation** (Cloud Build)
   - CI/CD pipelines in `cicd/cloudbuild/`
   - Automated deployments
   - Infrastructure as Code
   - GitOps-ready workflows

## 🎯 Core Commands

### Essential Commands

```bash
# Complete setup (first time)
make setup PROJECT_ID=your-project

# Deploy infrastructure
make deploy PROJECT_ID=your-project

# Build and push container
make build
make push PROJECT_ID=your-project

# Run tests
make test
```

### Cloud Build Automation (Recommended)

```bash
# Initial setup (one time)
make cloud-setup PROJECT_ID=your-project

# Deploy via Cloud Build
make cloud-deploy ENV=dev

# Check status
make cloud-status

# Diagnose issues
make cloud-diagnose
```

### Local Development

```bash
# Run locally for testing
make run-local

# Docker Compose services
make compose-up
make compose-down
make compose-logs

# Run tests
make test
```

### Workstation Management

```bash
# List workstations
make ws-list

# Start workstation
make ws-start

# Stop workstation  
make ws-stop

# SSH access
make ws-ssh

# Get access URL
make ws-url
```

## 🔧 Configuration

### Environment Variables

```bash
# Core settings
PROJECT_ID=your-gcp-project
REGION=us-central1
ZONE=us-central1-a
ENV=dev                    # dev/staging/prod

# Proof Service
PROOF_SERVICE_MODE=local   # local/external
PROOF_SERVICE_URL=         # URL for external service
PROOF_SERVICE_PORT=8080

# OpenCode AI (auto-configured)
GCP_PROJECT_ID=your-project  # For Vertex AI
```

### Proof Service Modes

#### Local Mode (Default)
- Runs proof server inside container
- Zero network latency
- No external dependencies

#### External Mode
```bash
PROOF_SERVICE_MODE=external
PROOF_SERVICE_URL=https://proof-api.midnight.network
```

### Multi-Environment Support

```bash
# Deploy to different environments
make deploy ENV=dev
make deploy ENV=staging
make deploy ENV=prod

# Or with Cloud Build
make cloud-deploy ENV=staging
```

## 🛠️ Development Workflow

### 1. Create a New DApp

```bash
# In the workstation
midnight new my-dapp
cd projects/my-dapp
```

### 2. Develop Smart Contracts

```compact
// contracts/Token.compact
contract Token {
    @shielded
    mapping(address => uint256) balances;
    
    export circuit proveBalance(
        address account,
        uint256 balance
    ) {
        assert balances[account] == balance;
    }
}
```

### 3. Compile and Test

```bash
# Compile contracts
midnight compile

# Run tests
midnight test

# Generate proofs
midnight prove

# Verify proofs
midnight verify build/Token.proof
```

### 4. Deploy to Network

```bash
# Deploy to testnet
midnight deploy
```

## 🤖 AI-Powered Development

OpenCode AI is pre-configured with Vertex AI models:

```bash
# In the workstation terminal
opencode

# Or use web interface
http://localhost:7681/opencode
```

### Available Models
- Claude Opus 4.1 (default)
- Claude 3.5 Sonnet v2
- Claude 3.5 Haiku
- Gemini 2.5 Flash
- Gemini 2.5 Pro

### Expert Assistance
OpenCode is configured as an expert in:
- Web3 and blockchain security
- Zero-knowledge proofs
- Midnight's Compact language
- Circuit development
- DApp architecture

## 📝 VSCode Extension

The Midnight Compact VSCode extension (v0.2.13) is automatically installed, providing:

### Features
- **Syntax Highlighting**: Full syntax support for `.compact` files
- **IntelliSense**: Code completion and parameter hints
- **Error Detection**: Real-time error checking and diagnostics
- **Integrated Compiler**: Compile contracts directly from VS Code
- **Code Navigation**: Go to definition, find references

### Usage
```bash
# The extension is automatically installed on startup
# To manually install or update:
install-midnight-extension

# To update to a specific version:
update-midnight-extension 0.2.14
```

### Working with Compact Files
1. Open any `.compact` file in VS Code
2. The extension activates automatically
3. Use Ctrl+Shift+B to compile
4. Errors appear in the Problems panel

## 🧪 Testing

### Integration Tests

```bash
# Run all tests
make test

# Test specific components
./scripts/test-integration.sh
```

### Circuit Testing

```bash
# Test individual circuits
./test-circuit.sh proveBalance

# Test all circuits
make prove
make verify
```

## 📊 Monitoring & Debugging

### Check Status

```bash
# Overall deployment status
make status

# Cloud Build status
make cloud-status

# Diagnose Cloud Build issues
make cloud-diagnose
```

### Access Services

| Service | URL | Description |
|---------|-----|-------------|
| Service Dashboard | http://localhost:7681/services | All services overview |
| Web Terminal | http://localhost:7681 | Browser-based terminal |
| OpenCode AI | http://localhost:7681/opencode | AI coding assistant |
| VS Code | http://localhost:8443 | Web-based IDE |
| Proof Service | http://localhost:8080 | Proof generation API |

## 🚢 Production Deployment

### Using Cloud Build (Recommended)

```bash
# Setup Cloud Build for production
make cloud-setup PROJECT_ID=prod-project

# Deploy to production
make cloud-deploy ENV=prod

# Check deployment status
make cloud-status
```

### Multi-Environment Support

```bash
# Deploy to different environments
make cloud-deploy ENV=dev      # Development
make cloud-deploy ENV=staging  # Staging
make cloud-deploy ENV=prod     # Production
```

## 🔒 Security

- **Least Privilege IAM**: Minimal required permissions
- **State Encryption**: Terraform state encrypted at rest
- **Secret Management**: Integration with Secret Manager
- **Network Isolation**: Private VPC for workstations
- **Audit Logging**: All actions logged to Cloud Logging

## 💰 Cost Optimization

### Workstation Auto-Stop

Workstations automatically stop after idle timeout:
- Dev: 20 minutes
- Staging: 1 hour  
- Prod: 4 hours

### Resource Sizing

```hcl
# terraform.tfvars
workstation_config = {
  machine_type = "e2-standard-4"  # Adjust as needed
  boot_disk_size_gb = 50
  persistent_disk_size_gb = 200
}
```

## 🐛 Troubleshooting

### Common Issues

**Cloud Build Permission Errors**
```bash
# Diagnose and fix permissions
make cloud-diagnose
make cloud-setup  # Re-run setup to fix
```

**Workstation Won't Start**
```bash
# Check workstation status
make ws-list
```

**Local Development Issues**
```bash
# Restart Docker Compose services
make compose-down
make compose-up
```

## 📚 Documentation

- [Quick Start Guide](docs/QUICK_START.md)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Cloud Build Guide](docs/CLOUD_BUILD.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Vertex AI Setup](docs/VERTEX_AI_SETUP.md)
- [Proof Service](docs/PROOF_SERVICE.md)

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/coding-platform
cd coding-platform

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and test
make test

# Submit PR
```

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Midnight Network team for the proof server
- Google Cloud for Cloud Workstations
- Anthropic for Claude models via Vertex AI
- The Web3 community

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/midnight-network/coding-platform/issues)
- **Discussions**: [GitHub Discussions](https://github.com/midnight-network/coding-platform/discussions)
- **Documentation**: [Online Docs](https://midnight-network.github.io/coding-platform)

---

**Built with ❤️ for the Midnight Network community**

*Empowering developers to build privacy-preserving applications*