# Vertex AI Configuration for OpenCode

This guide explains how to configure OpenCode to use multiple LLMs through Google Cloud Vertex AI.

## Overview

The Midnight Development Platform now includes OpenCode AI assistant configured to access:
- **Claude models** (Anthropic) via Vertex AI
- **Gemini models** (Google) via Vertex AI
- Direct API access (with API keys)

## Available Models

### Claude Models (via Vertex AI)
- `claude-opus-4-1@20250805` - Claude Opus 4.1 - Most advanced model
- `claude-3-5-sonnet-v2@20241022` - Claude 3.5 Sonnet - Balanced performance
- `claude-3-5-haiku@20241022` - Claude 3.5 Haiku - Fast and efficient

### Gemini Models (via Vertex AI)
- `gemini-2.5-pro` - Gemini 2.5 Pro - Advanced multimodal model
- `gemini-2.5-flash` - Gemini 2.5 Flash - Fast multimodal model

## Prerequisites

1. **Google Cloud Project** with billing enabled
2. **Vertex AI API** enabled
3. **Authentication** configured

## Setup Instructions

### 1. Enable Vertex AI API

```bash
gcloud services enable aiplatform.googleapis.com
```

### 2. Set Up Authentication

#### Option A: Using Cloud Workstations (Automatic)
When running in Google Cloud Workstations, authentication is handled automatically through the workstation's service account.

#### Option B: Local Development with gcloud
```bash
# Login to Google Cloud
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Set application default credentials
gcloud auth application-default login
```

#### Option C: Using Service Account Key
```bash
# Create a service account
gcloud iam service-accounts create opencode-vertex \
  --display-name="OpenCode Vertex AI"

# Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:opencode-vertex@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# Create and download key
gcloud iam service-accounts keys create ~/opencode-vertex-key.json \
  --iam-account=opencode-vertex@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=~/opencode-vertex-key.json
```

### 3. Configure OpenCode

The platform automatically configures OpenCode when it detects a GCP project. You can also manually configure it:

```bash
# Run the configuration script
configure-opencode

# Or set project ID and run
GCP_PROJECT_ID=your-project-id configure-opencode
```

### 4. Using with Local Development

#### Option A: Using run-local script (Recommended)

The `run-local` script automatically mounts your local gcloud credentials:

```bash
# Authenticate locally first
gcloud auth login
gcloud auth application-default login

# Run with your project ID
GCP_PROJECT_ID=your-project-id make run-local
```

This automatically:
- Mounts `~/.config/gcloud` into the container
- Passes your GCP project ID
- Enables Vertex AI access using your local credentials

#### Option B: Using Docker Compose

Add your project ID to the `.env` file:
```env
GCP_PROJECT_ID=your-project-id
MOUNT_GCLOUD_CREDS=true
```

Then start the services:
```bash
make compose-up
```

#### Option C: Using Service Account Key

If you prefer using a service account key:
```bash
# Set the path to your key
export GOOGLE_APPLICATION_CREDENTIALS=~/keys/my-service-account.json

# Run the container
make run-local
```

## Configuration File

OpenCode configuration is stored at `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "opencode",
  "autoupdate": true,
  "model": "google-vertex-anthropic/claude-opus-4-1@20250805",
  "small_model": "google-vertex-anthropic/claude-3-5-haiku@20241022",
  "provider": {
    "google-vertex-anthropic": {
      "models": {
        "claude-opus-4-1@20250805": {},
        "claude-3-5-sonnet-v2@20241022": {},
        "claude-3-5-haiku@20241022": {}
      },
      "options": {
        "project": "YOUR_PROJECT_ID",
        "location": "global"
      }
    },
    "google-vertex": {
      "models": {
        "gemini-2.5-pro": {},
        "gemini-2.5-flash": {}
      },
      "options": {
        "project": "YOUR_PROJECT_ID",
        "location": "global"
      }
    }
  }
}
```

## Switching Between Models

### Using the Helper Script
```bash
# Run the model switcher
~/.config/opencode/switch-model.sh
```

### Using OpenCode Commands
Within OpenCode, you can switch models using:
```
/model google-vertex-anthropic/claude-opus-4-1@20250805
/model google-vertex-anthropic/claude-3-5-haiku@20241022
/model google-vertex/gemini-2.5-pro
/model google-vertex/gemini-2.5-flash
```

### Programmatically
Update the config file:
```bash
# Switch to Gemini 2.5 Pro
jq '.model = "google-vertex/gemini-2.5-pro"' \
  ~/.config/opencode/opencode.json > /tmp/opencode.json && \
  mv /tmp/opencode.json ~/.config/opencode/opencode.json

# Switch to Claude Opus 4.1
jq '.model = "google-vertex-anthropic/claude-opus-4-1@20250805"' \
  ~/.config/opencode/opencode.json > /tmp/opencode.json && \
  mv /tmp/opencode.json ~/.config/opencode/opencode.json
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GCP_PROJECT_ID` | Your Google Cloud project ID | `my-project-123` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account key | `/path/to/key.json` |
| `VERTEX_AI_LOCATION` | Vertex AI region | `global` |

## Terraform Configuration

When deploying with Terraform, add these variables:

```hcl
variable "enable_vertex_ai" {
  description = "Enable Vertex AI for OpenCode"
  type        = bool
  default     = true
}

variable "vertex_ai_location" {
  description = "Vertex AI location"
  type        = string
  default     = "global"
}
```

In your `terraform.tfvars`:
```hcl
enable_vertex_ai = true
vertex_ai_location = "global"
```

## Cost Considerations

For current pricing information, please refer to:
- [Vertex AI Pricing](https://cloud.google.com/vertex-ai/pricing) - Official pricing page
- [Claude on Vertex AI Pricing](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-claude#claude-pricing) - Claude-specific pricing
- [Gemini Pricing](https://cloud.google.com/vertex-ai/generative-ai/pricing#gemini-models) - Gemini model pricing

### Cost Optimization Tips

1. **Choose the right model for the task** - Use faster/cheaper models like Haiku or Flash for simple tasks
2. **Set spending limits** in Google Cloud Console
3. **Monitor usage** with Cloud Monitoring
4. **Use local models** for development when possible
5. **Review pricing regularly** - Model pricing can change over time

## Security Considerations for Local Development

### Credential Mounting

By default, `run-local` mounts your gcloud credentials as **read-only** to enable Vertex AI access. You can disable this:

```bash
# Don't mount any credentials
MOUNT_GCLOUD_CREDS=false make run-local
```

### What Gets Mounted

When `MOUNT_GCLOUD_CREDS=true` (default):
- `~/.config/gcloud` - Mounted as read-only
- Application default credentials - Mounted as read-only
- Service account keys (if specified) - Mounted as read-only

The container cannot modify your local credentials.

## Troubleshooting

### Authentication Issues

```bash
# Check current authentication
gcloud auth list

# Verify project
gcloud config get-value project

# Test Vertex AI access
gcloud ai models list --region=us-central1
```

### OpenCode Not Finding Models

```bash
# Verify configuration
cat ~/.config/opencode/opencode.json

# Check if APIs are enabled
gcloud services list --enabled | grep aiplatform

# Test model availability
gcloud ai models list --region=global --filter="displayName:claude-opus-4-1"
gcloud ai models list --region=global --filter="displayName:gemini-2.5"

# Reconfigure OpenCode
configure-opencode
```

### Permission Errors

Ensure your account/service account has these roles:
- `roles/aiplatform.user` - Use Vertex AI models
- `roles/serviceusage.serviceUsageConsumer` - Use Google Cloud services

Grant permissions:
```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:YOUR_EMAIL@domain.com" \
  --role="roles/aiplatform.user"
```

### Rate Limits

Vertex AI has quotas and rate limits. If you encounter rate limit errors:
1. Check your quotas in Cloud Console
2. Request quota increases if needed
3. Implement retry logic with exponential backoff

## Security Best Practices

1. **Never commit credentials** - Don't commit service account keys to git
2. **Use IAM roles** - Prefer workload identity over service account keys
3. **Rotate keys regularly** - If using service account keys
4. **Limit permissions** - Grant minimum necessary permissions
5. **Use Secret Manager** - For production deployments

## Advanced Configuration

### Using Multiple Projects

```json
{
  "provider": {
    "google-vertex-anthropic-dev": {
      "options": {
        "project": "dev-project",
        "location": "us-central1"
      }
    },
    "google-vertex-anthropic-prod": {
      "options": {
        "project": "prod-project",
        "location": "us-central1"
      }
    }
  }
}
```

### Regional Configuration

Different regions for different models:
```json
{
  "provider": {
    "google-vertex-anthropic": {
      "options": {
        "project": "my-project",
        "location": "us-central1"
      }
    },
    "google-vertex": {
      "options": {
        "project": "my-project",
        "location": "europe-west4"
      }
    }
  }
}
```

### Custom Model Parameters

You can configure model-specific parameters in the provider options:

```json
{
  "provider": {
    "google-vertex-anthropic": {
      "options": {
        "project": "YOUR_PROJECT_ID",
        "location": "global",
        "temperature": 0.7,
        "maxTokens": 8192,
        "topP": 0.9
      }
    },
    "google-vertex": {
      "options": {
        "project": "YOUR_PROJECT_ID",
        "location": "global",
        "temperature": 0.8,
        "maxOutputTokens": 8192,
        "topK": 40,
        "topP": 0.95
      }
    }
  }
}
```

## Integration with Development Workflow

### VS Code Integration

OpenCode can integrate with VS Code in the workstation:
```json
{
  "editor": {
    "command": "code",
    "args": ["--goto", "${file}:${line}:${column}"]
  }
}
```

### Git Integration

Configure OpenCode to understand your repository:
```bash
# In your project directory
opencode --context .
```

### Custom Commands

Add custom commands to OpenCode:
```json
{
  "commands": {
    "deploy": "make deploy",
    "test": "npm test",
    "build": "make build"
  }
}
```

## Monitoring and Logging

### View OpenCode Logs

```bash
# OpenCode logs
tail -f ~/.config/opencode/logs/opencode.log

# Vertex AI requests
gcloud logging read "resource.type=aiplatform.googleapis.com"
```

### Monitor Usage

```bash
# Check Vertex AI usage
gcloud alpha ai operations list --region=us-central1

# Monitor costs
gcloud billing accounts get-iam-policy BILLING_ACCOUNT_ID
```

## Support and Resources

- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [OpenCode Documentation](https://docs.opencode.ai)
- [Claude on Vertex AI](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/claude)
- [Gemini Models](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)

For issues specific to the Midnight Development Platform:
- GitHub Issues: [midnight-network/cloud-platform](https://github.com/midnight-network/cloud-platform/issues)
- Discord: [Midnight Network Discord](https://discord.gg/midnight)