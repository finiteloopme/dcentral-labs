# OCI (Open Container Initiative) Directory

This directory contains all container-related files for the ABI Assistant project, following OCI standards.

## 📁 Structure

```
oci/
├── Dockerfile              # Main application container (platform-agnostic)
├── Dockerfile.anvil        # Anvil blockchain container
├── Dockerfile.dev          # Development container with hot reload
├── docker-compose.yml      # Development environment with Anvil
├── docker-compose.prod.yml # Production environment
└── README.md              # This file
```

## 🐳 Dockerfiles

### `Dockerfile` - Main Application
Platform-agnostic container for the MCP server that works on:
- Local Docker/Podman
- GCP Cloud Run  
- AWS ECS/Fargate
- Azure Container Instances
- Kubernetes

**Features:**
- Multi-stage build for minimal size
- Automatic PORT detection for cloud platforms
- Flexible entrypoint script
- Non-root user for security
- Health checks included

### `Dockerfile.anvil` - Ethereum Test Blockchain
Anvil container for local blockchain testing.

**Features:**
- Configurable via environment variables
- Fork mainnet support
- Platform-agnostic port handling
- Built-in health checks

### `Dockerfile.dev` - Development Container
Development environment with hot reload.

**Features:**
- cargo-watch for automatic rebuilds
- Debug logging enabled
- Volume mounts for live code editing
- Development tools included

## 🚀 Usage

### Local Development

```bash
# Start all services (MCP + Anvil)
docker-compose -f oci/docker-compose.yml up -d

# Start with dev container (hot reload)
docker-compose -f oci/docker-compose.yml --profile dev up

# View logs
docker-compose -f oci/docker-compose.yml logs -f

# Stop services
docker-compose -f oci/docker-compose.yml down
```

### Production

```bash
# Build production image
docker build -f oci/Dockerfile -t abi-assistant:prod .

# Run with external RPC
docker run -p 3000:3000 \
  -e ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/key \
  -e GEMINI_API_KEY=your-key \
  abi-assistant:prod

# Using docker-compose for production
docker-compose -f oci/docker-compose.prod.yml up -d
```

### Cloud Deployment

The same Dockerfiles work across all cloud platforms:

```bash
# GCP Cloud Run
gcloud run deploy abi-assistant \
  --source . \
  --dockerfile oci/Dockerfile

# AWS ECS
docker build -f oci/Dockerfile -t abi-assistant .
docker tag abi-assistant:latest $ECR_URI
docker push $ECR_URI

# Azure Container Instances
az container create \
  --resource-group mygroup \
  --name abi-assistant \
  --image myregistry.azurecr.io/abi-assistant
```

## 🔧 Environment Variables

### MCP Server Container

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Port to listen on (auto-detected on cloud) | 3000 |
| `MCP_PORT` | MCP server port | 3000 |
| `MCP_HOST` | Bind address | 0.0.0.0 |
| `DATABASE_URL` | SQLite database path | sqlite:///data/abi_assistant.db |
| `ETH_RPC_URL` | Ethereum RPC endpoint | http://anvil:8545 (dev) |
| `GEMINI_API_KEY` | Gemini API key | Required |
| `RUST_LOG` | Log level | info |

### Anvil Container

| Variable | Description | Default |
|----------|-------------|---------|
| `ANVIL_PORT` | RPC port | 8545 |
| `ANVIL_HOST` | Bind address | 0.0.0.0 |
| `ANVIL_ACCOUNTS` | Number of test accounts | 10 |
| `ANVIL_BALANCE` | Initial balance (ETH) | 10000 |
| `ANVIL_CHAIN_ID` | Chain ID | 31337 |
| `ANVIL_FORK_URL` | Fork from mainnet | Optional |
| `ANVIL_FORK_BLOCK` | Fork at block | Optional |
| `ANVIL_BLOCK_TIME` | Block time (seconds) | 1 |

## 🔗 Service Communication

In development, services communicate via Docker network:
- MCP Server → Anvil: `http://anvil:8545`
- External → MCP Server: `http://localhost:3000`
- External → Anvil: `http://localhost:8545`

## 🏗️ Building Images

```bash
# Build all images
make build

# Build specific image
docker build -f oci/Dockerfile -t abi-assistant:latest .
docker build -f oci/Dockerfile.anvil -t anvil:latest .
docker build -f oci/Dockerfile.dev -t abi-assistant:dev .
```

## 📊 Docker Compose Services

### Development (`docker-compose.yml`)
- `anvil` - Local Ethereum blockchain
- `mcp-server` - Main application server
- `dev` - Development container (profile: dev)

### Production (`docker-compose.prod.yml`)
- `mcp-server` - Production server with external RPC

## 🔍 Health Checks

All containers include health checks:

```bash
# Check MCP server health
curl http://localhost:3000/health

# Check Anvil health
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

## 🐛 Troubleshooting

### Port conflicts
```bash
# Check what's using the port
lsof -i :3000
lsof -i :8545

# Use different ports
PORT=3001 docker-compose -f oci/docker-compose.yml up
```

### Build failures
```bash
# Clean build cache
docker system prune -a

# Build with no cache
docker build --no-cache -f oci/Dockerfile .
```

### Container connectivity
```bash
# Inspect network
docker network ls
docker network inspect abi-network

# Test connectivity
docker exec abi-assistant-mcp curl http://anvil:8545
```

## 📚 Additional Resources

- [OCI Image Specification](https://github.com/opencontainers/image-spec)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Container Security](https://docs.docker.com/engine/security/)