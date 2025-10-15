# Cloud Build CI/CD Setup

This guide covers the automated CI/CD pipeline using Google Cloud Build.

## Quick Setup

```bash
# Automated setup
./scripts/setup-cloudbuild.sh

# Manual trigger
gcloud builds submit --config=cloudbuild.yaml
```

## Build Configurations

### Cloud Source Repositories (Default)

**File**: `cloudbuild.yaml`

Triggers:
- **Push to main**: Auto-deploy with Terraform apply
- **Pull requests**: Terraform plan only
- **Manual**: On-demand deployment

### GitHub Integration

**File**: `cloudbuild-github.yaml`

1. Install Cloud Build GitHub app:
   ```bash
   open https://github.com/apps/google-cloud-build
   ```

2. Connect repository in Cloud Console

3. Create triggers via Console or CLI

## Build Pipeline

1. **Build Image**: Using Kaniko (rootless)
2. **Push to Registry**: With SHA and latest tags
3. **Terraform Plan**: Validate changes
4. **Terraform Apply**: Deploy (main branch only)

## Monitoring

```bash
# View build history
gcloud builds list --limit=10

# Stream logs
gcloud builds log BUILD_ID --stream

# Trigger manual build
gcloud builds triggers run deploy-web3-workstation --branch=main
```

## Customization

Edit `cloudbuild.yaml` substitutions:

```yaml
substitutions:
  _REGION: 'us-central1'
  _ENVIRONMENT: 'production'
  _FORCE_APPLY: 'true'
```

## Permissions

Cloud Build service account needs:
- `roles/artifactregistry.writer`
- `roles/storage.admin`
- `roles/compute.admin`
- `roles/workstations.admin`

These are automatically configured by Terraform.