# OCI Container Configurations

This directory contains Open Container Initiative (OCI) compatible container definitions for the ABI Assistant MCP Server.

## Container Images

### Production (`Dockerfile`)
Multi-stage build for the production MCP server:
- Builds optimized Rust binary
- Minimal runtime image with Debian slim
- Non-root user for security
- Health check endpoint
- Port 3000 exposed

**Build:** `podman build -f oci/Dockerfile -t abi-assistant:latest .`  
**Run:** `podman run -p 3000:3000 abi-assistant:latest`

### Development (`Dockerfile.dev`)
Development container with full Rust toolchain:
- Rust 1.79 with rustfmt and clippy
- Development tools (git, vim, curl)
- Volume mounts for live development
- Cargo watch for auto-reload

**Build:** `podman build -f oci/Dockerfile.dev -t abi-assistant-dev:latest .`  
**Run:** See `scripts/podman-dev.sh`

### Anvil Testing (`Dockerfile.anvil`)
Local Ethereum node for testing:
- Foundry's Anvil
- Pre-configured test accounts
- Fork mainnet capability
- Port 8545 exposed

**Build:** `podman build -f oci/Dockerfile.anvil -t abi-assistant-anvil:latest .`  
**Run:** See `scripts/anvil-start.sh` or `scripts/anvil-fork.sh`

## Docker Compose

The `docker-compose.yml` file provides:
- Complete development environment
- Service orchestration
- Volume management
- Environment configuration

**Usage from project root:**
```bash
# Start all services
docker-compose -f oci/docker-compose.yml up

# Development mode
docker-compose -f oci/docker-compose.yml up dev

# Production mode
docker-compose -f oci/docker-compose.yml up abi-assistant
```

## Notes

- All builds should be run from the project root directory
- The `.dockerignore` file ensures clean builds
- Containers use Podman by default but are Docker-compatible
- See `/scripts` directory for container management utilities