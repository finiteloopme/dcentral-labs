# Midnight Development Platform - Google Cloud Workstation

This Docker image provides a complete development environment for Midnight blockchain applications, customized for Google Cloud Workstations according to the [official customization guide](https://cloud.google.com/workstations/docs/customize-container-images).

## Features

### Base Image
- **Code OSS for Cloud Workstations**: Leverages the official `us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest` base image
- **Web-based IDE**: Code OSS accessible on port 80
- **SSH Support**: Built-in SSH server on port 22

### Midnight-Specific Tools

1. **Midnight Compact Compiler**
   - Command: `compactc`
   - Compiles `.compact` smart contracts
   - Generates JSON artifacts with ABI and bytecode

2. **Midnight Proof Server**
   - Runs on port 8080 (Cloud Workstations) or 8081 (local development)
   - Provides zero-knowledge proof generation APIs
   - Automatically starts on container startup

3. **Project Templates**
   - Basic token contract template
   - Pre-configured project structure
   - Command: `midnight new <project-name>`

4. **Midnight Compact VSCode Extension**
   - Version: 0.2.13
   - Syntax highlighting for `.compact` files
   - IntelliSense and code completion
   - Auto-installed on startup
   - Source: https://raw.githubusercontent.com/midnight-ntwrk/releases/gh-pages/artifacts/vscode-extension/compact-0.2.13/compact-0.2.13.vsix

5. **OpenCode AI Assistant**
   - Terminal-based AI coding assistant
   - Version: 0.15.8
   - Command: `opencode`
   - Requires ANTHROPIC_API_KEY environment variable
   - See [OPENCODE_SETUP.md](OPENCODE_SETUP.md) for detailed setup instructions

## Building the Image

### Prerequisites
- Docker installed locally
- Access to Google Artifact Registry (for pushing)
- Google Cloud SDK (optional, for registry authentication)

### Build Script

Use the provided build script for easy building:

```bash
# From docker directory
cd docker
./build.sh

# Build with custom name and tag
./build.sh --name my-midnight-workstation --tag v1.0.0

# Build and push to Artifact Registry
./build.sh \
  --registry us-central1-docker.pkg.dev/PROJECT_ID/REPOSITORY \
  --name midnight-workstation \
  --tag latest \
  --push
```

### Manual Build

The Dockerfile is self-contained and builds from the docker directory:

```bash
# From docker directory
cd docker
docker build -t midnight-workstation:latest .

# Quick test build
./test-build.sh
```

**Note:** The build context is the `docker/` directory itself. All necessary components (proof server, templates, scripts) are either copied from this directory or created inline during the build process.

## Testing Locally

### Quick Start (Recommended)

Use the simplified local startup that bypasses Cloud Workstations initialization:

```bash
# From project root
make run-local-simple

# Or directly from docker directory
cd docker
./run-local-simple.sh

# Or using docker-compose
docker-compose -f docker-compose.local.yml up
```

Access services:
- Code OSS IDE: http://localhost:8080
- Proof Server: http://localhost:8081

### Manual Run

```bash
# Run with simplified startup
docker run -it --rm \
  --name midnight-local \
  --entrypoint /usr/local/bin/start-local \
  -p 8080:8080 \
  -p 8081:8081 \
  midnight-workstation:latest
```

### Verify Installation

```bash
# Connect to container
docker exec -it midnight-dev bash

# Check Midnight tools
midnight help
compactc --version

# Check proof server
curl http://localhost:8080/health

# List installed VS Code extensions
/opt/code-oss/bin/codeoss-cloudworkstations --list-extensions
```

## Deploying to Google Cloud Workstations

### 1. Push to Artifact Registry

```bash
# Configure Docker for Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tag and push image
docker tag midnight-workstation:latest \
  us-central1-docker.pkg.dev/PROJECT_ID/REPOSITORY/midnight-workstation:latest

docker push \
  us-central1-docker.pkg.dev/PROJECT_ID/REPOSITORY/midnight-workstation:latest
```

### 2. Create Workstation Configuration

Use the custom image in your workstation configuration:

```bash
gcloud workstations configs create midnight-config \
  --cluster=CLUSTER_NAME \
  --region=us-central1 \
  --machine-type=e2-standard-4 \
  --container-custom-image=us-central1-docker.pkg.dev/PROJECT_ID/REPOSITORY/midnight-workstation:latest \
  --service-account=workstation-sa@PROJECT_ID.iam.gserviceaccount.com
```

### 3. Create Workstation

```bash
gcloud workstations create midnight-dev \
  --cluster=CLUSTER_NAME \
  --config=midnight-config \
  --region=us-central1
```

## Container Structure

### Implementation Pattern

This image follows Google's recommended patterns from [cloud-workstations-custom-image-examples](https://github.com/GoogleCloudPlatform/cloud-workstations-custom-image-examples):

- Extends the official `code-oss` base image without modifying its core functionality
- Installs the Midnight Compact extension as a `@builtin` extension
- Uses the `assets/` directory structure for startup scripts
- Scripts follow the self-executing pattern with `runuser` for user context

### Startup Scripts

The image includes startup scripts in `/etc/workstation-startup.d/`:

- `100_configure-midnight-settings.sh` - Configures Code OSS settings for Midnight development
- `200_start-proof-server.sh` - Starts the proof server on port 8080
- `210_initialize-workspace.sh` - Sets up workspace and templates

### Directory Layout

```
/opt/midnight/
├── bin/              # Midnight CLI tools
├── extensions/       # VSCode extensions
├── proof-server/     # Proof service
└── config/          # Configuration files

/opt/templates/       # Project templates
└── basic-token/     # Token contract template

/home/user/          # User home (persistent)
└── workspace/       # Working directory
    ├── projects/    # User projects
    └── templates/   # Copied templates
```

### Environment Variables

```bash
MIDNIGHT_HOME=/opt/midnight
PATH=/opt/midnight/bin:$PATH
PROOF_SERVICE_PORT=8080
```

## Customization

### Adding More Tools

Create additional startup scripts:

```dockerfile
# In your Dockerfile
RUN echo '#!/bin/bash' > /etc/workstation-startup.d/230_custom_setup.sh && \
    echo 'echo "Running custom setup..."' >> /etc/workstation-startup.d/230_custom_setup.sh && \
    chmod +x /etc/workstation-startup.d/230_custom_setup.sh
```

### Modifying IDE Settings

Configure default Code OSS settings:

```dockerfile
RUN echo '#!/bin/bash' > /etc/workstation-startup.d/240_ide_settings.sh && \
    echo 'runuser user -c "mkdir -p $HOME/.codeoss-cloudworkstations/data/Machine"' >> /etc/workstation-startup.d/240_ide_settings.sh && \
    echo 'runuser user -c "echo {\"workbench.colorTheme\":\"Default Dark Modern\"} > $HOME/.codeoss-cloudworkstations/data/Machine/settings.json"' >> /etc/workstation-startup.d/240_ide_settings.sh && \
    chmod +x /etc/workstation-startup.d/240_ide_settings.sh
```

## Troubleshooting

### Code OSS Not Accessible (Port 80 Error)

If you see "Unable to forward your request to a backend" or "Couldn't connect to a server on port 80":

1. **Check if Code OSS is running:**
```bash
gcloud workstations ssh WORKSTATION_NAME --command "pgrep -f codeoss-cloudworkstations"
```

2. **Check port 80 status:**
```bash
gcloud workstations ssh WORKSTATION_NAME --command "netstat -tuln | grep :80"
```

3. **View Code OSS logs:**
```bash
gcloud workstations ssh WORKSTATION_NAME --command "cat /home/user/.codeoss-cloudworkstations/logs/server.log"
```

4. **Manually start Code OSS:**
```bash
gcloud workstations ssh WORKSTATION_NAME --command "sudo /etc/workstation-startup.d/110_start-code-oss.sh"
```

5. **Restart the workstation:**
```bash
gcloud workstations stop WORKSTATION_NAME
gcloud workstations start WORKSTATION_NAME
```

### Extension Not Installing

Check logs:
```bash
docker exec midnight-dev cat /var/log/customize_environment
```

Manually install:
```bash
docker exec -it midnight-dev bash
/opt/midnight/bin/install-midnight-extension
```

### Proof Server Issues

Check server logs:
```bash
docker exec midnight-dev cat /tmp/midnight-logs/proof-server.log
```

Restart server:
```bash
docker exec midnight-dev /opt/midnight/bin/start-proof-server
```

### Permission Issues

The base image runs as user `1000`. Ensure files are accessible:
```bash
docker exec midnight-dev ls -la /opt/midnight
```

## Security Considerations

### Non-Root Operation
- **The container runs as `USER 1000` (non-root) by default** - this is required by Cloud Workstations
- All Midnight tools are installed with appropriate permissions for non-root access
- User-level operations are handled through the `customize_environment` mechanism
- Startup scripts run as root but execute user operations via `runuser user -c`

### Additional Security
- Sudo access can be disabled by setting `CLOUD_WORKSTATIONS_CONFIG_DISABLE_SUDO=true`
- Use service accounts with minimal permissions for Artifact Registry access
- Regular rebuilds recommended to incorporate base image security updates
- All user data is stored in the persistent home directory, not in the container image

## Support

For issues or questions:
- Midnight Network Documentation: [docs.midnight.network](https://docs.midnight.network)
- Cloud Workstations Documentation: [cloud.google.com/workstations](https://cloud.google.com/workstations)
- GitHub Issues: [github.com/midnight-ntwrk](https://github.com/midnight-ntwrk)