# dCoder Login Page

Magic-link email sign-in UI for dCoder, hosted at `/login` and `/__/auth/*`
on the deployment FQDN (e.g. `dcoder.<base_domain>`).

## Overview

This service hosts:

- The dCoder branded landing page with an email input + "Send magic link" button
- The `/__/auth/handler` endpoint that completes Firebase email-link sign-in
  and redirects the user back to the IAP-protected app

It is deployed as a public Cloud Run service with `--ingress=internal-and-cloud-load-balancing`
so it is only reachable through the External HTTPS Load Balancer (which
routes `/login*` and `/__/auth/*` paths to it).

## Architecture

```
┌──────────────────────────┐       ┌─────────────────────────────┐
│   opencode-login         │       │      opencode-web           │
│   (public, no IAP)       │       │   (IAP via gcipSettings     │
│                          │       │    agent flow)              │
│   /login                 │       │                             │
│     ▲                    │       │   Main application          │
│     │ user enters email  │       │   Receives x-goog-iap-jwt-  │
│     ▼                    │       │   assertion + enforces      │
│   Firebase JS SDK        │       │   config.toml allow-list    │
│     ▲                    │       │                             │
│     │ magic link in      │       └────────────▲────────────────┘
│     │ email              │                    │
│     ▼                    │                    │
│   /__/auth/handler       │ signInWithEmailLink│
│     ▲                    │ → ID token         │
│     │ user clicks link   │ → IAP session      │
│     ▼                    │ ───────────────────┘
│   redirect to original   │
│   target URL             │
└──────────────────────────┘

  All paths share the same hostname (dcoder.<base_domain>) — no
  cross-domain bouncing. The LB URL map handles routing:

      /login*       → opencode-login-backend (no IAP)
      /__/auth/*    → opencode-login-backend (no IAP)
      /*  (default) → opencode-web-backend   (IAP enabled)
```

See `gcip-magiclink-setup.md` for the one-time bootstrap.

## Development

### Local Testing

```bash
# Install dependencies
cd packages/opencode-login
npm install

# Run locally
APP_URL=http://localhost:4097 \
  FIREBASE_API_KEY=<your-key> \
  FIREBASE_AUTH_DOMAIN=<project>.firebaseapp.com \
  FIREBASE_PROJECT_ID=<project> \
  npm start

# Visit http://localhost:8080/login
```

If the Firebase env vars are unset, the page renders but clicking "Send magic
link" will display a "Sign-in is not configured" error.

For fully offline testing, run the Firebase Auth emulator:

```bash
docker compose --profile emulator up firebase-auth-emulator
# then export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 before
# loading the page in your browser
```

### With Docker/Podman

```bash
# Build from project root
podman build -f packages/opencode-login/Containerfile -t opencode-login .

# Run
podman run -p 8080:8080 \
  -e APP_URL=http://localhost:4097 \
  -e FIREBASE_API_KEY=<your-key> \
  -e FIREBASE_AUTH_DOMAIN=<project>.firebaseapp.com \
  -e FIREBASE_PROJECT_ID=<project> \
  opencode-login
```

### With Docker Compose (optional profile)

```bash
# From project root - includes login page
docker compose --profile login up

# Login page: http://localhost:4098/login
# Main app:   http://localhost:4097 (or 8181 for adk-backend)
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8080` |
| `APP_URL` | URL of the main application (fallback for "return to app" links) | `http://localhost:4097` |
| `FIREBASE_API_KEY` | Public Firebase Web API key (browser-safe) | `""` |
| `FIREBASE_AUTH_DOMAIN` | Firebase auth domain, typically `<project>.firebaseapp.com` | `""` |
| `FIREBASE_PROJECT_ID` | GCP project ID hosting GCIP | `""` |

The Firebase values are PUBLIC config (browser-safe) — security comes from
authorized-domain whitelisting in the Firebase Console + Firebase Security
Rules, not from secrecy of the apiKey. See `gcip-magiclink-setup.md`
Phase 0 for how to retrieve them.

## Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Landing page HTML |
| `GET /login` | Magic-link sign-in page (alias for `/`) |
| `GET /__/auth/handler` | Email-link return handler (completes sign-in) |
| `GET /health` | Health check |
| `GET /config` | Returns `{ appUrl, firebase: { apiKey, authDomain, projectId } }` for the SPA |

## Deployment

The login page is deployed as a Cloud Run service with LB-only ingress
(`--ingress=internal-and-cloud-load-balancing`) so it can only be reached
through the External HTTPS Load Balancer. The LB URL map routes `/login*`
and `/__/auth/*` requests to this backend without IAP.

See `cloudbuild.yaml` and `gcip-magiclink-setup.md` for deployment details.
