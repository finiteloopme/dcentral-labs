# Fixing Vertex AI Authentication in Cloud Workstations

## Problem

Cloud Workstations were unable to authenticate with Vertex AI because:
1. The default Compute Engine service account lacks necessary IAM permissions
2. No dedicated service account was configured for workstations
3. The `aiplatform.googleapis.com` API wasn't enabled in Terraform

## Solution

### 1. Terraform Changes

The following changes were made to properly configure Vertex AI access:

#### a. Created Dedicated Service Account (`terraform/modules/workstations/main.tf`)
- Created a dedicated service account for workstations
- Granted necessary IAM roles:
  - `roles/aiplatform.user` - Access Vertex AI models
  - `roles/serviceusage.serviceUsageConsumer` - Use Google Cloud services
  - `roles/logging.logWriter` - Write logs
  - `roles/monitoring.metricWriter` - Write metrics
  - `roles/storage.objectViewer` - Read from Cloud Storage

#### b. Updated Workstation Configuration
- Added `service_account` field to use the dedicated account
- Added `GCP_PROJECT_ID` and `GOOGLE_CLOUD_PROJECT` environment variables
- Ensured proper OAuth scopes are configured

#### c. Enabled Vertex AI API (`terraform/main.tf`)
- Added `aiplatform.googleapis.com` to the list of enabled APIs

### 2. Applying the Fix

#### For New Deployments

```bash
# Initialize and apply terraform
cd terraform
terraform init
terraform plan
terraform apply
```

#### For Existing Workstations

**Option 1: Recreate Workstations (Recommended)**
```bash
# This will recreate the workstation config with the new service account
cd terraform
terraform apply -target=module.workstations
```

**Note:** This will require recreating the workstation configuration, which means existing workstations will need to be recreated.

**Option 2: Manual IAM Grant (Temporary)**
If you can't recreate workstations immediately, grant permissions to the default service account:

```bash
# Get the default service account
PROJECT_ID="your-project-id"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
DEFAULT_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Grant Vertex AI permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${DEFAULT_SA}" \
  --role="roles/aiplatform.user"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${DEFAULT_SA}" \
  --role="roles/serviceusage.serviceUsageConsumer"
```

### 3. Verification

#### Inside a Cloud Workstation

Run the diagnostic script:
```bash
./scripts/fix-vertex-ai-auth.sh
```

This script will:
- Check if Vertex AI API is enabled
- Verify authentication status
- Test model access
- Configure OpenCode automatically

#### Manual Verification

```bash
# Check current authentication
gcloud auth list

# Verify project
gcloud config get-value project

# Test Vertex AI access
gcloud ai models list --region=global --limit=5

# Check service account
curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" \
  -H "Metadata-Flavor: Google"
```

### 4. Using OpenCode with Vertex AI

Once authentication is fixed:

```bash
# OpenCode should automatically detect the GCP project
opencode

# Test with a Vertex AI model
/model google-vertex-anthropic/claude-3-5-haiku@20241022

# Ask a test question
What is 2+2?
```

## Troubleshooting

### Issue: "Permission denied" when accessing Vertex AI

**Cause:** Service account lacks necessary permissions
**Fix:** Apply terraform changes or manually grant IAM roles

### Issue: "API not enabled" error

**Cause:** `aiplatform.googleapis.com` is not enabled
**Fix:** 
```bash
gcloud services enable aiplatform.googleapis.com --project=YOUR_PROJECT_ID
```

### Issue: OpenCode not detecting project

**Cause:** `GCP_PROJECT_ID` environment variable not set
**Fix:** Ensure the workstation config includes the environment variable (applied via terraform)

### Issue: Models not appearing in list

**Cause:** Models may not be available in your region
**Fix:** Check available regions:
```bash
gcloud ai models list --region=us-central1
gcloud ai models list --region=europe-west4
gcloud ai models list --region=global
```

## Architecture Overview

```
┌─────────────────────────────┐
│   Cloud Workstation         │
│                             │
│  ┌────────────────────┐     │
│  │ Container           │     │
│  │                     │     │
│  │ - OpenCode          │     │
│  │ - gcloud CLI        │     │
│  │ - GCP_PROJECT_ID    │     │
│  └────────────────────┘     │
│           │                 │
│           ▼                 │
│  ┌────────────────────┐     │
│  │ Metadata Service    │     │
│  │                     │     │
│  │ Service Account:    │     │
│  │ midnight-workstation│     │
│  └────────────────────┘     │
└─────────────────────────────┘
            │
            ▼
┌─────────────────────────────┐
│   Google Cloud IAM          │
│                             │
│  Roles:                     │
│  - aiplatform.user          │
│  - serviceusage.consumer    │
│  - logging.logWriter        │
│  - monitoring.metricWriter  │
│  - storage.objectViewer     │
└─────────────────────────────┘
            │
            ▼
┌─────────────────────────────┐
│   Vertex AI API             │
│                             │
│  - Claude Models            │
│  - Gemini Models            │
└─────────────────────────────┘
```

## Best Practices

1. **Use Dedicated Service Accounts**: Always use dedicated service accounts for workstations rather than default compute accounts
2. **Principle of Least Privilege**: Grant only necessary permissions
3. **Environment Variables**: Pass project configuration via environment variables
4. **Automatic Configuration**: Use startup scripts to configure tools automatically
5. **Regular Audits**: Periodically review IAM permissions and remove unnecessary access

## Related Documentation

- [Vertex AI Setup Guide](./VERTEX_AI_SETUP.md)
- [Workstation Management](./WORKSTATION_MANAGEMENT.md)
- [Cloud Build Configuration](./CLOUD_BUILD.md)