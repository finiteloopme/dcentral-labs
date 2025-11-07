# Scripts Documentation

This directory contains modular scripts for managing the Privacy-Preserving DeFi project.

## Overview

The scripts have been modularized into two main files:

- **`dev.sh`** - Local development operations
- **`cloud.sh`** - Cloud deployment and management

## Development Script (`dev.sh`)

### Service Management

```bash
# Start services
./scripts/dev.sh start          # Start development services (mock mode)
./scripts/dev.sh start prod     # Start production services
./scripts/dev.sh start demo     # Start demo services

# Stop services
./scripts/dev.sh stop

# Restart services
./scripts/dev.sh restart        # Restart development services
./scripts/dev.sh restart prod   # Restart production services

# View logs
./scripts/dev.sh logs          # Show all logs
./scripts/dev.sh logs frontend  # Show frontend logs only
./scripts/dev.sh logs tee       # Show TEE service logs only
./scripts/dev.sh logs docker    # Show Docker/Podman logs only

# Service status
./scripts/dev.sh status         # Show comprehensive service status

# Clean resources
./scripts/dev.sh clean         # Clean all resources and artifacts

# Check services
./scripts/dev.sh check         # Quick service health check
```

### Build Operations

```bash
# Build Compact contract
./scripts/dev.sh build-compact

# Build Midnight integration service
./scripts/dev.sh build-midnight-integration

# Run all tests
./scripts/dev.sh test
```

### Features

- **Colored Output**: Easy-to-read status messages
- **Process Management**: Proper PID tracking and cleanup
- **Health Checks**: Service readiness verification
- **Log Management**: Centralized logging with rotation
- **Error Handling**: Graceful error recovery
- **Service Dependencies**: Proper startup ordering

## Cloud Script (`cloud.sh`)

### Deployment Operations

```bash
# Build application image
./scripts/cloud.sh build

# Deploy infrastructure only
./scripts/cloud.sh infra

# Deploy everything (app + infrastructure)
./scripts/cloud.sh deploy

# Destroy all resources
./scripts/cloud.sh destroy
```

### Monitoring & Testing

```bash
# Check deployment status
./scripts/cloud.sh status

# View service logs
./scripts/cloud.sh logs                    # Default service logs
./scripts/cloud.sh logs my-service          # Specific service logs
./scripts/cloud.sh logs my-service 100      # Last 100 log entries

# Test deployed service
./scripts/cloud.sh test

# Get service URL
./scripts/cloud.sh url
```

### Configuration

```bash
# Set project and region
./scripts/cloud.sh config my-project us-east1

# Use command line flags
./scripts/cloud.sh deploy --project my-project --region us-east1

# Environment variables
export GOOGLE_CLOUD_PROJECT=my-project
export CLOUD_REGION=us-east1
./scripts/cloud.sh deploy
```

### Features

- **Prerequisites Checking**: Validates gcloud setup and authentication
- **Interactive Prompts**: Safety confirmations for destructive operations
- **Service Testing**: Automated deployment validation
- **Log Streaming**: Real-time log viewing
- **Status Monitoring**: Comprehensive deployment overview
- **Error Handling**: Graceful failure with helpful messages

## Makefile Integration

The Makefile provides simple aliases for common operations:

```bash
# Development
make dev-start      # Same as ./scripts/dev.sh start
make dev-stop       # Same as ./scripts/dev.sh stop
make dev-logs       # Same as ./scripts/dev.sh logs
make dev-restart    # Same as ./scripts/dev.sh restart
make dev-clean      # Same as ./scripts/dev.sh clean
make dev-status     # Same as ./scripts/dev.sh status

# Building
make build-compact              # Same as ./scripts/dev.sh build-compact
make build-midnight-integration # Same as ./scripts/dev.sh build-midnight-integration

# Production
make demo-start     # Same as ./scripts/dev.sh start prod
make demo-stop      # Same as ./scripts/dev.sh stop

# Cloud
make cloud-build    # Same as ./scripts/cloud.sh build
make cloud-deploy   # Same as ./scripts/cloud.sh deploy
make cloud-destroy  # Same as ./scripts/cloud.sh destroy
make cloud-status   # Same as ./scripts/cloud.sh status
make cloud-logs     # Same as ./scripts/cloud.sh logs
make cloud-test     # Same as ./scripts/cloud.sh test
```

## Service Architecture

### Development Mode

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   TEE Service  │    │  Midnight Int. │
│   (Port 3000)  │    │   (Port 8080)  │    │   (Port 3000)  │
│                 │    │                 │    │                 │
│  Static Files   │◄──►│  Rust Service  │◄──►│  Node.js API   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Docker/Podman │
                    │   Services     │
                    │                 │
                    │  Arc (8545)    │
                    │  Midnight (9944)│
                    │  Proof Server   │
                    └─────────────────┘
```

### Production Mode

Same architecture, but with:
- Production configuration files
- Real Midnight proof generation
- Production TEE attestation
- Enhanced logging and monitoring

## Log Management

### Log Locations

```
logs/
├── frontend.log          # Frontend server logs
├── tee-service.log       # TEE service logs
├── frontend.pid          # Frontend process ID
└── tee-service.pid      # TEE service process ID
```

### Log Viewing

```bash
# Follow all logs
./scripts/dev.sh logs

# Follow specific service logs
./scripts/dev.sh logs frontend
./scripts/dev.sh logs tee

# View Docker logs
./scripts/dev.sh logs docker
```

## Environment Configuration

### Development Configuration

Files used in development mode:
- `cicd/docker-compose.yml` - Service definitions
- `tee-service/config.toml` - TEE service config
- Environment variables for service URLs

### Production Configuration

Files used in production mode:
- `cicd/docker-compose.prod.yml` - Production services
- `tee-service/config.prod.toml` - Production TEE config
- Production environment variables

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   ./scripts/dev.sh stop
   ./scripts/dev.sh clean
   ./scripts/dev.sh start
   ```

2. **Services Not Starting**
   ```bash
   ./scripts/dev.sh status    # Check service status
   ./scripts/dev.sh logs       # View error logs
   ```

3. **Build Failures**
   ```bash
   ./scripts/dev.sh clean      # Clean artifacts
   ./scripts/dev.sh build-compact  # Rebuild Compact contract
   ```

4. **Cloud Deployment Issues**
   ```bash
   ./scripts/cloud.sh status   # Check deployment status
   ./scripts/cloud.sh logs     # View cloud logs
   ./scripts/cloud.sh test     # Test deployment
   ```

### Debug Mode

Enable verbose logging:
```bash
RUST_LOG=debug ./scripts/dev.sh start
```

### Health Checks

Manual health checks:
```bash
# Frontend
curl http://localhost:3000

# TEE Service
curl http://localhost:8080/healthz

# Midnight Integration
curl http://localhost:3000/healthz

# Arc RPC
curl http://localhost:8545

# Proof Server
curl http://localhost:6300/health
```

## Migration from Legacy Scripts

Old scripts have been moved to `scripts/legacy/`:

| Old Command | New Command |
|-------------|-------------|
| `./scripts/dev-start.sh` | `./scripts/dev.sh start` |
| `./scripts/dev-stop.sh` | `./scripts/dev.sh stop` |
| `./scripts/dev-logs.sh` | `./scripts/dev.sh logs` |
| `./scripts/cloud-build.sh` | `./scripts/cloud.sh build` |
| `./scripts/cloud-deploy.sh` | `./scripts/cloud.sh deploy` |

The new modular scripts provide:
- **Better Error Handling**: Colored output and proper error codes
- **More Features**: Status checking, health monitoring, testing
- **Consistent Interface**: Unified command structure
- **Enhanced Logging**: Better log management and viewing
- **Safety Features**: Confirmation prompts for destructive operations

## Best Practices

### Development Workflow

1. **Start Fresh**
   ```bash
   ./scripts/dev.sh clean
   ./scripts/dev.sh start
   ```

2. **Monitor Services**
   ```bash
   ./scripts/dev.sh status
   ./scripts/dev.sh logs
   ```

3. **Build Changes**
   ```bash
   ./scripts/dev.sh build-compact
   ./scripts/dev.sh restart
   ```

### Cloud Deployment Workflow

1. **Test Locally**
   ```bash
   ./scripts/dev.sh start prod
   ./scripts/dev.sh test
   ```

2. **Deploy to Cloud**
   ```bash
   ./scripts/cloud.sh deploy
   ```

3. **Verify Deployment**
   ```bash
   ./scripts/cloud.sh status
   ./scripts/cloud.sh test
   ```

4. **Monitor**
   ```bash
   ./scripts/cloud.sh logs
   ```

### Safety Tips

- Always run `./scripts/cloud.sh status` before `destroy`
- Use `./scripts/dev.sh clean` between major changes
- Check `./scripts/dev.sh status` if services misbehave
- Keep backup of configuration files before major changes