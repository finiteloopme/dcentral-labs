# Midnight Development Platform - MVP

A cloud-native development platform for building privacy-preserving DApps on Midnight Network using Google Cloud Workstations.

## 🚀 Features

- **Zero Local Setup**: Browser-based development environment
- **Pre-configured Tools**: Midnight compiler, proof generator, and development tools
- **AI Code Assistant**: OpenCode AI with modern web terminal interface (@xterm/xterm)
- **Quick Start Template**: Basic token DApp template ready to deploy
- **Integrated Proof Service**: Generate and verify zero-knowledge proofs
- **Cloud-Native**: Fully managed infrastructure on Google Cloud Platform
- **Container Agnostic**: Works with both Podman and Docker
- **State Management**: Terraform state stored securely in GCS

## 📋 Prerequisites

- Google Cloud Platform account
- `gcloud` CLI installed
- Terraform 1.5+
- Podman or Docker (container runtime)
- Basic knowledge of smart contracts

## 🏃 Quick Start

### One-Command Deployment

```bash
# Clone the repository
git clone https://github.com/midnight-network/cloud-platform
cd cloud-platform

# Deploy everything with one command
make setup PROJECT_ID=YOUR_PROJECT_ID

# Or use the deployment script directly
./scripts/deploy.sh YOUR_PROJECT_ID
```

### What Gets Deployed

1. **APIs**: Automatically enabled via Terraform
2. **State Management**: GCS bucket for Terraform state
3. **Infrastructure**: VPC, Cloud Workstations, Artifact Registry
4. **Container**: Built and pushed to registry
5. **Access**: Workstation URL provided at completion

## 📁 Project Structure

```
midnight-development-platform/
├── terraform/              # Infrastructure as Code
│   ├── modules/           # Terraform modules
│   │   ├── networking/    # VPC and networking
│   │   ├── workstations/  # Cloud Workstations
│   │   └── registry/      # Artifact Registry
│   ├── main.tf           # Main configuration
│   ├── backend.tf        # GCS backend configuration
│   └── variables.tf      # Variable definitions
├── docker/                # Container configuration
│   ├── Dockerfile        # Workstation image
│   ├── scripts/          # Startup scripts
│   └── templates/        # DApp templates
├── proof-service/         # Proof generation service
│   └── src/              # Service implementation
├── scripts/              # Shell scripts
│   ├── common.sh         # Shared functions
│   ├── deploy.sh         # Main deployment script
│   ├── terraform-init.sh # Terraform initialization
│   ├── terraform-deploy.sh # Infrastructure deployment
│   ├── build.sh          # Container building
│   ├── push.sh           # Registry push
│   ├── status.sh         # Status checking
│   ├── clean.sh          # Cleanup script
│   └── workstation.sh    # Workstation management
├── docs/                  # Documentation
│   ├── QUICK_START.md    # Getting started guide
│   ├── ARCHITECTURE.md   # System architecture
│   ├── API.md            # API documentation
│   ├── WORKSTATION_MANAGEMENT.md # Workstation guide
│   └── PODMAN.md         # Podman usage guide
└── Makefile              # Build automation
```

## 🛠️ Available Commands

### Core Operations
```bash
make help          # Show help and current settings
make setup         # Complete setup (init + deploy + build + push)
make init          # Initialize Terraform with GCS backend
make deploy        # Deploy infrastructure
make build         # Build container image
make push          # Push to registry
make run-local     # Run container locally for testing
make status        # Check deployment status
make clean         # Clean local artifacts
make destroy       # Destroy infrastructure
```

### Workstation Management
```bash
make workstation   # Show workstation management help
make list          # List all workstations
make start         # Start default workstation
make stop          # Stop default workstation
make ssh           # SSH into workstation
make logs          # View workstation logs
make port-forward  # Set up port forwarding (3000, 8080)
```

### Advanced Workstation Management
Use the `workstation.sh` script directly for more control:

```bash
# Create new workstation
./scripts/workstation.sh create my-workstation

# Start specific workstation
./scripts/workstation.sh start my-workstation

# SSH with custom command
./scripts/workstation.sh ssh --workstation my-workstation "ls -la"

# Port forwarding for specific project
./scripts/workstation.sh --project-id my-project port-forward

# Get workstation URL
./scripts/workstation.sh url

# View detailed info
./scripts/workstation.sh info
```

## 🔧 Configuration

### Environment Variables

```bash
PROJECT_ID=your-project-id  # GCP Project ID (required)
REGION=us-central1          # Deployment region
ZONE=us-central1-a          # Deployment zone
ENV=mvp                     # Environment name
```

### Workstation Specs (Default)

- **Machine Type**: e2-standard-4 (4 vCPU, 16 GB RAM)
- **Boot Disk**: 50 GB SSD
- **Persistent Disk**: 200 GB
- **Idle Timeout**: 20 minutes
- **Running Timeout**: 4 hours

## 🏗️ Building the Container Locally

The platform builds the container image locally on your machine before pushing it to Google Artifact Registry. This allows for customization and ensures you have full control over the development environment.

### Prerequisites for Container Building

Ensure you have either Podman or Docker installed:

```bash
# Check for Podman (recommended)
podman --version

# Or Docker
docker --version
```

### Building the Container

The container is automatically built during `make setup`, but you can also build it manually:

```bash
# Build using the script (auto-detects podman/docker)
./scripts/build.sh

# Or using Make
make build

# Or directly with your container runtime
podman build -t midnight-workstation:latest docker/
# or
docker build -t midnight-workstation:latest docker/
```

### Customizing the Container

To customize the development environment, edit `docker/Dockerfile`:

```dockerfile
# Example: Add custom tools
RUN apt-get update && apt-get install -y \
    your-custom-tool \
    another-tool

# Example: Add custom npm packages
RUN npm install -g \
    your-npm-package \
    another-package
```

After customizing, rebuild and push:

```bash
make build push
./scripts/workstation.sh update-config
./scripts/workstation.sh restart
```

### Testing the Container Locally

Before pushing to the registry, you can test the container locally:

```bash
# Easy way - using Make target
make run-local

# This will:
# - Start the container with port forwarding
# - Mount templates directory for live editing
# - Provide access URLs for all services
# - Clean up on exit (Ctrl+C)
```

Access points when running locally:
- **Service Dashboard**: http://localhost:7681/services (All services)
- **Web Terminal**: http://localhost:7681 (Full bash terminal)
- **OpenCode AI**: http://localhost:7681/opencode (Dedicated AI assistant)
- **Proof Service API**: http://localhost:8080 (ZK proof generation)
- **DApp Server**: http://localhost:3000 (When running)

You can also use custom ports or external services:
```bash
# Run with custom ports
APP_PORT=3001 PROOF_PORT=8081 make run-local

# Use external proof service instead of local mock
PROOF_SERVICE_URL=https://proof-api.midnight.network make run-local

# Or use the script directly
./scripts/run-local.sh

# Run specific image version
./scripts/run-local.sh midnight-workstation v1.0
```

#### Using External Proof Service

By default, the platform runs a mock proof service for development. To use an external proof service:

```bash
# Set the environment variable when running locally
PROOF_SERVICE_URL=https://your-proof-service.com make run-local

# Or in production workstations, set it in the container configuration
gcloud workstations configs update midnight-config \
    --env=PROOF_SERVICE_URL=https://your-proof-service.com
```

Manual container run (if needed):
```bash
# With Podman
podman run -it --rm \
    -p 3000:3000 \
    -p 8080:8080 \
    -p 8443:8443 \
    midnight-workstation:latest

# With Docker  
docker run -it --rm \
    -p 3000:3000 \
    -p 8080:8080 \
    -p 8443:8443 \
    midnight-workstation:latest
```

### Container Build Process

1. **Base Image**: Starts from Google's Cloud Workstations image with VS Code
2. **Development Tools**: Installs Node.js, npm, git, build tools
3. **AI Assistant**: Installs OpenCode AI with web terminal interface
4. **Web Terminal**: Sets up xterm.js-based terminal accessible via browser
5. **Midnight Tools**: Adds mock Midnight compiler and proof generator
6. **Templates**: Copies DApp templates into `/workspace/templates`
7. **Configuration**: Sets up environment variables and startup scripts

### Troubleshooting Container Builds

If the build fails:

```bash
# Clean up and retry
make clean
make build

# Build with no cache
podman build --no-cache -t midnight-workstation:latest docker/
# or
docker build --no-cache -t midnight-workstation:latest docker/

# Check build logs
podman build -t midnight-workstation:latest docker/ 2>&1 | tee build.log
```

## 🚀 Using the Platform

### 1. Access Your Workstation

After deployment, get your workstation URL:

```bash
make status
# or
./scripts/workstation.sh url
```

Open the URL in your browser to access the VS Code IDE.

### 2. Create a New DApp

In the workstation terminal:

```bash
# Option 1: Use the Midnight CLI
midnight new my-dapp
cd /workspace/projects/my-dapp

# Option 2: Use OpenCode for AI assistance
opencode
# Then ask: "Create a new Midnight token contract"
```

### 3. Compile Contracts

```bash
midnight compile
# or
make compile
```

### 4. Generate Proofs

```bash
midnight prove
# or
make prove
```

### 5. Deploy to Testnet

```bash
midnight deploy
# or
make deploy
```

### 6. Start Development Server

```bash
make dev
```

Access your DApp at `http://localhost:3000` in the workstation browser.

### 7. Local Development with Port Forwarding

For local development, set up port forwarding:

```bash
# In a separate terminal on your local machine
make port-forward
# or
./scripts/workstation.sh port-forward
```

Then access:
- DApp: http://localhost:3000
- Proof Service: http://localhost:8080

## 📚 Documentation

- [Quick Start Guide](docs/QUICK_START.md) - Get up and running in 10 minutes
- [Architecture Overview](docs/ARCHITECTURE.md) - System design and components
- [API Documentation](docs/API.md) - Proof service API reference
- [Workstation Management](docs/WORKSTATION_MANAGEMENT.md) - Complete workstation control guide
- [Podman Guide](docs/PODMAN.md) - Using Podman as container runtime

## 🧪 Testing

Run all tests:

```bash
make test
```

Test individual components:

```bash
# Test Terraform configuration
cd terraform && terraform validate

# Test container build
./scripts/build.sh

# Test proof service
cd proof-service && npm test

# Test token template
cd docker/templates/basic-token && npm test
```

## 🔍 Troubleshooting

### Workstation Not Starting

```bash
# Check workstation status
./scripts/workstation.sh status

# View detailed information
./scripts/workstation.sh info

# Check logs for errors
./scripts/workstation.sh logs

# Restart workstation
./scripts/workstation.sh restart
```

### Build Failures

```bash
# Clean and rebuild
make clean
make build
```

### Connection Issues

```bash
# Check service health
curl http://localhost:8080/health

# Ensure workstation is running
make status

# Try port forwarding
make port-forward
```

## 📈 Monitoring

View workstation logs:

```bash
make logs
# or
./scripts/workstation.sh logs
```

Check resource usage:

```bash
./scripts/workstation.sh info
```

## 🔒 Security

- All traffic encrypted with TLS
- IAP-based authentication
- Private VPC with NAT gateway
- No public IPs on workstations
- Automated security updates
- Terraform state encrypted in GCS

## 💰 Cost Estimation

Estimated monthly costs (MVP configuration):

- Cloud Workstations: ~$150/month (assuming 8 hours/day usage)
- Networking: ~$20/month
- Storage: ~$10/month
- **Total**: ~$180/month

**Cost Optimization Tips:**
- Stop workstations when not in use: `make stop`
- Use appropriate idle timeout settings
- Monitor usage with GCP billing reports

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [docs.midnight.network](https://docs.midnight.network)
- **GitHub Issues**: [Create an issue](https://github.com/midnight-network/cloud-platform/issues)
- **Discord**: [Join our community](https://discord.gg/midnight)
- **Email**: support@midnight.network

## 🎯 Roadmap

### MVP (Current) ✅
- ✅ Basic Cloud Workstations setup
- ✅ Single region deployment
- ✅ Mock proof service
- ✅ Basic token template
- ✅ Container runtime agnostic (Podman/Docker)
- ✅ GCS backend for Terraform state
- ✅ Comprehensive workstation management

### Phase 2 (Production)
- [ ] Multi-region support
- [ ] Real Midnight compiler integration
- [ ] Production proof service
- [ ] Multiple DApp templates
- [ ] CI/CD integration
- [ ] Monitoring dashboard

### Phase 3 (Enterprise)
- [ ] Private clusters
- [ ] VPN connectivity
- [ ] SSO integration
- [ ] Compliance controls
- [ ] Team collaboration features
- [ ] Advanced RBAC

## 🏁 Demo Scenarios

### Quick Local Testing (No GCP Required)

Test the development environment locally before deploying to GCP:

```bash
# 1. Build container
make build

# 2. Run locally
make run-local

# 3. Access services:
#    - VS Code: http://localhost:8443
#    - DApp: http://localhost:3000
#    - Proof Service: http://localhost:8080

# 4. Stop with Ctrl+C
```

### Full Cloud Deployment

Try the complete flow with Cloud Workstations:

```bash
# 1. Deploy everything
make setup PROJECT_ID=your-project-id

# 2. Start workstation and get URL
./scripts/workstation.sh start

# 3. Set up port forwarding (in another terminal)
./scripts/workstation.sh port-forward

# 4. Access the workstation URL in browser

# 5. In the workstation terminal:
midnight new demo-token
cd /workspace/projects/demo-token
make compile
make test
make prove
make deploy
make dev

# 6. Access locally at http://localhost:3000

# 7. When done, stop the workstation
make stop
```

## 🔄 Updates and Maintenance

### Update Container Image
```bash
make build push
./scripts/workstation.sh update-config
./scripts/workstation.sh restart
```

### Update Infrastructure
```bash
# Modify terraform files as needed
make deploy
```

### Clean Up Resources
```bash
# Stop all workstations
./scripts/workstation.sh list
make stop

# Destroy infrastructure (keeps state bucket)
make destroy

# Complete cleanup including state
make clean
```

---

Built with ❤️ for the Midnight Network community