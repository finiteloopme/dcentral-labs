# Vertex AI Setup for OpenCode

This guide explains how to configure OpenCode to use Vertex AI models (Gemini and Claude) in the Web3 Workstation.

## Prerequisites

1. Google Cloud Project with billing enabled
2. Vertex AI API enabled
3. Authentication configured

## Quick Setup

### 1. Enable Vertex AI API

```bash
# If not already done during terraform setup
gcloud services enable aiplatform.googleapis.com
```

### 2. Set up Authentication

For local development:
```bash
# Authenticate your local machine
gcloud auth application-default login

# Set your project
export GOOGLE_CLOUD_PROJECT=your-project-id
```

For container usage:
```bash
# Mount your credentials when running the container
make local  # This automatically mounts ~/.config/gcloud
```

### 3. Configure OpenCode

Inside the container:
```bash
# Start OpenCode
opencode

# Configure Vertex AI provider (first time only)
/auth login
# Select: vertex-ai
# Enter your GCP project ID when prompted
```

## Available Models

OpenCode in this workstation is pre-configured with:

### Gemini Models (via Google Vertex AI)
- `google-vertex/gemini-2.0-flash-exp` (default - fastest)
- `google-vertex/gemini-2.0-flash-thinking-exp-1219` (reasoning model)
- `google-vertex/gemini-1.5-flash` (lightweight tasks)
- `google-vertex/gemini-1.5-flash-8b` (smallest model)
- `google-vertex/gemini-1.5-pro` (complex tasks)
- `google-vertex/gemini-exp-1206` (experimental)

### Claude Models (via Vertex AI Model Garden)
- `google-vertex-anthropic/claude-3-5-sonnet@20241022` 
- `google-vertex-anthropic/claude-3-opus@20240229`
- `google-vertex-anthropic/claude-3-haiku@20240307`

Note: Claude 4 models are pre-configured and will work when available on Vertex AI.

## Switching Models

In OpenCode, you can switch models using:
```
/model google-vertex/gemini-1.5-pro
```

Or set a default in your config:
```jsonc
// ~/.config/opencode/opencode.jsonc
{
  "model": "google-vertex/gemini-2.0-flash-exp"
}
```

## Configuration

The OpenCode configuration file (`~/.config/opencode/opencode.jsonc`) is pre-configured with:

- **Provider settings** for `google-vertex` and `google-vertex-anthropic`
- **Model definitions** for all available Gemini and Claude models
- **Environment variable substitution** using `{env:GOOGLE_CLOUD_PROJECT}`
- **Web3-specific commands** for Foundry development

## Custom Instructions

The workstation includes Web3-specific instructions in:
- `/home/developer/.opencode/rules/web3-development.md`
- `/home/developer/.opencode/rules/defi.md`

These automatically guide the AI for smart contract development.

## Troubleshooting

### Authentication Issues

If you see authentication errors:
```bash
# Verify authentication
gcloud auth application-default print-access-token

# Re-authenticate if needed
gcloud auth application-default login
```

### Model Not Found

If a model is not available:
1. Check if the model is available in your region
2. Verify Vertex AI API is enabled
3. Check quota limits in GCP Console

### Permission Denied

Ensure your account has these IAM roles:
- `roles/aiplatform.user` (for using models)
- `roles/aiplatform.viewer` (for listing models)

## Cost Optimization

- Use `gemini-2.0-flash-exp` for most tasks (cheapest and fastest)
- Switch to Pro models only for complex reasoning
- Monitor usage in GCP Console > Vertex AI > Quotas

## Environment Variables

The container automatically sets:
- `GOOGLE_CLOUD_PROJECT` - Your GCP project ID
- `VERTEX_AI_LOCATION` - Region (default: us-central1)

## Additional Resources

- [Vertex AI Pricing](https://cloud.google.com/vertex-ai/pricing)
- [Gemini Models Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/models/gemini)
- [OpenCode Documentation](https://opencode.ai/docs)