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
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://www.terraform.io/downloads) 
- [Podman](https://podman.io/getting-started/installation) or [Docker](https://docs.docker.com/get-docker/)

### Configuration

```bash
# Required for cloud deployment
export PROJECT_ID=your-gcp-project-id

# Optional
export REGION=us-central1  # default
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

### Development Workflow

```bash
# Start local environment
make local

# Inside container
forge init my-project
cd my-project
forge build
forge test

# Or use OpenCode with AI assistance
opencode

# Configure Vertex AI (first time only)
opencode auth login  # Select vertex-ai
# Enter your GCP project ID when prompted
```

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