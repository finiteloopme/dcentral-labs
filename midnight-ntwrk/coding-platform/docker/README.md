# Docker Configuration

This folder contains all Docker-related configuration for the Midnight Development Platform.

## Structure

```
docker/
├── Dockerfile                  # Main workstation container image
├── docker-compose.yml          # Docker Compose configuration
├── docker-compose.override.yml # Development overrides (auto-loaded)
├── docker-compose.prod.yml    # Production configuration
├── scripts/                    # Container runtime scripts
│   ├── startup.sh             # Container entrypoint script
│   ├── web-terminal.js        # Web terminal service
│   ├── package.json           # Node dependencies for web terminal
│   └── opencode-terminal.service # SystemD service (unused in container)
└── templates/                  # DApp starter templates
    └── basic-token/           # Basic token contract template
```

## Usage

### Quick Start

From the project root:
```bash
# Using Make commands (recommended)
make compose-up     # Start services
make compose-down   # Stop services
make compose-logs   # View logs
```

From this directory:
```bash
# Using docker-compose directly
docker-compose up -d     # Start in background
docker-compose down      # Stop and remove
docker-compose logs -f   # Follow logs
```

### Development Mode

The `docker-compose.override.yml` file is automatically loaded and provides:
- Source code mounting for live editing
- Debug logging enabled
- Additional debugging ports exposed

### Production Mode

For production-like testing:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
```

This provides:
- Resource limits
- Production logging
- External proof service configuration
- Security hardening

## Building Images

### Workstation Image

```bash
# Build the main workstation image
docker build -t midnight-workstation:latest .

# Or using docker-compose
docker-compose build
```

### Proof Service Image

The proof service can run inside the workstation or as a separate container:
```bash
# Build standalone proof service
docker build -t midnight-proof-service:latest ../proof-service/
```

## Configuration

### Environment Variables

Create a `.env` file in the project root:
```env
# Ports
TERMINAL_PORT=7681
VSCODE_PORT=8443
APP_PORT=3000
PROOF_PORT=8080

# Services
PROOF_SERVICE_URL=https://proof-api.midnight.network

# Environment
ENV=development
MIDNIGHT_NETWORK=testnet
```

### Volumes

The following volumes are created for persistence:
- `workspace_data` - Project files
- `home_data` - User home directory
- `vscode_data` - VS Code server configuration

## Services

### Main Workstation Container

Includes:
- Web Terminal (port 7681)
- VS Code Server (port 8443) with Midnight Compact extension
- OpenCode AI Assistant with Vertex AI integration
- Mock Midnight compiler
- Proof service (embedded or external)
- Compact language support (.compact files)

### Optional Proof Service

Uncomment in `docker-compose.yml` to run as separate service:
```yaml
proof-service:
  build:
    context: ../proof-service
    dockerfile: Dockerfile
  ports:
    - "8081:8080"
```

## Health Checks

All services include health check endpoints:
- `/health` - Overall health status
- `/ready` - Service readiness
- `/live` - Liveness probe

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs workstation

# Rebuild without cache
docker-compose build --no-cache
```

### Port conflicts
```bash
# Use different ports
TERMINAL_PORT=7682 docker-compose up
```

### Permission issues with Podman
```bash
# Run with proper security options
podman-compose up --security-opt label=disable
```

## Development Tips

1. **Live Editing**: The override file mounts source code for live changes
2. **Quick Rebuild**: `docker-compose build` rebuilds only changed layers
3. **Service Logs**: `docker-compose logs -f [service]` for specific service
4. **Shell Access**: `docker-compose exec workstation bash`
5. **Clean Restart**: `docker-compose down -v` removes volumes for fresh start