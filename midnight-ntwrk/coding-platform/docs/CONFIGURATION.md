# Configuration Guide

This guide covers all configuration options for the Midnight Development Platform.

## Environment Variables

### Core Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PROJECT_ID` | Google Cloud Project ID | - | Yes |
| `REGION` | GCP deployment region | `us-central1` | No |
| `ZONE` | GCP deployment zone | `us-central1-a` | No |
| `ENV` | Environment name (used in resource naming) | `mvp` | No |

### Service Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PROOF_SERVICE_URL` | External proof service URL | `http://localhost:8080` | No |
| `PROOF_SERVICE_CONFIG` | Additional proof service config (JSON) | `{}` | No |
| `TERMINAL_PORT` | Web terminal port | `7681` | No |
| `APP_PORT` | DApp development server port | `3000` | No |
| `PROOF_PORT` | Proof service port (local) | `8080` | No |
| `VSCODE_PORT` | VS Code server port | `8443` | No |

### Workstation Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `WORKSPACE` | Working directory in container | `/workspace` | No |
| `MIDNIGHT_NETWORK` | Network to connect to | `testnet` | No |
| `MIDNIGHT_ENV` | Environment identifier | Same as `ENV` | No |

### Development Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `OPENCODE_NO_VSCODE` | Disable VS Code integration in OpenCode | `1` | No |
| `OPENCODE_OPENEDITOR` | Allow OpenCode to open external editor | `false` | No |
| `OPENCODE_NOEDITOR` | Disable editor launches from OpenCode | `true` | No |
| `EDITOR` | Default text editor | `nano` | No |
| `BROWSER` | Default browser (set to 'none' in container) | `none` | No |

## Configuration Files

### `.env` File

Create a `.env` file in the project root for local configuration:

```bash
# .env
PROJECT_ID=my-gcp-project
REGION=us-central1
ZONE=us-central1-a
ENV=development

# External Services
PROOF_SERVICE_URL=https://proof-api.midnight.network
PROOF_SERVICE_CONFIG='{"API_KEY":"your-api-key"}'

# Local Development Ports
APP_PORT=3001
PROOF_PORT=8081
TERMINAL_PORT=7682
```

### Terraform Variables

Configure infrastructure via `terraform.tfvars`:

```hcl
# terraform.tfvars
project_id = "my-gcp-project"
region     = "us-central1"
zone       = "us-central1-a"
environment = "production"

# Proof Service Configuration
proof_service_url = "https://proof-api.midnight.network"
proof_service_config = {
  API_KEY = "your-api-key"
  TIMEOUT = "30s"
}

# Workstation Configuration
workstation_config = {
  machine_type             = "e2-standard-8"
  boot_disk_size_gb       = 100
  persistent_disk_size_gb = 500
  idle_timeout            = "30m"
  running_timeout         = "8h"
}
```

## Terraform Variable Reference

### Root Module Variables

```hcl
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "mvp"
}

variable "proof_service_url" {
  description = "External proof service URL"
  type        = string
  default     = "http://localhost:8080"
}

variable "proof_service_config" {
  description = "Additional proof service configuration"
  type        = map(string)
  default     = {}
}

variable "workstation_config" {
  description = "Cloud Workstation configuration"
  type = object({
    machine_type             = string
    boot_disk_size_gb       = number
    persistent_disk_size_gb = number
    idle_timeout            = string
    running_timeout         = string
  })
  default = {
    machine_type             = "e2-standard-4"
    boot_disk_size_gb       = 50
    persistent_disk_size_gb = 200
    idle_timeout            = "20m"
    running_timeout         = "4h"
  }
}
```

## Container Configuration

### Dockerfile Build Args

Pass build arguments when building the container:

```bash
# Build with custom configuration
podman build \
  --build-arg NODE_VERSION=18 \
  --build-arg OPENCODE_VERSION=latest \
  -t midnight-workstation:custom \
  docker/
```

Available build args:
- `NODE_VERSION` - Node.js version to install (default: 18)
- `OPENCODE_VERSION` - OpenCode AI version (default: latest)

### Runtime Configuration

Configure the container at runtime:

```bash
# Run with custom configuration
podman run -it --rm \
  -e PROOF_SERVICE_URL=https://api.example.com \
  -e WORKSPACE=/custom/workspace \
  -e TERMINAL_PORT=8000 \
  -p 8000:8000 \
  midnight-workstation:latest
```

## Service Configuration

### Proof Service

The proof service can be configured in multiple ways:

1. **Local Mock Service** (default)
   - Runs automatically if no external URL provided
   - Available at `http://localhost:8080`
   - Returns mock proofs for development

2. **External Service**
   ```bash
   # Via environment variable
   export PROOF_SERVICE_URL=https://proof-api.midnight.network
   
   # Via .env file
   echo "PROOF_SERVICE_URL=https://proof-api.midnight.network" >> .env
   
   # Via Terraform
   terraform apply -var="proof_service_url=https://proof-api.midnight.network"
   ```

3. **Custom Configuration**
   ```bash
   # Pass additional config as JSON
   export PROOF_SERVICE_CONFIG='{"API_KEY":"secret","TIMEOUT":"30s"}'
   
   # Or via Terraform
   terraform apply -var='proof_service_config={API_KEY="secret",TIMEOUT="30s"}'
   ```

### Web Terminal

Configure the web terminal service:

```javascript
// docker/scripts/web-terminal.js configuration
const config = {
  port: process.env.TERMINAL_PORT || 7681,
  workspace: process.env.WORKSPACE || '/workspace',
  shell: process.env.SHELL || '/bin/bash',
  term: {
    cols: 80,
    rows: 30,
    scrollback: 1000
  }
};
```

### VS Code Server

Configure code-server settings:

```yaml
# ~/.config/code-server/config.yaml (in container)
bind-addr: 0.0.0.0:8443
auth: none
cert: false
```

## Machine Types

### Recommended Configurations

| Use Case | Machine Type | vCPUs | Memory | Cost/Month* |
|----------|-------------|-------|--------|-------------|
| Development | `e2-standard-4` | 4 | 16 GB | ~$150 |
| Testing | `e2-standard-2` | 2 | 8 GB | ~$75 |
| Production | `e2-standard-8` | 8 | 32 GB | ~$300 |
| High Performance | `n2-standard-8` | 8 | 32 GB | ~$400 |

*Estimated cost assuming 8 hours/day, 22 days/month usage

### Custom Machine Types

```hcl
# terraform.tfvars
workstation_config = {
  machine_type = "n2-custom-6-24576"  # 6 vCPUs, 24 GB RAM
  # ... other config
}
```

## Networking Configuration

### VPC Settings

```hcl
# terraform/modules/networking/variables.tf
variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "enable_private_google_access" {
  description = "Enable private Google access"
  type        = bool
  default     = true
}
```

### Firewall Rules

Default firewall rules:
- Allow internal traffic within VPC
- Allow IAP for SSH/RDP
- Allow load balancer health checks
- Deny all other inbound traffic

## Storage Configuration

### Persistent Disk

```hcl
# Configure persistent storage
variable "persistent_disk_config" {
  type = object({
    size_gb   = number
    type      = string  # pd-standard, pd-ssd, pd-balanced
    snapshot  = string  # Optional snapshot to restore from
  })
  default = {
    size_gb   = 200
    type      = "pd-standard"
    snapshot  = null
  }
}
```

### Artifact Registry

```hcl
# Configure container registry
variable "registry_config" {
  type = object({
    format      = string  # DOCKER
    mode        = string  # STANDARD_REPOSITORY
    description = string
  })
  default = {
    format      = "DOCKER"
    mode        = "STANDARD_REPOSITORY"
    description = "Container images for Midnight workstations"
  }
}
```

## Security Configuration

### IAM Roles

Required roles for deployment:
- `roles/compute.admin` - Manage compute resources
- `roles/workstations.admin` - Manage workstations
- `roles/artifactregistry.admin` - Manage container registry
- `roles/iam.serviceAccountAdmin` - Manage service accounts

### Service Account

```bash
# Create service account for workstations
gcloud iam service-accounts create midnight-workstation-sa \
  --display-name="Midnight Workstation Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:midnight-workstation-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/workstations.workstationUser"
```

## Monitoring Configuration

### Logging

```hcl
# Enable logging for workstations
variable "enable_logging" {
  description = "Enable Cloud Logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}
```

### Metrics

```hcl
# Enable monitoring
variable "enable_monitoring" {
  description = "Enable Cloud Monitoring"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
  default     = ""
}
```

## Backup Configuration

### Automated Backups

```bash
# Schedule persistent disk snapshots
gcloud compute resource-policies create snapshot-schedule midnight-backup \
  --region=REGION \
  --max-retention-days=7 \
  --on-source-disk-delete=keep-auto-snapshots \
  --daily-schedule \
  --start-time=03:00
```

### Manual Backup

```bash
# Create manual snapshot
gcloud compute disks snapshot DISK_NAME \
  --snapshot-names=midnight-backup-$(date +%Y%m%d) \
  --zone=ZONE
```

## Advanced Configuration

### Multi-Region Setup

```hcl
# Deploy to multiple regions
variable "regions" {
  type = map(object({
    zone = string
    workstation_count = number
  }))
  default = {
    "us-central1" = {
      zone = "us-central1-a"
      workstation_count = 2
    }
    "europe-west1" = {
      zone = "europe-west1-b"
      workstation_count = 1
    }
  }
}
```

### Custom Container Registry

```bash
# Use external registry
export REGISTRY_URL=gcr.io/my-project/midnight
make build
docker tag midnight-workstation:latest $REGISTRY_URL/workstation:latest
docker push $REGISTRY_URL/workstation:latest
```

### Private Cluster Configuration

```hcl
# Enable private cluster
variable "enable_private_endpoint" {
  description = "Use private IP for cluster endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for private cluster master"
  type        = string
  default     = "172.16.0.0/28"
}
```

## Troubleshooting Configuration Issues

### Validate Configuration

```bash
# Check Terraform configuration
cd terraform
terraform validate
terraform plan

# Verify environment variables
env | grep MIDNIGHT
env | grep PROOF

# Test configuration locally
make run-local
```

### Common Issues

1. **Proof Service Not Connecting**
   ```bash
   # Check if URL is set correctly
   echo $PROOF_SERVICE_URL
   
   # Test connectivity
   curl -v $PROOF_SERVICE_URL/health
   ```

2. **Workstation Not Starting**
   ```bash
   # Check machine type availability
   gcloud compute machine-types list --zones=$ZONE
   
   # Verify quotas
   gcloud compute project-info describe --project=$PROJECT_ID
   ```

3. **Port Conflicts**
   ```bash
   # Check for port usage
   lsof -i :3000
   lsof -i :8080
   
   # Use alternative ports
   APP_PORT=3001 PROOF_PORT=8081 make run-local
   ```

## Configuration Best Practices

1. **Use `.env` for local development**
2. **Use `terraform.tfvars` for infrastructure**
3. **Never commit secrets to git**
4. **Use Secret Manager for production secrets**
5. **Set appropriate idle timeouts to control costs**
6. **Use persistent disks for important data**
7. **Enable monitoring and logging in production**
8. **Regular backup persistent disks**
9. **Use private endpoints for production workstations**
10. **Implement least-privilege IAM policies**