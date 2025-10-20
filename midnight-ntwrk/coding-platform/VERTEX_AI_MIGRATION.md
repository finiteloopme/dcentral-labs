# Vertex AI Migration Complete

## Changes Made

### 1. Updated Container for Vertex AI Support
- **Modified `docker/run-local.sh`**: 
  - Removed ANTHROPIC_API_KEY environment variable handling
  - Added automatic mounting of gcloud credentials from `~/.config/gcloud`
  - Container now mounts credentials as read-only for security

### 2. Updated Documentation
- **`OPENCODE_USAGE.md`**: 
  - Removed all ANTHROPIC_API_KEY references
  - Added gcloud authentication prerequisites
  - Updated to show Vertex AI/Claude configuration
  
- **`LOCAL_DEVELOPMENT.md`**: 
  - Updated OpenCode section to reflect Vertex AI usage
  - Added gcloud authentication instructions
  
- **`docs/SECURITY.md`**: 
  - Replaced API key references with Google Cloud IAM authentication

### 3. Updated Configuration Files
- **`docker/entrypoint-local.sh`**: 
  - Removed ANTHROPIC_API_KEY instructions
  - Added note about Vertex AI configuration
  
- **`docker/scripts/opencode-config-template.json`**: 
  - Set default model to `google-vertex-anthropic/claude-3-5-sonnet-v2@20241022`
  - Removed direct Anthropic provider configuration
  - Kept only Vertex AI providers (google-vertex-anthropic and google-vertex)

## How to Use

### Prerequisites
1. **Authenticate with Google Cloud** (on host machine):
   ```bash
   gcloud auth application-default login
   ```

2. **Ensure Vertex AI API is enabled**:
   ```bash
   gcloud services enable aiplatform.googleapis.com
   ```

### Running Locally
```bash
# Build the container
make build

# Run with mounted gcloud credentials
make run-local
```

### Using OpenCode
Once in the container:
```bash
# OpenCode is pre-configured for Vertex AI
opencode
```

## Benefits of Vertex AI Migration

1. **No API Key Management**: Uses Google Cloud IAM for authentication
2. **Enterprise Security**: Leverages GCP's security infrastructure
3. **Better Integration**: Works seamlessly with other GCP services
4. **Cost Tracking**: Usage billed to your GCP project with clear cost attribution

## Verification

The container will automatically:
- Mount your gcloud credentials from `~/.config/gcloud`
- Configure OpenCode to use Vertex AI
- Use Claude 3.5 Sonnet via Vertex AI endpoint

## Troubleshooting

If OpenCode fails to connect:
1. Verify gcloud authentication: `gcloud auth list`
2. Check project: `gcloud config get-value project`
3. Ensure Vertex AI API is enabled
4. Verify credentials are mounted: `ls -la ~/.config/gcloud` (in container)

## Migration Complete ✅

All references to ANTHROPIC_API_KEY have been removed and replaced with Vertex AI integration using gcloud credentials.