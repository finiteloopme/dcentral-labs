# Local Environment Changes for Cloud Workstation Container

This document lists all the specific changes and configurations applied when running the Cloud Workstation container in a local development environment.

## Overview

The same container image (`midnight-workstation:latest`) works in both environments, but local development requires additional configuration to handle differences in:
- User management and permissions
- Service initialization
- Authentication mechanisms
- Terminal configuration

## 1. Custom Entrypoint (`docker/entrypoint-local.sh`)

**Purpose**: Replace the Cloud Workstation initialization with local-specific setup

### Key Changes:
- **Bypasses Cloud Workstation initialization** that expects GCP environment
- **Creates non-root user** (`ubuntu` with UID 1000) for terminal work
- **Starts services as root** (Code OSS on port 80, proof server on port 8081)
- **Switches to non-root user** for the interactive terminal session
- **Sets up environment variables**:
  - `HOME=/home/ubuntu`
  - `USER_HOME=/home/ubuntu`
  - `TERM=xterm-256color`
  - `GCP_PROJECT_ID` (if provided)

### User Management:
```bash
# Services run as root (needed for port 80)
# Terminal runs as ubuntu (UID 1000)
# sudo available with NOPASSWD for development
```

## 2. Terminal Wrapper (`docker/terminal-wrapper.sh`)

**Purpose**: Ensure Code OSS terminals run as non-root user

### Key Changes:
- **Intercepts Code OSS terminal creation**
- **Forces terminals to run as `ubuntu` user** instead of root
- **Creates necessary directories** for OpenCode
- **Sets proper ownership** for user directories

## 3. Docker Run Script (`docker/run-local.sh`)

**Purpose**: Launch container with local-specific configurations

### Key Changes:
- **Uses `--privileged` flag** (following Google's testing guidelines)
- **Port mappings**:
  - `-p 8080:80` (Code OSS IDE)
  - `-p 8081:8081` (Proof Server)
- **Volume mounts**:
  - `entrypoint-local.sh` mounted to `/entrypoint-local.sh`
  - `terminal-wrapper.sh` mounted to `/terminal-wrapper.sh`
  - `~/.config/gcloud` mounted to `/tmp/gcloud-config` (for Vertex AI auth)
- **Environment variables**:
  - `GCP_PROJECT_ID` (auto-detected or manually set)
- **Custom entrypoint**: Uses `/entrypoint-local.sh` instead of default

## 4. Authentication Differences

### Cloud Workstation:
- Uses Service Account automatically
- No user intervention needed
- Credentials from metadata service

### Local Development:
- **Mounts gcloud credentials** from host machine
- **Copies credentials** to container user's home
- **Requires manual authentication** on host:
  ```bash
  gcloud auth application-default login
  gcloud config set project YOUR-PROJECT-ID
  ```

## 5. Directory Structure

### Created for Local:
```
/home/ubuntu/
├── .bashrc                    # Custom bash configuration
├── .config/
│   ├── gcloud/                # Copied from host
│   └── opencode/              # OpenCode configuration
└── .local/
    └── share/
        └── opencode/
            └── log/           # OpenCode logs
```

## 6. Service Management

### Cloud Workstation:
- Services managed by Cloud Workstation platform
- Automatic startup via systemd

### Local Development:
- **Manual service startup** in entrypoint:
  ```bash
  # Start Code OSS
  /opt/code-oss/bin/code-oss-server --port 80 &
  
  # Start Proof Server
  cd /opt/midnight/proof-server && npm start &
  ```

## 7. Network Configuration

### Cloud Workstation:
- Direct access via Cloud Workstation proxy
- No port mapping needed

### Local Development:
- **Port mappings required**:
  - Code OSS: `127.0.0.1:8080` → container port 80
  - Proof Server: `127.0.0.1:8081` → container port 8081
- **Note**: Must use `127.0.0.1` instead of `localhost` for Code OSS

## 8. Profile Scripts Disabled

### Disabled in Local:
```bash
# These scripts cause issues in local environment
/etc/profile.d/*gcloud*
/etc/profile.d/*gce*
```
These are renamed to `.disabled` to prevent execution

## 9. OpenCode Configuration

### Cloud Workstation:
- Uses Service Account for Vertex AI
- Auto-detects project from metadata

### Local Development:
- **Custom OpenCode wrapper function** in bashrc:
  ```bash
  opencode() {
      # Check for application default credentials
      # Set GCP_PROJECT_ID
      # Launch with proper environment
  }
  ```

## 10. Terminal Prompt

### Cloud Workstation:
```
user@workstation-name:~$
```

### Local Development:
```
ubuntu@midnight:~$
```

## Summary of Key Commands

### Building:
```bash
make build  # Same for both environments
```

### Running:
```bash
# Cloud Workstation (automatic)
# Deployed via Terraform/GCP Console

# Local Development
make run-local
# or with explicit project:
GCP_PROJECT_ID=my-project make run-local
```

### Key Differences Table:

| Aspect | Cloud Workstation | Local Development |
|--------|------------------|-------------------|
| Entrypoint | Default Cloud Workstation | `/entrypoint-local.sh` |
| User | `user` (managed by platform) | `ubuntu` (UID 1000) |
| Auth | Service Account (automatic) | Mounted gcloud credentials |
| Services | Managed by platform | Started in entrypoint |
| Port Access | Direct via proxy | Mapped (8080:80, 8081:8081) |
| Privileged | No | Yes (for testing) |
| Terminal | Automatic setup | Custom wrapper script |
| /dev/null | Provided by platform | Created if missing |

## Files Specific to Local Development

1. `docker/entrypoint-local.sh` - Main entry point
2. `docker/terminal-wrapper.sh` - Terminal user switching
3. `docker/run-local.sh` - Launch script
4. `LOCAL_DEVELOPMENT.md` - Usage documentation
5. `OPENCODE_USAGE.md` - OpenCode setup guide

These files are **not used** in Cloud Workstation deployments and don't affect the production environment.