# Cloud Build Automation Guide

## Overview

This guide explains how to use Google Cloud Build for automated Terraform deployments of the Midnight Development Platform. Cloud Build provides a serverless CI/CD platform that runs Terraform in a secure, isolated environment while maintaining state in Google Cloud Storage.

## Architecture

```
GitHub Repository
    ↓
Cloud Build Triggers
    ↓
Cloud Build (Terraform)
    ↓
GCS Backend (State)
    ↓
Infrastructure Resources
```

## Prerequisites

1. **Google Cloud Project** with billing enabled
2. **GitHub repository** (or other source repository)
3. **Terraform state bucket** (created automatically by setup script)
4. **Required APIs** enabled:
   - Cloud Build API
   - Artifact Registry API
   - Cloud Workstations API
   - Compute Engine API
   - Cloud Storage API

## Quick Start

### 1. Initial Setup

Run the setup script to configure Cloud Build:

```bash
./scripts/setup-cloudbuild.sh YOUR_PROJECT_ID
```

This script will:
- Enable required APIs
- Configure IAM permissions for Cloud Build
- Create Terraform state bucket with versioning
- Create Artifact Registry repository
- Set up initial Cloud Build triggers

### 2. Manual Deployment

Deploy using Cloud Build from command line:

```bash
# Plan only (safe, no changes)
gcloud beta builds submit \
  --config=cicd/cloudbuild/cloudbuild-plan.yaml \
  --substitutions="_ENVIRONMENT=dev,_REGION=us-central1,_ZONE=us-central1-a" \
  --project=YOUR_PROJECT_ID

# Apply changes (requires _AUTO_APPROVE=true)
gcloud beta builds submit \
  --config=cicd/cloudbuild/cloudbuild.yaml \
  --substitutions="_ENVIRONMENT=dev,_TERRAFORM_ACTION=apply,_AUTO_APPROVE=true" \
  --project=YOUR_PROJECT_ID
```

### 3. Using the Deploy Script

Use the deploy script with Cloud Build:

```bash
# Traditional local deployment
./scripts/deploy.sh YOUR_PROJECT_ID

# Cloud Build deployment
USE_CLOUD_BUILD=true ./scripts/deploy.sh YOUR_PROJECT_ID
```

## Cloud Build Configurations

### Main Configuration (`cicd/cloudbuild/cloudbuild.yaml`)

The primary configuration that handles both planning and applying Terraform changes.

**Substitutions:**
- `_TERRAFORM_VERSION`: Terraform version to use (default: 1.5.0)
- `_ENVIRONMENT`: Target environment (dev/staging/prod)
- `_TERRAFORM_ACTION`: Action to perform (plan/apply/destroy)
- `_AUTO_APPROVE`: Auto-approve changes (true/false)
- `_REGION`: GCP region
- `_ZONE`: GCP zone

### Plan-Only Configuration (`cicd/cloudbuild/cloudbuild-plan.yaml`)

Safe configuration for pull requests that only creates a plan without applying changes.

```bash
gcloud beta builds submit --config=cicd/cloudbuild/cloudbuild-plan.yaml
```

### Production Configuration (`cicd/cloudbuild/cloudbuild-prod.yaml`)

Enhanced configuration for production deployments with:
- Manual approval requirements
- State backups before changes
- Extended validation
- Deployment notifications

### Destroy Configuration (`cicd/cloudbuild/cloudbuild-destroy.yaml`)

Carefully controlled configuration for destroying infrastructure:
- Requires explicit confirmation (`_CONFIRM_DESTROY=true`)
- Creates state backups
- Blocks production destruction

## Triggers

### Automatic Triggers

1. **Pull Request Plan** (`terraform-plan-pr`)
   - Runs on: Pull requests to main branch
   - Action: Terraform plan only
   - Safe for automatic execution

2. **Dev Deployment** (`terraform-apply-dev`)
   - Runs on: Merge to main branch
   - Action: Auto-deploy to dev environment
   - Automatic approval

3. **Staging Deployment** (`terraform-apply-staging`)
   - Runs on: Tags matching `staging-*`
   - Action: Deploy to staging
   - Manual trigger

4. **Production Deployment** (`terraform-apply-prod`)
   - Runs on: Tags matching `prod-v*`
   - Action: Deploy to production
   - Requires manual approval

### Manual Triggers

Create manual triggers for ad-hoc deployments:

```bash
gcloud builds triggers create manual \
  --name=manual-deploy \
  --build-config=cicd/cloudbuild/cloudbuild.yaml \
  --substitutions="_ENVIRONMENT=dev"
```

## Terraform State Management

### State Storage

Terraform state is stored in GCS with the following structure:

```
gs://PROJECT_ID-terraform-state/
├── midnight-platform/
│   ├── dev/
│   │   └── default.tfstate
│   ├── staging/
│   │   └── default.tfstate
│   └── prod/
│       └── default.tfstate
├── backups/
│   └── BUILD_ID/
└── plans/
    └── BUILD_ID/
```

### State Locking

GCS provides automatic state locking to prevent concurrent modifications.

### State Recovery

Recover from state issues:

```bash
# List state backups
gsutil ls gs://PROJECT_ID-terraform-state/backups/

# Restore a backup
gsutil cp gs://PROJECT_ID-terraform-state/backups/BUILD_ID/default.tfstate \
          gs://PROJECT_ID-terraform-state/midnight-platform/dev/default.tfstate
```

## IAM Permissions

The Cloud Build service account requires these roles:

```yaml
roles:
  - roles/storage.admin          # For Terraform state
  - roles/compute.admin          # For infrastructure
  - roles/workstations.admin     # For Cloud Workstations
  - roles/artifactregistry.admin # For container images
  - roles/iam.serviceAccountUser # For service accounts
  - roles/secretmanager.secretAccessor # For secrets (optional)
```

Grant permissions manually:

```bash
PROJECT_ID=your-project-id
CLOUD_BUILD_SA="${PROJECT_ID}@cloudbuild.gserviceaccount.com"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${CLOUD_BUILD_SA}" \
  --role="roles/storage.admin"
```

## Security Best Practices

### 1. Least Privilege

Grant minimal required permissions:

```bash
# Create custom role with specific permissions
gcloud iam roles create terraformDeployer \
  --project=${PROJECT_ID} \
  --permissions=compute.instances.create,compute.instances.delete
```

### 2. Approval Gates

Require approval for production:

```yaml
approvalConfig:
  approvalRequired: true
```

### 3. Branch Protection

Protect main branch and require PR reviews:
- Enable branch protection in GitHub
- Require status checks to pass
- Require PR approval before merge

### 4. Secrets Management

Use Secret Manager for sensitive values:

```yaml
steps:
  - name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        export API_KEY=$(gcloud secrets versions access latest --secret=api-key)
```

## Monitoring and Debugging

### View Build Logs

```bash
# List recent builds
gcloud builds list --limit=10

# View specific build logs
gcloud builds log BUILD_ID

# Stream logs in real-time
gcloud builds log BUILD_ID --stream
```

### Cloud Console

View builds in the console:
```
https://console.cloud.google.com/cloud-build/builds?project=PROJECT_ID
```

### Build Notifications

Set up notifications for build status:

```bash
# Create Pub/Sub topic
gcloud pubsub topics create cloud-builds

# Configure Cloud Build to publish to topic
gcloud builds configure --topic=projects/PROJECT_ID/topics/cloud-builds
```

## Troubleshooting

### Common Issues

1. **Service Account Error**
   ```
   ERROR: Service account project-id@cloudbuild.gserviceaccount.com does not exist
   ```
   **Solution**: Cloud Build uses project NUMBER, not project ID:
   ```bash
   # Get correct service account
   PROJECT_NUMBER=$(gcloud projects describe PROJECT_ID --format="value(projectNumber)")
   echo "${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
   ```

2. **Machine Type Error**
   ```
   ERROR: interpreting cicd/cloudbuild/cloudbuild.yaml as build config: .options.machineType: unused
   ```
   **Solution**: Move `machineType` to root level:
   ```yaml
   # Wrong
   options:
     machineType: 'n2-standard-8'
   
   # Correct
   machineType: 'n2-standard-8'
   options:
     logging: CLOUD_LOGGING_ONLY
   ```

3. **Permission Denied**
   ```
   Error: googleapi: Error 403: Required 'storage.buckets.get' permission
   ```
   **Solution**: Grant Storage Admin role to Cloud Build SA:
   ```bash
   make cloud-setup  # This will fix permissions
   ```

4. **State Lock**
   ```
   Error: Error acquiring the state lock
   ```
   **Solution**: Remove stale lock file from GCS:
   ```bash
   gsutil rm gs://PROJECT_ID-terraform-state/midnight-platform/ENV/default.tflock
   ```

5. **Timeout**
   ```
   ERROR: build step 0 "hashicorp/terraform:1.5.0" timed out
   ```
   **Solution**: Increase timeout in cicd/cloudbuild/cloudbuild.yaml:
   ```yaml
   timeout: '45m'  # Increase from 30m
   ```

6. **Invalid Substitution**
   ```
   ERROR: failed to parse substitutions
   ```
   **Solution**: Check substitution format:
   ```bash
   # Correct format
   --substitutions="_ENVIRONMENT=dev,_REGION=us-central1"
   ```

### Quick Diagnostic Commands

```bash
# Check Cloud Build configuration
make cloud-diagnose

# Test Cloud Build is working
make cloud-test

# View recent build logs
make cloud-logs

# Check service account
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:cloudbuild.gserviceaccount.com"
```

### Debug Mode

Enable verbose logging:

```yaml
options:
  logging: CLOUD_LOGGING_ONLY
  logStreamingOption: STREAM_ON
  env:
    - 'TF_LOG=DEBUG'
```

## Cost Optimization

### Build Machine Types

Choose appropriate machine types:

```yaml
options:
  machineType: 'n2-standard-8'  # For most builds
  # machineType: 'E2_HIGHCPU_8'  # For large infrastructures
```

### Build Caching

Cache Docker layers:

```yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '--cache-from', 'IMAGE', '.']
```

### Concurrent Builds

Limit concurrent builds to control costs:

```bash
gcloud builds configure --max-concurrent-builds=2
```

## Advanced Patterns

### Multi-Environment Deployment

Deploy to multiple environments:

```bash
for env in dev staging prod; do
  gcloud beta builds submit \
    --config=cicd/cloudbuild/cloudbuild.yaml \
    --substitutions="_ENVIRONMENT=$env" \
    --async
done
```

### Blue-Green Deployment

Implement blue-green deployments:

```yaml
steps:
  # Deploy to green environment
  - name: 'hashicorp/terraform'
    args: ['apply', '-target=module.green']
  
  # Switch traffic
  - name: 'gcr.io/cloud-builders/gcloud'
    args: ['compute', 'backend-services', 'update']
```

### Rollback Procedure

Rollback to previous version:

```bash
# Get previous state version
gsutil ls -l gs://PROJECT_ID-terraform-state/midnight-platform/prod/

# Restore previous state
gsutil cp gs://PROJECT_ID-terraform-state/midnight-platform/prod/default.tfstate#1234567890 \
          gs://PROJECT_ID-terraform-state/midnight-platform/prod/default.tfstate

# Re-run Terraform
gcloud beta builds submit --config=cicd/cloudbuild/cloudbuild.yaml
```

## Migration from Local Deployment

### Step 1: Export Current State

```bash
terraform state pull > current-state.json
```

### Step 2: Upload to GCS

```bash
gsutil cp current-state.json \
  gs://PROJECT_ID-terraform-state/midnight-platform/dev/default.tfstate
```

### Step 3: Verify Cloud Build

```bash
gcloud beta builds submit --config=cicd/cloudbuild/cloudbuild-plan.yaml
```

### Step 4: Switch to Cloud Build

```bash
USE_CLOUD_BUILD=true ./scripts/deploy.sh PROJECT_ID
```

## Additional Resources

- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Terraform GCS Backend](https://www.terraform.io/docs/language/settings/backends/gcs.html)
- [Cloud Build Triggers](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers)
- [IAM Best Practices](https://cloud.google.com/iam/docs/best-practices)