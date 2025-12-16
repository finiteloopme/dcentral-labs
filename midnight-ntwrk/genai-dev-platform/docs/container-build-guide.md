# Container Build and Deployment Guide

This guide explains how to build and deploy the Midnight Development Platform container image for Google Cloud Workstations.

## 🚀 Quick Start

### 1. Build and Push Container Image

```bash
# Build and push image only
make build-image

# Build and update specific workstation
make build-image WORKSTATION_ID=midnight-developer-1
```

### 2. Restart Workstation to Pick Up Latest Image

```bash
# Stop workstation
make ws-stop WORKSTATION_ID=midnight-developer-1

# Start workstation (will use latest image)
make ws-start WORKSTATION_ID=midnight-developer-1
```

## 📋 Container Build Process

### What Gets Built

The container image includes:
- **OpenCode TUI** - Terminal-based AI code editor
- **Midnight Network Tools** - Node, Proof Server, Indexer
- **VS Code Extensions** - Midnight Compact, TypeScript, Rust
- **Vertex AI Integration** - Pre-configured with project settings
- **Developer Helper** - `midnight-dev` CLI for project management

### Build Configuration

**File**: `cicd/cloudbuild/cloudbuild-image.yaml`

**Image Tags**:
- `latest` - Always points to the most recent build
- `{BUILD_ID}` - Unique build identifier for version tracking

**Artifact Registry Location**:
```
{region}-docker.pkg.dev/{project-id}/midnight-{environment}-workstation-images/midnight-workstation
```

## 🔧 Manual Build Process

### Prerequisites

1. **Google Cloud SDK** installed and authenticated
2. **Project ID** set in environment or `.env` file
3. **Service Account** with necessary permissions

### Environment Variables

```bash
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_VERTEX_REGION="us-central1"
export MIDNIGHT_ENV="dev"
```

### Build Commands

```bash
# Using existing gcloud commands script
./scripts/gcloud-commands.sh build-image

# Build and update specific workstation
./scripts/gcloud-commands.sh build-image developer-2

# Using gcloud directly
gcloud builds submit \
  --config=cicd/cloudbuild/cloudbuild-image.yaml \
  --substitutions="_PROJECT_ID=your-project,_REGION=us-central1,_ENVIRONMENT=dev"
```

## 🔄 Automated Builds

### Setting up Triggers

1. **Manual Trigger Setup**:
   ```bash
   # Follow instructions in cicd/cloudbuild/trigger-setup.md
   ```

2. **Automatic on Push**:
   - Triggers when code is pushed to `main` branch
   - Builds and pushes container automatically
   - Updates specified workstation if provided

### Trigger Configuration

**Event**: Push to branch  
**Branch**: `^main$`  
**Build Config**: `cicd/cloudbuild/cloudbuild-image.yaml`  
**Substitutions**:
- `_ENVIRONMENT=dev`
- `_REGION=us-central1`
- `_IMAGE_NAME=midnight-workstation`

## 🏗️ Container Image Contents

### Base Image
- **Source**: `us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest`
- **Includes**: VS Code Server, Google Cloud SDK, development tools

### Container Build File
- **Dockerfile**: Main container definition (only Dockerfile - no .refactored version)
- **Location**: Project root directory
- **Includes**: All Midnight tools, OpenCode, VS Code extensions, startup scripts

### Midnight Components
- **Midnight Node**: v0.8.0
- **Proof Server**: v4.0.0  
- **Indexer**: v2.3.0
- **Compact Compiler**: Latest release

### Development Tools
- **OpenCode**: `/usr/local/opencode/opencode`
- **Node.js**: v20.19.2
- **Java**: Temurin JDK 22
- **Rust**: Latest stable toolchain

### Configuration Files
- **OpenCode Config**: `/etc/opencode/config.json`
- **Midnight Services**: `/home/user/midnight-dev/`
- **Startup Scripts**: `/etc/workstation-startup.d/`

## 📦 Image Updates and Versioning

### Version Strategy

1. **`latest` tag**: Always points to the most recent successful build
2. **`{BUILD_ID}` tag**: Unique identifier for each build
3. **Rollback capability**: Can revert to previous build by tag

### Update Process

1. **Code Changes** → Push to `main` branch
2. **Automatic Build** → Cloud Build triggers
3. **Image Push** → Artifact Registry updated
4. **Workstation Restart** → Picks up new image

### Manual Updates

```bash
# 1. Build new image
make build-image

# 2. Update specific workstation
gcloud workstations update my-workstation \
  --cluster=midnight-dev-cluster \
  --region=us-central1 \
  --image=us-central1-docker.pkg.dev/my-project/midnight-dev-workstation-images/midnight-workstation:latest

# 3. Restart workstation
make ws-stop WORKSTATION_ID=my-workstation
make ws-start WORKSTATION_ID=my-workstation
```

## 🔍 Troubleshooting

### Build Failures

1. **Check permissions**:
   ```bash
   gcloud projects get-iam-policy your-project
   ```

2. **Verify service account**:
   ```bash
   gcloud iam service-accounts describe midnight-cloudbuild-sa@your-project.iam.gserviceaccount.com
   ```

3. **Check Artifact Registry**:
   ```bash
   gcloud artifacts repositories list --location=us-central1
   ```

### Workstation Not Updating

1. **Force image update**:
   ```bash
   gcloud workstations update my-workstation \
     --cluster=midnight-dev-cluster \
     --region=us-central1 \
     --image=us-central1-docker.pkg.dev/my-project/midnight-dev-workstation-images/midnight-workstation:BUILD_ID
   ```

2. **Check current image**:
   ```bash
   gcloud workstations describe my-workstation \
     --cluster=midnight-dev-cluster \
     --region=us-central1 \
     --format="value(container.image)"
   ```

### OpenCode Not Available

1. **Check container logs**:
   ```bash
   make logs WORKSTATION_ID=my-workstation
   ```

2. **Verify installation**:
   ```bash
   make exec WORKSTATION_ID=my-workstation "which opencode"
   ```

## 📚 Additional Resources

- **Cloud Build Documentation**: https://cloud.google.com/build/docs
- **Artifact Registry**: https://cloud.google.com/artifact-registry
- **Cloud Workstations**: https://cloud.google.com/workstations
- **OpenCode Configuration**: https://opencode.ai/docs/config

## 📋 Files Created/Modified

1. **`cicd/cloudbuild/cloudbuild-image.yaml`** - Container build configuration
2. **`scripts/gcloud-commands.sh`** - Added build_image() function
3. **`cicd/cloudbuild/trigger-setup.md`** - GitHub trigger setup guide
4. **`docs/container-build-guide.md`** - Comprehensive documentation
5. **`Makefile`** - Added build-image command
6. **`terraform/modules/workstations/main.tf`** - Updated image reference
7. **`README.md`** - Updated with new workflow