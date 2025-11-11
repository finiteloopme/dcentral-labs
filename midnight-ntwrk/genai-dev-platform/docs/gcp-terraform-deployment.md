# Midnight Vibe Platform - GCP Deployment Guide

This guide provides step-by-step instructions for deploying the Midnight Vibe Platform to Google Cloud Workstations using Terraform automation.

## Prerequisites

1. **Google Cloud SDK** installed and configured
2. **Terraform** (version 1.5 or later)
3. **Appropriate IAM permissions** in your GCP project:
   - Workstations Admin
   - Artifact Registry Admin
   - Cloud Build Admin
   - Compute Network Admin

## Quick Start

### 1. Clone and Navigate

```bash
git clone <repository-url>
cd midnight-ntwrk/genai-dev-platform
```

### 2. Deploy with the Automated Script

The easiest way to deploy is using the provided deployment script:

```bash
# Basic deployment
./scripts/deploy-gcp.sh -p your-gcp-project-id --state-bucket your-project-terraform-state --auto-deploy

# Production deployment with specific users
./scripts/deploy-gcp.sh \
  -p your-gcp-project-id \
  --state-bucket your-project-terraform-state \
  -e prod \
  -m e2-standard-8 \
  --users user@example.com,service-account@project.iam.gserviceaccount.com \
  --vertex-project your-vertex-project \
  --auto-deploy

# Build and push image only (no infrastructure deployment)
./scripts/deploy-gcp.sh -p your-gcp-project-id --state-bucket your-project-terraform-state --build-only
```

> **Note**: Required Google Cloud APIs are enabled automatically via Terraform's `api-services` module, so there's no need to manually enable them beforehand.

### 3. Access Your Workstation

1. Visit the [Google Cloud Workstations console](https://console.cloud.google.com/workstations)
2. Select your project and region
3. Create a new workstation using the deployed configuration
4. Access the VS Code IDE through your browser

## Manual Deployment

If you prefer to deploy manually using Terraform:

### 1. Create Terraform State Bucket

First, create a GCS bucket for Terraform state:

```bash
# Create bucket (replace with your preferred name)
gsutil mb -p your-gcp-project-id gs://your-project-terraform-state

# Enable versioning
gsutil versioning set on gs://your-project-terraform-state

# Enable uniform bucket-level access
gsutil iam ch uniformBucketLevelAccess:enabled gs://your-project-terraform-state
```

### 2. Set Up Terraform Variables

Create a `terraform/terraform.tfvars` file:

```hcl
project_id            = "your-gcp-project-id"
project_number        = "123456789012"
terraform_state_bucket = "your-project-terraform-state"
region               = "us-central1"
cluster_name         = "midnight-vibe-platform"
environment          = "dev"
machine_type         = "e2-standard-4"
google_vertex_project = "your-vertex-project-id"
google_vertex_region = "us-central1"
workstation_users    = [
  "user@example.com",
  "service-account@project.iam.gserviceaccount.com"
]
```

### 3. Initialize and Apply Terraform

**Option A: Using Cloud Build (Recommended)**

```bash
# Initialize Terraform via Cloud Build
make terraform-init -p your-project-id -b your-project-terraform-state

# Create deployment plan
make terraform-plan -p your-project-id -b your-project-terraform-state

# Apply infrastructure
make terraform-apply -p your-project-id -b your-project-terraform-state
```

**Option B: Using Local Terraform**

```bash
cd terraform
terraform init -backend-config="bucket=your-project-terraform-state" -backend-config="prefix=terraform/state"
terraform plan
terraform apply
```

> **Note**: Cloud Build approach is recommended as it eliminates local Terraform dependencies and provides consistent execution environment.

## Configuration Options

### Terraform Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP project ID | Required |
| `project_number` | GCP project number | Required |
| `terraform_state_bucket` | GCS bucket for Terraform state | Required |
| `region` | GCP region | `us-central1` |
| `cluster_name` | Workstation cluster name | `midnight-vibe-platform` |
| `environment` | Environment label | `dev` |
| `machine_type` | GCE machine type | `e2-standard-4` |
| `persistent_disk_size_gb` | Persistent disk size in GB | `100` |
| `google_vertex_project` | Vertex AI project ID | `""` |
| `google_vertex_region` | Vertex AI region | `us-central1` |
| `allowed_ip_ranges` | Allowed IP ranges | `["0.0.0.0/0"]` |
| `workstation_users` | Users with workstation access | `[]` |

### Machine Types

Recommended machine types:
- **Development**: `e2-standard-4` (4 vCPU, 16 GB RAM)
- **Production**: `e2-standard-8` (8 vCPU, 32 GB RAM)
- **High Performance**: `e2-highmem-8` (8 vCPU, 64 GB RAM)

## Service Endpoints

Once deployed, services are available at:

- **VS Code IDE**: `https://[workstation-url]`
- **Midnight Node RPC**: `http://[workstation-ip]:9933`
- **Midnight Node WebSocket**: `ws://[workstation-ip]:9944`
- **PostgreSQL**: `[workstation-ip]:5432`
- **Proof Server**: `http://[workstation-ip]:8081`

## Container Image

The platform uses a custom container image based on Google Cloud Workstations' Code OSS image:

```bash
# Image URL format
{region}-docker.pkg.dev/{project-id}/midnight-platform/midnight-vibe-platform:latest
```

## Security Considerations

1. **Network Access**: Configure `allowed_ip_ranges` to restrict access
2. **IAM**: Grant workstation access only to required users
3. **Vertex AI**: Ensure proper Vertex AI permissions for AI features
4. **Data Persistence**: PostgreSQL data is persisted on attached disk

## Monitoring and Management

### View Workstation Status

```bash
gcloud workstations workstations list \
  --cluster=midnight-vibe-platform \
  --region=us-central1 \
  --project=your-project-id
```

### View Logs

```bash
gcloud workstations workstations describe [workstation-name] \
  --cluster=midnight-vibe-platform \
  --region=us-central1 \
  --project=your-project-id
```

### Update Container Image

1. Update the image tag in Terraform variables
2. Run `terraform apply`
3. Recreate workstations to use the new image

## Troubleshooting

### Common Issues

1. **API Not Enabled**: Ensure all required APIs are enabled
2. **Permission Denied**: Check IAM permissions
3. **Workstation Won't Start**: Verify machine type and region availability
4. **Container Pull Fails**: Check Artifact Registry permissions

### Debug Commands

```bash
# Check Terraform state
terraform show

# Check Cloud Build logs
gcloud builds list --limit=5

# Check workstation status
gcloud workstations workstations list --cluster=midnight-vibe-platform
```

## Cleanup

To remove all deployed resources:

```bash
cd terraform
terraform destroy
```

Or use the script (if you have a cleanup script):

```bash
./scripts/cleanup-gcp.sh -p your-gcp-project-id
```

## Cost Optimization

1. **Idle Timeout**: Workstations automatically stop after 1 hour of inactivity
2. **Running Timeout**: Maximum 24 hours running time
3. **Machine Type**: Choose appropriate machine type for your workload
4. **Region**: Select regions with better pricing

## Modular Architecture

This deployment uses a modular Terraform architecture for better organization and maintainability. See [terraform-modules.md](terraform-modules.md) for detailed documentation of the module structure.

### Module Overview

- **api-services**: Enables required Google Cloud APIs
- **artifact-registry**: Creates container registry
- **networking**: Manages VPC network and firewall rules
- **workstation**: Creates workstation cluster and configuration
- **iam**: Manages IAM permissions

### Benefits

- **Separation of Concerns**: Each module handles specific infrastructure aspects
- **Reusability**: Modules can be reused across environments
- **Maintainability**: Easier to update individual components
- **Testing**: Modules can be tested independently

## Support

For issues with:
- **Google Cloud Workstations**: Check [GCP documentation](https://cloud.google.com/workstations/docs)
- **Terraform**: Check [Terraform documentation](https://www.terraform.io/docs)
- **Platform Issues**: Check the project's GitHub issues