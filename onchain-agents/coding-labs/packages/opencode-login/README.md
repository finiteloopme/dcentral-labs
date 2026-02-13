# dCoder Login Page

Landing page for dCoder with "Sign in with Google" functionality.

## Overview

This is a simple static landing page that:
- Displays the dCoder branding with ASCII art
- Shows key features of the platform
- Provides a "Sign in with Google" button that redirects to the IAP-protected main app

## Architecture

```
┌──────────────────────┐         ┌──────────────────────────┐
│   opencode-login     │         │      opencode-web        │
│   (Public)           │         │   (IAP Protected)        │
│                      │         │                          │
│   Landing page with  │  ──→    │   Main application       │
│   "Sign in" button   │  click  │   IAP handles Google     │
│                      │         │   OAuth automatically    │
└──────────────────────┘         └──────────────────────────┘
```

## Development

### Local Testing

```bash
# Install dependencies
cd packages/opencode-login
npm install

# Run locally
APP_URL=http://localhost:4097 npm start

# Visit http://localhost:8080
```

### With Docker/Podman

```bash
# Build from project root
podman build -f packages/opencode-login/Containerfile -t opencode-login .

# Run
podman run -p 8080:8080 -e APP_URL=http://localhost:4097 opencode-login
```

### With Docker Compose (optional profile)

```bash
# From project root - includes login page
docker compose --profile login up

# Login page: http://localhost:4098
# Main app:   http://localhost:4097 (or 3000 in container mode)
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8080` |
| `APP_URL` | URL of the main application (IAP-protected) | `http://localhost:4097` |

## Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Landing page HTML |
| `GET /health` | Health check |
| `GET /config` | Returns `{ appUrl: "..." }` for the frontend |

## Deployment

The login page is deployed to Cloud Run as a public service (no authentication required).
The "Sign in with Google" button links to the IAP-protected main app, which triggers
Google's OAuth flow automatically.

See `cloudbuild.yaml` for deployment configuration.
