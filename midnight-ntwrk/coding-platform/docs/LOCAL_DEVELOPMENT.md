# Local Development Guide

## Running Locally

```bash
make run-local
```

This command:
1. Starts services (Code OSS and Proof Server) as root (needed for port 80)
2. **Automatically switches to non-root user** (`ubuntu` with UID 1000) for your terminal
3. Provides a clean development environment

## Terminal Users

### Main Container Terminal
When you run `make run-local`, the main terminal runs as `ubuntu` (non-root):

```
ubuntu@midnight:/home/ubuntu$ whoami
ubuntu

ubuntu@midnight:/home/ubuntu$ id
uid=1000(ubuntu) gid=1000(ubuntu)
```

### Code OSS IDE Terminals
Terminals opened within Code OSS (Terminal → New Terminal) also run as non-root:

```
Terminal running as: ubuntu (UID: 1000)
Services: Code OSS at http://127.0.0.1:8080 | Proof Server at http://127.0.0.1:8081

ubuntu@localhost:~$ whoami
ubuntu
```

**Both the main terminal and Code OSS terminals run as non-root user** for security.

## Accessing Services

Services are available at:
- **Code OSS**: http://127.0.0.1:8080 (⚠️ Use 127.0.0.1, NOT localhost)
- **Proof Server**: http://127.0.0.1:8081

## Important Notes

### ✅ Correct Way to Access Terminal
```bash
# This gives you the non-root terminal:
make run-local

# You'll be working as 'ubuntu' user
ubuntu@midnight:~$ 
```

### ❌ Wrong Way (Will Give Root)
```bash
# Don't use exec - it bypasses the user switching:
docker exec -it midnight-local /bin/bash  # This gives root!
podman exec -it midnight-local /bin/bash  # This gives root!
```

### If You Need Another Terminal
If you need another terminal session in the same container:
```bash
# Connect as the ubuntu user:
podman exec -it midnight-local su - ubuntu
```

## Available Tools

In your non-root terminal, you have access to:
- `opencode` - AI coding assistant (uses Vertex AI with your gcloud credentials)
- `midnight` - Midnight CLI tool
- `compactc` - Compact language compiler
- `prove` - Proof generation tool
- `verify` - Proof verification tool

## Using OpenCode TUI

### Prerequisites
Before starting the container, authenticate with Google Cloud on your host machine:
```bash
# On your host machine (not in container)
gcloud auth application-default login

# Ensure your project is set
gcloud config set project YOUR-PROJECT-ID
```

### Starting the Container
The container will automatically detect your GCP project from gcloud config:
```bash
make run-local
```

Or explicitly set the project:
```bash
GCP_PROJECT_ID=your-project-id make run-local
```

### Launch OpenCode
```bash
# In the container, OpenCode is pre-configured for Vertex AI
opencode
```

OpenCode will use Claude 3.5 Sonnet via Vertex AI with your mounted gcloud credentials and project.

## Stopping the Container

Press `Ctrl+C` in the terminal where you ran `make run-local`.

## Security

- **Services**: Run as root (required for port 80)
- **Your Terminal**: Runs as `ubuntu` (UID 1000, non-root)
- **Development**: You work as a regular user, can use `sudo` if needed

This setup follows the principle of least privilege - services have the permissions they need, but you work as a regular user.