# Google Cloud Workstation Deployment

## Overview
The Midnight Vibe Platform is designed to run on Google Cloud Workstations using the predefined Code OSS base image.

## Local Development
For local testing with podman:

```bash
# Build the container
make build

# Run with privileged mode (required for the base image)
make run

# Check status
make status

# View logs
make logs

# Stop services
make stop
```

## Production Deployment

### Container Registry
Push the built image to a container registry accessible by Google Cloud Workstations:

```bash
# Tag for production
podman tag midnight-vibe-platform gcr.io/your-project/midnight-vibe-platform:latest

# Push to registry
podman push gcr.io/your-project/midnight-vibe-platform:latest
```

### Workstation Configuration
In Google Cloud Workstations, configure:

1. **Container Image**: `gcr.io/your-project/midnight-vibe-platform:latest`
2. **Machine Type**: At least e2-standard-4 (4 vCPU, 16 GB RAM)
3. **Network**: Ensure ports 9933, 9944, 5432, and 8080 are accessible
4. **Persistent Storage**: Configure for PostgreSQL data persistence

### Environment Variables
The workstation will automatically have access to:
- Google Cloud credentials
- Required networking for Midnight services
- Persistent home directory for development

### Service Endpoints
Once deployed, services will be available at:
- **Midnight Node RPC**: `http://workstation-ip:9933`
- **Midnight Node WebSocket**: `ws://workstation-ip:9944`
- **PostgreSQL**: `workstation-ip:5432`
- **Proof Server**: `http://workstation-ip:8080`

### IDE Access
Google Cloud Workstations provide built-in VS Code interface:
- **Access**: Workstation URL in browser
- **Authentication**: Google account login
- **Features**: Full VS Code experience with terminal
- **OpenCode TUI**: Not needed (built-in IDE preferred)

## Security Considerations
- The base image includes SSH and Code OSS server
- PostgreSQL uses trust authentication for local development
- Consider using proper authentication for production
- Network access should be restricted as needed

## Troubleshooting
- Use `make logs` to view service status
- Check individual service logs in `/tmp/` directory in container
- Ensure privileged mode is enabled for local development