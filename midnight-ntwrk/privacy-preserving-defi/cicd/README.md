# CI/CD Configuration

This directory contains the CI/CD configuration files for the Privacy-Preserving DeFi platform.

## Structure

```
cicd/
├── docker-compose.yml    # Docker Compose for local development
├── Dockerfile          # Main TEE service Docker image
├── Dockerfile.dev      # Development image with hot reload
├── Dockerfile.devtools # Development image with debugging tools
├── Dockerfile.deployer # Deployment image for cloud builds
├── nginx.conf         # Nginx configuration for frontend
├── cloudbuild-app.yaml  # Cloud Build for application
├── cloudbuild-infra.yaml # Cloud Build for infrastructure
├── mock-registrations.json # Mock data for Midnight node
└── README.md          # This file
```

## Services

### Docker Compose Services

- **anvil**: Arc blockchain node (Foundry)
- **proof-server**: Midnight ZK proof server
- **tee-service**: Main TEE service application
- **frontend**: Web frontend (via Nginx)
- **midnight-node**: Midnight blockchain node (disabled due to config issues)

## Usage

### Local Development

```bash
# Start all services
make start

# Stop all services  
make stop

# View logs
make logs

# Clean up
make clean
```

### Docker Compose Commands

```bash
# Start specific services
docker-compose -f cicd/docker-compose.yml up -d anvil proof-server tee-service

# Start all services
docker-compose -f cicd/docker-compose.yml up -d

# Stop services
docker-compose -f cicd/docker-compose.yml down

# View logs
docker-compose -f cicd/docker-compose.yml logs -f

# Rebuild service
docker-compose -f cicd/docker-compose.yml up -d --build tee-service
```

## Configuration

### Environment Variables

Key environment variables for services:

- **ANVIL_IP_ADDR**: Anvil binding address (0.0.0.0)
- **PROOF_SERVER_PORT**: Proof server port (6300)
- **TEE_SERVICE_PORT**: TEE service port (8080)

### Networking

Services communicate via Docker network `privacy-defi`:

- Frontend: http://localhost:3000
- TEE Service: http://localhost:8080  
- Arc Blockchain: http://localhost:8545
- Proof Server: http://localhost:6300
- Midnight RPC: http://localhost:9944 (when enabled)

## Cloud Deployment

### Google Cloud Build

The `cloudbuild-*.yaml` files define Cloud Build steps:

- **cloudbuild-app.yaml**: Build and deploy TEE service
- **cloudbuild-infra.yaml**: Deploy infrastructure via Terraform

### Terraform

Infrastructure is defined in `../terraform/` directory:

```bash
# Plan deployment
make cloud-plan

# Deploy infrastructure
make cloud-apply

# Destroy infrastructure
make cloud-destroy
```

## Docker Images

### TEE Service Images

- **Dockerfile**: Production image
- **Dockerfile.dev**: Development with hot reload
- **Dockerfile.devtools**: Development with debugging tools
- **Dockerfile.deployer**: Minimal image for cloud deployment

### Building Images

```bash
# Build production image
docker build -f cicd/Dockerfile -t privacy-defi-tee-service .

# Build development image
docker build -f cicd/Dockerfile.dev -t privacy-defi-tee-service:dev .

# Build with compose
docker-compose -f cicd/docker-compose.yml build tee-service
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 3000, 8080, 8545, 6300 are available
2. **Anvil binding**: Use `ANVIL_IP_ADDR=0.0.0.0` environment variable
3. **Permission issues**: Check Docker/Podman permissions
4. **Resource limits**: Ensure sufficient memory for proof server

### Health Checks

All services include health checks:

```bash
# Check service status
docker-compose -f cicd/docker-compose.yml ps

# Check health endpoints
curl http://localhost:8080/healthz  # TEE service
curl http://localhost:6300/health   # Proof server
curl http://localhost:8545          # Anvil (JSON-RPC)
```

### Logs

```bash
# View all logs
make logs

# View specific service logs
docker-compose -f cicd/docker-compose.yml logs -f tee-service
docker-compose -f cicd/docker-compose.yml logs -f anvil
docker-compose -f cicd/docker-compose.yml logs -f proof-server
```

---

## Legacy Information

### Environment Variables

The build system expects these environment variables:

- `GCP_PROJECT` - Google Cloud project ID
- `GCP_REGION` - Deployment region (default: us-central1)
- `TEE_IMAGE_DIGEST` - Container image digest (auto-populated by CI/CD)

### Docker Compose Services

- **anvil** - Mock Arc blockchain (EVM-compatible)
- **midnight-node** - Mock Midnight network node
- **blockscout** - Optional block explorer for development
- **db** - PostgreSQL database for Blockscout