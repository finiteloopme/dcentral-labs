# Web3 Cloud Workstation

A production-ready development environment for Web3 and smart contract development, deployable both locally and on Google Cloud.

## Features

- 🔨 **Foundry** - forge, cast, anvil for Ethereum development
- 💻 **Code-OSS IDE** - VS Code in the browser with Remix IDE extension  
- 🤖 **OpenCode TUI** - AI-powered terminal interface with Vertex AI support
- 🧠 **Vertex AI Models** - Access to Gemini 2.0 and Claude models
- 🐳 **Podman/Docker** - Rootless container support
- ☁️ **Cloud Native** - Google Cloud Workstations integration
- 🔄 **CI/CD** - Automated deployments with Cloud Build

## Quick Start

### Local Development (No Cloud Required)

```bash
# Run locally for testing
make local

# Access at:
# - IDE: http://localhost:8000
# - Terminal: http://localhost:8080
```

### Cloud Deployment

```bash
# Set your GCP project
export PROJECT_ID=your-gcp-project-id

# Complete automated setup
make quick-start
```

## Installation

### Prerequisites

Choose **one** of these options:

**Option 1: Auto-install**
```bash
make install-deps
```

**Option 2: Manual install**
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) (for Vertex AI)
- [Terraform](https://www.terraform.io/downloads) (for cloud deployment)
- [Podman](https://podman.io/getting-started/installation) or [Docker](https://docs.docker.com/get-docker/)

### Configuration

```bash
# For Vertex AI support (optional)
export GOOGLE_CLOUD_PROJECT=your-gcp-project-id

# For cloud deployment
export PROJECT_ID=your-gcp-project-id
export REGION=us-central1  # default
```

## Local Development

### Getting Started

```bash
# Build and run the container locally
make local

# Or run with custom settings
make local MEMORY=8g CPUS=4
```

### Service Endpoints

Once the container is running, the following services are available:

| Service | URL | Description |
|---------|-----|-------------|
| **VS Code IDE** | http://localhost:8000 | Full VS Code in browser with Solidity support |
| **OpenCode Terminal** | http://localhost:8080 | Web-based terminal with AI assistance |
| **Container Shell** | `make shell` | Direct terminal access to container |

### Container Management

```bash
# Check container status
make status

# Stop the container
make stop

# View container logs
make logs

# Enter container shell
make shell

# Clean up (remove container and image)
make clean
```

### Working Directory

Your work is persisted in `~/web3-workspace/` on your host machine:
- `projects/` - Your development projects
- `.config/` - Configuration files
- Files persist between container restarts

### Development Workflow

```bash
# 1. Start the environment
make local

# 2. Open VS Code in browser
# Navigate to http://localhost:8000

# 3. Or use the terminal interface
# Navigate to http://localhost:8080

# 4. Inside the container, create a new project
forge init my-project
cd my-project
forge build
forge test

# 5. Use OpenCode AI assistant
opencode

# 6. Deploy locally with Anvil
anvil  # Start local blockchain
forge script Deploy.s.sol --rpc-url http://localhost:8545
```

### AI Integration (Vertex AI)

To use AI models with OpenCode:

```bash
# Set your Google Cloud project
export GOOGLE_CLOUD_PROJECT=your-project-id

# Authenticate (one time)
gcloud auth application-default login

# Start container with credentials
make local

# Inside container, models are pre-configured
opencode
# Use /model to switch between models
/model google-vertex/gemini-2.0-flash-exp
```

## Usage

### Essential Commands

| Command | Description |
|---------|------------|
| `make help` | Show available commands |
| `make quick-start` | Complete cloud setup and deployment |
| `make local` | Run locally without cloud |
| `make deploy` | Deploy to Google Cloud |
| `make status` | Show deployment status |
| `make destroy` | Destroy cloud infrastructure |

## Project Structure

```
├── docker/           # Container configuration
├── terraform/        # Infrastructure as code
├── scripts/          # Automation scripts  
├── cloudbuild.yaml   # CI/CD pipeline
└── Makefile         # Task automation
```

## Documentation

- [Local Development Guide](LOCAL_DEVELOPMENT.md)
- [Vertex AI Setup Guide](VERTEX_AI_SETUP.md)
- [Cloud Build CI/CD](CLOUD_BUILD.md)
- [All Makefile Targets](MAKEFILE_TARGETS.md)

## Costs

**Local**: Free (uses your machine's resources)

**Cloud**: ~$70/month
- Workstation (e2-standard-4): ~$60/month
- Storage (200GB): ~$8/month  
- Network: ~$2/month

*Auto-shutdown after 4 hours idle saves costs*

## Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Docs**: Run `make docs` for all documentation

## License

MIT