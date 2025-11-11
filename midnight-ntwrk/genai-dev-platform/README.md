# 🌙 Midnight Development Platform

A vibe coding platform for Midnight Network that leverages OpenCode TUI, Vertex AI for model selection, and Google Cloud Workstations for developer environments. This platform provides a seamless development experience with AI-powered coding assistance and cloud-based workstations.

## 🚀 Overview

The Midnight Development Platform creates a comprehensive development environment that includes:

- **OpenCode TUI** - Terminal-based code editor with AI integration
- **Vertex AI Integration** - Access to Google's AI models for intelligent code assistance
- **Google Cloud Workstations** - Managed development environments in the cloud
- **Local Development** - Full local development setup using Podman
- **Midnight Network Tools** - Specialized tools for blockchain development

## 📁 Project Structure

```
genai-dev-platform/
├── cicd/                          # CI/CD configurations
│   └── cloudbuild/               # Cloud Build configurations
│       ├── cloudbuild.yaml       # Main deployment pipeline
│       └── cloudbuild-destroy.yaml # Resource cleanup pipeline
├── config/                       # Configuration files
│   ├── 110_start-code-oss-custom.sh    # Code OSS startup
│   ├── 120_code-oss-port-config.sh     # Port configuration
│   ├── 200_midnight-services.sh        # Midnight network services
│   ├── 210_default-ide-settings.sh    # Default IDE settings
│   ├── 220_vertex-ide-config.sh        # Vertex AI integration
│   ├── indexer-config.yaml             # Indexer configuration
│   └── midnight-node-config.toml       # Node configuration
├── docs/                         # Documentation
│   ├── container-customization.md      # Container setup guide
│   ├── gcp-deployment.md               # GCP deployment guide
│   ├── gcp-terraform-deployment.md     # Terraform deployment
│   ├── midnight-development-stack.md  # Midnight development guide
│   ├── opencode-access.md              # OpenCode access guide
│   └── terraform-modules.md            # Terraform modules guide
├── scripts/                      # Automation scripts
│   ├── gcloud-commands.sh       # Google Cloud operations
│   └── local.sh                 # Local development commands
├── terraform/                    # Infrastructure as Code
│   ├── modules/                 # Terraform modules
│   │   ├── dns/                 # DNS configuration
│   │   ├── networking/          # Network setup
│   │   ├── registry/            # Artifact Registry
│   │   └── workstations/        # Workstation configuration
│   ├── backend.tf               # Terraform backend
│   ├── main.tf                  # Main infrastructure
│   ├── outputs.tf               # Output definitions
│   ├── variables.tf             # Variable definitions
│   └── versions.tf              # Provider versions
├── Dockerfile                   # Container image definition
├── Makefile                     # Build and deployment commands
├── .env.example                 # Environment variables template
└── README.md                    # This file
```

## 🛠️ Makefile Commands

The platform uses a Makefile-based interface for all operations. Set up your environment by copying `.env.example` to `.env` and configuring your variables.

### 🏗️ Main Commands

```bash
# Deploy the entire platform to Google Cloud
make deploy

# Destroy all cloud resources
make undeploy

# Run locally in secure mode
make run-local
```

### 🖥️ Workstation Management

```bash
# Start a specific workstation
make ws-start WORKSTATION_ID=midnight-developer-1

# Stop a workstation
make ws-stop WORKSTATION_ID=midnight-developer-1

# Open Code OSS in browser
make ws-open

# Create tunnel to localhost:8080
make ws-tunnel
```

### 🏠 Local Development

```bash
# Build the container image
make build

# Run the development environment
make run

# Stop all services
make stop

# Clean up resources
make clean

# Check service status
make status

# View logs
make logs

# Database operations
make db

# Restart services
make restart

# Execute commands in container
make exec <command>
```

## 🚀 Quick Start

### 1. Prerequisites

- Google Cloud SDK installed and configured
- Podman for local development
- Appropriate GCP permissions for workstation creation

### 2. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit with your configuration
nano .env
```

Required environment variables:
- `PROJECT_ID` - Your Google Cloud project ID
- `REGION` - GCP region (default: us-central1)
- `ENVIRONMENT` - Environment label (default: dev)

### 3. Deploy to Google Cloud

```bash
# Deploy the entire platform
make deploy

# This will:
# - Build and push container image
# - Deploy Terraform infrastructure
# - Configure Google Cloud Workstations
# - Set up Vertex AI integration
```

### 4. Access Your Workstation

After deployment, access your workstation at:
```
https://<workstation-id>.cluster-<hash>.cloudworkstations.dev
```

## 🏠 Local Development

For local development using Podman:

```bash
# Build and run locally
make build
make run

# The environment includes:
# - OpenCode TUI with AI integration
# - Midnight Network development tools
# - Vertex AI model access
# - Local development services
```

### 🌙 Midnight Development Stack

The platform includes a complete Midnight Network development environment that runs automatically in each workstation:

**In Google Cloud Workstation:**
```bash
# Services start automatically on workstation access
# Management commands available:

midnight-dev status    # Show service status
midnight-dev logs      # View logs (node/proof/indexer/all)
midnight-dev restart    # Restart all services
```

**Available Services:**
- **Midnight Node**: http://localhost:9944 (WebSocket: ws://localhost:9944)
- **Proof Server**: http://localhost:8081 (ZK proof generation)
- **Indexer API**: http://localhost:8088 (Data indexing)
- **PostgreSQL**: localhost:5432 (Database)

**Database Connection:**
- Host: localhost
- Port: 5432
- User: postgres
- Password: (no password required)
- Database: midnight_dev, midnight_test, indexer_db

**Management Commands:**
```bash
# Show service status and logs
midnight-dev status

# Follow logs for specific service
midnight-dev logs node          # Node logs
midnight-dev logs proof         # Proof server logs
midnight-dev logs indexer       # Indexer logs
midnight-dev logs all          # All logs

# Restart all services
midnight-dev restart
```

This setup allows developers to:
- Test smart contracts before deployment
- Develop DApps with full Midnight Network stack
- Use ZK proofs for confidential transactions
- Index and query blockchain data
- Iterate quickly with local feedback

## 🔧 Configuration

### Workstation Configuration

Workstations are configured in `terraform/modules/workstations/main.tf` with:

- **Machine Type**: Configurable (default: e2-standard-4)
- **Persistent Disk**: 100GB standard persistent disk
- **Service Account**: Dedicated SA with Vertex AI permissions
- **Environment Variables**: Pre-configured for Vertex AI and Midnight services

### Vertex AI Integration

The platform includes Vertex AI integration through:

- Environment variables for project and region
- Service account with `roles/aiplatform.user`
- Pre-configured gcloud settings
- Model selection interface in OpenCode

### Container Customization

The container image (`Dockerfile`) includes:

- OpenCode TUI with custom configurations
- Midnight Network development tools
- Vertex AI client libraries
- Development utilities and runtimes

## 📚 Documentation

- [Container Customization](docs/container-customization.md) - Container setup details
- [GCP Deployment](docs/gcp-deployment.md) - Google Cloud deployment guide
- [Terraform Modules](docs/terraform-modules.md) - Infrastructure modules
- [OpenCode Access](docs/opencode-access.md) - Code editor access guide

## 🌟 Features

- **AI-Powered Development**: Vertex AI integration for intelligent coding assistance
- **Cloud-Based Workstations**: Managed development environments with Google Cloud Workstations
- **Terminal-Based Editor**: OpenCode TUI for efficient coding
- **Complete Midnight Stack**: Integrated proof server, node, indexer, and PostgreSQL
- **Blockchain Development**: Specialized tools for Midnight Network development
- **Local Development**: Full local development environment with Docker/Podman
- **Infrastructure as Code**: Complete Terraform-based deployment
- **CI/CD Integration**: Automated builds and deployments with Cloud Build
- **ZK Proof Support**: Built-in zero-knowledge proof generation and verification
- **Data Indexing**: Real-time blockchain data indexing and query API

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `make run`
5. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for the full license text.

   Copyright 2025 Dcentral Labs

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.


---

**Built with ❤️ for the Midnight Network community**