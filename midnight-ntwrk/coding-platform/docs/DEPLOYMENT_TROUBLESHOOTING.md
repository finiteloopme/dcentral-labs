# Deployment Troubleshooting Guide

## Overview

This guide helps troubleshoot common deployment issues with the Midnight Development Platform.

## Deployment Process

The deployment uses Google Cloud Build to:
1. Build the Docker container with integrated mock proof server
2. Push to Artifact Registry
3. Deploy infrastructure with Terraform
4. Create Cloud Workstations

## Common Issues and Solutions

### Build Failures

**Issue: Docker build fails**
```
Error: failed to solve: process "/bin/sh -c npm install -g @midnight/prove@latest" did not complete successfully
```

**Solution:**
- Check network connectivity
- Verify npm registry access
- Try building locally: `make build`

### Terraform Errors

**Issue: State lock timeout**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

**Issue: Permission denied**
```
Error: googleapi: Error 403: Required 'compute.instances.create' permission
```

**Solution:**
- Ensure Cloud Build service account has required roles:
  ```bash
  gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:midnight-cloudbuild-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"
  ```

### Workstation Issues

**Issue: Workstation won't start**
```
Error: Workstation is in state STOPPED
```

**Solution:**
```bash
# Start workstation
make ws-start WORKSTATION_ID=midnight-developer-1

# Check status
gcloud workstations describe midnight-developer-1 \
  --cluster=midnight-dev-cluster \
  --config=midnight-dev-config \
  --region=us-central1
```

**Issue: Can't connect to workstation**
```
Error: Failed to connect to workstation
```

**Solution:**
```bash
# Create SSH tunnel
make ws-tunnel WORKSTATION_ID=midnight-developer-1

# Or open in browser
make ws-open WORKSTATION_ID=midnight-developer-1
```

### Container Registry Issues

**Issue: Can't push image**
```
Error: denied: Permission "artifactregistry.repositories.uploadArtifacts" denied
```

**Solution:**
```bash
# Configure Docker authentication
gcloud auth configure-docker us-central1-docker.pkg.dev

# Verify registry exists
gcloud artifacts repositories describe midnight-dev-workstation-images \
  --location=us-central1
```

### Cloud Build Issues

**Issue: Build trigger not working**
```
Error: Trigger not found
```

**Solution:**
```bash
# Import triggers
gcloud builds triggers import \
  --source=cicd/cloudbuild/cloudbuild-triggers.yaml

# List triggers
gcloud builds triggers list
```

**Issue: Substitution variable errors**
```
Error: Substitution _ENVIRONMENT not found
```

**Solution:**
- Verify all required substitutions are defined
- Check `cicd/cloudbuild/cloudbuild.yaml` for required variables

## Debugging Commands

### Check Deployment Status
```bash
# View current configuration
make config

# Check build history
gcloud builds list --limit=5

# View build logs
gcloud builds log <build-id>
```

### Validate Configuration
```bash
# Check requirements
make deploy  # Will validate before deploying

# Test build locally
make build

# Verify Terraform
cd terraform && terraform validate
```

### Monitor Resources
```bash
# List workstations
gcloud workstations list \
  --cluster=midnight-dev-cluster \
  --config=midnight-dev-config \
  --region=us-central1

# Check container images
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/PROJECT_ID/midnight-dev-workstation-images
```

## Rollback Procedures

### Revert Infrastructure
```bash
# Destroy specific resources
cd terraform
terraform destroy -target=google_workstations_workstation.developer

# Full teardown
make undeploy
```

### Restore Previous Image
```bash
# List available images
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/PROJECT_ID/midnight-dev-workstation-images

# Update workstation config to use specific image
gcloud workstations configs update midnight-dev-config \
  --cluster=midnight-dev-cluster \
  --region=us-central1 \
  --container-custom-image=us-central1-docker.pkg.dev/PROJECT_ID/midnight-dev-workstation-images/workstation:TAG
```

## Getting Help

If issues persist:
1. Check Cloud Build logs: `gcloud builds log <build-id>`
2. Review Terraform state: `terraform show`
3. Examine workstation logs in Cloud Console
4. Contact support with error messages and build IDs