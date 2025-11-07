# Terraform Infrastructure

This directory contains the modular Terraform configuration for deploying the Privacy-Preserving DeFi infrastructure on Google Cloud Platform.

## 🏗️ Architecture

The infrastructure is organized into modular components:

```
terraform/
├── main.tf              # Root configuration that calls all modules
├── variables.tf         # Input variables for the entire infrastructure
├── outputs.tf          # Output values from deployed resources
├── modules/            # Reusable infrastructure components
│   ├── services/       # GCP services and API enablement
│   ├── networking/     # VPC, subnet, and firewall rules
│   ├── iam/           # Service accounts and permissions
│   └── compute/       # Virtual machines
├── scripts/           # Startup scripts for VM instances
└── backup/           # Original non-modular files (preserved)
```

## 🚀 Quick Start

### Prerequisites

- Google Cloud SDK installed and authenticated
- Terraform installed locally
- Appropriate GCP permissions

### Deployment Steps

```bash
# 1. Initialize Terraform
terraform init

# 2. Review the execution plan
terraform plan

# 3. Deploy the infrastructure
terraform apply

# 4. Get outputs
terraform output
```

### Variables

Key variables that can be customized:

| Variable | Default | Description |
|----------|---------|-------------|
| `gcp_project` | `privacy-defi-mvp` | GCP project ID |
| `gcp_region` | `us-central1` | GCP region |
| `mock_server_machine_type` | `e2-standard-16` | Mock server VM type |
| `tee_service_machine_type` | `c3-standard-8` | TEE service VM type |
| `subnet_cidr` | `10.0.0.0/24` | VPC subnet CIDR range |

### Outputs

After deployment, you can access:

```bash
# Get instance IPs
terraform output mock_server_ip
terraform output tee_service_ip

# Get network information
terraform output vpc_name
terraform output subnet_name

# Get service account details
terraform output tee_service_account_email
```

## 📦 Module Details

### Services Module
- Enables required GCP APIs (Compute, Artifact Registry, Secret Manager, etc.)
- No dependencies
- Must be deployed first

### Networking Module
- Creates VPC network and subnet
- Configures firewall rules for internal communication
- Depends on: Services module

### IAM Module
- Creates service accounts for TEE service
- Sets up workload identity federation
- Configures Artifact Registry for container images
- Depends on: Services module

### Compute Module
- Deploys mock server VM
- Deploys TEE service VM with confidential computing
- Depends on: Services, Networking, and IAM modules

## 🔧 Management

### View Resources
```bash
# List all resources
terraform state list

# Show resource details
terraform state show <resource_name>
```

### Destroy Infrastructure
```bash
# Destroy all resources
terraform destroy

# Destroy specific module
terraform destroy -target=module.compute
```

### Update Configuration
```bash
# After modifying variables or modules
terraform plan
terraform apply
```

## 📋 Dependencies

The modules have explicit dependencies to ensure proper deployment order:

1. **Services** → Enables APIs (no dependencies)
2. **Networking** → Creates VPC/subnet (depends on Services)
3. **IAM** → Creates service accounts (depends on Services)
4. **Compute** → Creates VMs (depends on all above)

## 🔒 Security Features

- **Private VPC**: Isolated network with no public IPs
- **Firewall Rules**: Restrictive access controls
- **Service Accounts**: Least-privilege IAM permissions
- **Workload Identity**: Secure authentication for GCP services
- **Confidential Computing**: TEE service runs in secure enclave

## 📊 Monitoring

After deployment, you can monitor:

- **Cloud Logging**: Via GCP Console or `gcloud logging read`
- **Instance Metrics**: Via Cloud Monitoring
- **Service Health**: Via internal health checks

## 🧹 Cleanup

```bash
# Complete cleanup
terraform destroy

# Remove state files (after destroy)
rm -rf .terraform/
rm .terraform.lock.hcl
```

## 🆘 Troubleshooting

### Common Issues

1. **API Enablement**: Ensure all required APIs are enabled
2. **Permissions**: Verify service account has necessary roles
3. **Quotas**: Check GCP resource quotas in your region
4. **Network**: Verify VPC and subnet configurations

### Debug Commands

```bash
# Detailed error messages
terraform apply -detailed-exitcode

# Validate configuration
terraform validate

# Check state consistency
terraform plan -detailed-exitcode
```