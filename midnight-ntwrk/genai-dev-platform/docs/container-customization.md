# Midnight Development Platform - Container Customization Guide

This document explains how the Google Cloud Workstation container is customized for Midnight development.

## Overview

The workstation container is based on Google's Code OSS image and customized with:

- **Midnight Network Tools** - Rust toolchain, Midnight binaries, Compact CLI
- **Vertex AI Integration** - Pre-configured environment variables and credentials
- **Development Environment** - PostgreSQL, Node.js, and IDE settings
- **Service Account Authentication** - Proper credential mounting and configuration

## Container Layers

### Base Image
```dockerfile
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest
```

### Development Tools Installed
- **Rust Toolchain** - Latest stable Rust with Cargo, Clippy, Rustfmt
- **Node.js 20.x** - For frontend development and tooling
- **PostgreSQL 16** - Database server with configuration
- **Midnight Binaries**:
  - `midnight-proof-server` - Mock proof server (port 8081)
  - `midnight-node` - Midnight network node
  - `midnight-indexer-standalone` - Indexer service
- **Compact CLI** - Midnight development tool
- **OpenCode AI Assistant** - AI-powered development assistant

### Environment Variables

#### Core Configuration
```bash
MIDNIGHT_ENV=dev                    # Environment name
MIDNIGHT_NETWORK=testnet              # Midnight network
CLOUD_WORKSTATIONS_CONFIG=true         # Cloud Workstations flag
GCP_PROJECT_ID=kunal-scratch          # GCP project
GOOGLE_CLOUD_PROJECT=kunal-scratch    # GCP project (alias)
```

#### Vertex AI Configuration
```bash
GOOGLE_VERTEX_PROJECT=kunal-scratch     # Vertex AI project
GOOGLE_VERTEX_LOCATION=us-central1      # Vertex AI region
GOOGLE_APPLICATION_CREDENTIALS=/var/run/secrets/workstation-credentials.json
```

#### Infrastructure Configuration
```bash
GCE_METADATA_HOST=metadata.google.internal  # Use metadata service
```

## Startup Scripts

### 1. Code OSS Port Configuration (`120_code-oss-port-config.sh`)
- Configures Code OSS to run on port 80 (web interface)
- Sets up appropriate firewall rules
- Exposes development server

### 2. Midnight Services (`200_midnight-services.sh`)
- Starts Midnight proof server on port 8081
- Configures Midnight node
- Sets up indexer service
- Creates background services for development

### 3. IDE Settings (`210_default-ide-settings.sh`)
- Basic IDE configuration (backup script)
- Sets up development environment

### 4. Vertex AI & IDE Configuration (`220_vertex-ide-config.sh`)
- **Configures Vertex AI environment variables**
- **Sets up service account authentication**
- **Configures gcloud with workstation credentials**
- **Sets up Git configuration**
- **Creates useful aliases and environment summary**

## Service Account Integration

### Credential Management
The workstation uses a dedicated service account with proper credential mounting:

```hcl
secrets {
  workstation_credentials = {
    kubernetes_secret = "workstation-credentials"
    filename         = "workstation-credentials.json"
    mount_path       = "/var/run/secrets"
  }
}
```

### IAM Roles
The workstation service account has these roles:
- `roles/aiplatform.user` - Access to Vertex AI models and endpoints
- `roles/serviceusage.serviceUsageConsumer` - Use GCP services
- `roles/logging.logWriter` - Write logs to Cloud Logging
- `roles/monitoring.metricWriter` - Write metrics to Cloud Monitoring
- `roles/storage.objectViewer` - Access to storage resources

## Development Workflow

### 1. Initial Setup
When the workstation starts, the `220_vertex-ide-config.sh` script:
- Activates service account with mounted credentials
- Sets default gcloud project
- Configures Vertex AI environment
- Sets up Git user configuration

### 2. Development Commands
```bash
# Vertex AI commands
gcloud ai models list                 # List available models
gcloud ai endpoints list             # List deployed endpoints
gcloud ai endpoints predict ...        # Make predictions

# Midnight commands
midnight --help                      # Midnight CLI help
compact --help                       # Compact CLI help

# Workstation management
make ws-start                        # Start workstation
make ws-stop                         # Stop workstation
make ws-open                         # Open in browser
make ws-tunnel                       # Tunnel to localhost:8080
```

### 3. IDE Integration
The IDE is pre-configured with:
- **Vertex AI integration** - Models and endpoints available
- **Service account auth** - No manual credential setup needed
- **Midnight tooling** - All CLI tools in PATH
- **Database access** - PostgreSQL running locally
- **Development aliases** - Quick access to common commands

## Security Considerations

### Credential Isolation
- Service account credentials are mounted as Kubernetes secrets
- Credentials are only accessible within the workstation
- No credential files persisted in container image

### Principle of Least Privilege
- Service account has only required roles
- No unnecessary permissions granted
- Access scoped to specific resources

## Troubleshooting

### Common Issues

#### Vertex AI Not Working
```bash
# Check environment variables
echo $GOOGLE_VERTEX_PROJECT
echo $GOOGLE_VERTEX_LOCATION

# Check credentials
gcloud auth list
```

#### Service Account Issues
```bash
# Check service account status
gcloud auth activate-service-account --key-file=/var/run/secrets/workstation-credentials.json

# Verify permissions
gcloud projects get-iam-policy $GOOGLE_CLOUD_PROJECT
```

#### Midnight Services Not Running
```bash
# Check if services are running
ps aux | grep midnight
netstat -tlnp | grep 8081
```

## Customization Guide

### Adding New Tools
1. Update `Dockerfile` with installation commands
2. Add environment variables to workstation config
3. Create startup scripts in `config/` directory
4. Update Terraform configuration if needed

### Modifying Vertex AI Configuration
1. Update environment variables in `modules/workstations/main.tf`
2. Modify `220_vertex-ide-config.sh` for additional setup
3. Update IAM roles if new permissions needed

### Adding Development Services
1. Create new startup script in `config/`
2. Copy to `/etc/workstation-startup.d/` in Dockerfile
3. Make executable with `chmod +x`
4. Add to container build process

## References

- [Google Cloud Workstations Documentation](https://cloud.google.com/workstations/docs)
- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Midnight Network Documentation](https://docs.midnight.network)
- [Container Customization Guide](https://cloud.google.com/workstations/docs/customize-container-images)