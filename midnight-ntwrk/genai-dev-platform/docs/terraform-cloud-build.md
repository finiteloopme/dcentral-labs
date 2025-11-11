# Terraform Cloud Build Deployment

This guide explains how to use Cloud Build for Terraform operations, eliminating the need for local Terraform installation.

## Overview

Instead of running Terraform locally, all Terraform operations are executed through Google Cloud Build, providing:
- **No local dependencies** - No need to install Terraform
- **Consistent environment** - Same Terraform version and configuration
- **Audit trail** - All operations logged in Cloud Build
- **Security** - Operations run with Cloud Build service account

## Prerequisites

1. **Google Cloud SDK** installed and configured
2. **Appropriate IAM permissions**:
   - Cloud Build Editor
   - Storage Admin (for state bucket)
   - Workstations Admin
   - Artifact Registry Admin

## Quick Start

### 1. Create Terraform State Bucket

```bash
make setup-state-bucket
```

### 2. Initialize Terraform

```bash
make terraform-init -p your-project-id -b your-state-bucket
```

### 3. Plan Deployment

```bash
make terraform-plan -p your-project-id -b your-state-bucket
```

### 4. Apply Infrastructure

```bash
make terraform-apply -p your-project-id -b your-state-bucket
```

## Available Commands

### Terraform Operations via Cloud Build

```bash
# Initialize Terraform
make terraform-init -p PROJECT_ID -b STATE_BUCKET

# Create deployment plan
make terraform-plan -p PROJECT_ID -b STATE_BUCKET

# Apply infrastructure changes
make terraform-apply -p PROJECT_ID -b STATE_BUCKET

# Destroy all resources
make terraform-destroy -p PROJECT_ID -b STATE_BUCKET
```

### Advanced Options

```bash
# Custom configuration
make terraform-apply \
  -p my-project \
  -b my-state-bucket \
  -r us-west1 \
  -c my-cluster \
  -e prod \
  -m e2-standard-8 \
  --users user@example.com \
  --vertex-project my-vertex-project

# Disable Vertex AI
make terraform-apply \
  -p my-project \
  -b my-state-bucket \
  --disable-vertex-ai

# Restrict IP access
make terraform-apply \
  -p my-project \
  -b my-state-bucket \
  --allowed-ips 10.0.0.0/8,192.168.0.0/16
```

## Cloud Build Configuration

The `ci-cd/cloudbuild-terraform.yaml` file defines:

### Steps
1. **Terraform Init** - Initialize with GCS backend
2. **Terraform Plan** - Create execution plan (conditional)
3. **Terraform Apply** - Apply changes (conditional)
4. **Terraform Destroy** - Destroy resources (conditional)

### Environment Variables
All Terraform variables are passed as environment variables to Cloud Build:
- Project configuration (ID, region, etc.)
- Infrastructure settings (machine type, disk size)
- Vertex AI configuration
- Security settings (IP ranges, users)

### Substitutions
Configuration is passed through Cloud Build substitutions, allowing customization without modifying the YAML file.

## Benefits

### 1. No Local Dependencies
- No need to install or manage Terraform versions
- Consistent Terraform version across team
- Works from any environment with gcloud CLI

### 2. Enhanced Security
- Operations run with Cloud Build service account
- No need for local credentials
- Audit trail in Cloud Build logs

### 3. Consistency
- Same environment for all team members
- Reproducible builds
- Version-controlled Terraform configuration

### 4. Scalability
- Parallel execution capabilities
- Integration with CI/CD pipelines
- Automated testing and deployment

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure Cloud Build service account has required IAM roles
2. **State Bucket Not Found**: Create bucket with `make setup-state-bucket`
3. **Build Timeout**: Increase timeout in `ci-cd/cloudbuild-terraform.yaml`
4. **Variable Errors**: Check variable names and formats

### Debug Commands

```bash
# Check Cloud Build logs
gcloud builds list --limit=5

# View specific build details
gcloud builds describe BUILD_ID

# Check state bucket
gsutil ls gs://your-state-bucket/terraform/state/
```

## Integration with CI/CD

The Cloud Build approach integrates seamlessly with CI/CD pipelines:

```yaml
# Example CI/CD pipeline step
- name: 'gcr.io/cloud-builders/gcloud'
  args:
    - 'builds'
    - 'submit'
    - '--config=ci-cd/cloudbuild-terraform.yaml'
    - '--substitutions=_PROJECT_ID=my-project,_STATE_BUCKET=my-bucket,_TERRAFORM_APPLY=true'
    - '.'
```

## Best Practices

1. **Use separate state buckets** for different environments
2. **Enable versioning** on state buckets
3. **Restrict IP ranges** for production deployments
4. **Use service accounts** instead of user credentials
5. **Monitor Cloud Build logs** for troubleshooting
6. **Test with terraform-plan** before applying

## Migration from Local Terraform

If you have existing local Terraform state:

1. **Backup local state**: `cp terraform.tfstate terraform.tfstate.backup`
2. **Create state bucket**: `make setup-state-bucket`
3. **Migrate state**: Use `terraform init -migrate-state` with Cloud Build
4. **Verify**: Check state in GCS bucket

This approach provides a modern, cloud-native way to manage Terraform infrastructure without local dependencies.