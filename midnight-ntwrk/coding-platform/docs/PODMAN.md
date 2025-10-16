# Using Podman with Midnight Development Platform

This project fully supports Podman as a Docker-compatible container runtime. Podman offers several advantages including rootless operation and daemonless architecture.

## Installation

### Linux (Fedora/RHEL/CentOS)
```bash
sudo dnf install podman
```

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install podman
```

### macOS
```bash
brew install podman
podman machine init
podman machine start
```

## Configuration

### 1. Enable Rootless Mode (Recommended)
```bash
# Check if running rootless
podman info | grep rootless

# Enable lingering for rootless containers
loginctl enable-linger $USER
```

### 2. Configure Registry Access
```bash
# Add Google Container Registry to registries
echo -e "[registries.search]\nregistries = ['docker.io', 'gcr.io', 'us-central1-docker.pkg.dev']" | \
  sudo tee -a /etc/containers/registries.conf
```

### 3. Set up GCP Authentication
```bash
# Login to GCR with Podman
gcloud auth print-access-token | \
  podman login -u oauth2accesstoken --password-stdin gcr.io

# Login to Artifact Registry
REGION=us-central1
gcloud auth print-access-token | \
  podman login -u oauth2accesstoken --password-stdin $REGION-docker.pkg.dev
```

## Usage

All Makefile commands work seamlessly with Podman:

```bash
# Build image
make build

# Push to registry
make push

# Run tests
make test
```

### Podman-Specific Commands

Additional Podman-optimized commands are available:

```bash
# Show Podman system information
make -f Makefile.podman podman-info

# Build with Podman-specific options
make -f Makefile.podman podman-build

# Push with Podman credentials helper
make -f Makefile.podman podman-push

# Run container locally for testing
make -f Makefile.podman podman-run

# Clean Podman cache
make -f Makefile.podman podman-clean
```

## Differences from Docker

### 1. Rootless by Default
Podman runs without root privileges, enhancing security:
```bash
# Check if running as root
podman info | grep -i root
```

### 2. No Daemon
Podman doesn't require a background daemon:
```bash
# Containers run directly as child processes
podman ps
```

### 3. Pod Support
Podman can manage pods (groups of containers):
```bash
# Create a pod for the development environment
podman pod create --name midnight-dev -p 3000:3000 -p 8080:8080
```

### 4. Systemd Integration
Generate systemd services for containers:
```bash
# Generate systemd service
podman generate systemd --name midnight-workstation > \
  ~/.config/systemd/user/midnight-workstation.service

# Enable service
systemctl --user enable midnight-workstation.service
```

## Troubleshooting

### Issue: Permission Denied
```bash
# For SELinux systems, add :Z flag for volumes
podman run -v /path/to/local:/path/in/container:Z image
```

### Issue: Cannot Push to Registry
```bash
# Re-authenticate with GCP
gcloud auth application-default login
gcloud auth configure-docker
```

### Issue: Rootless Networking
```bash
# Check slirp4netns is installed
sudo dnf install slirp4netns  # or apt-get
```

### Issue: Storage Space
```bash
# Clean up unused images and containers
podman system prune -a

# Check storage usage
podman system df
```

## Performance Optimization

### 1. Use Overlay Storage Driver
```bash
# Check current storage driver
podman info | grep -i storage

# Configure overlay in ~/.config/containers/storage.conf
[storage]
driver = "overlay"
```

### 2. Increase UIDs for Rootless
```bash
# Increase subordinate UIDs/GIDs
sudo usermod --add-subuids 100000-165535 $USER
sudo usermod --add-subgids 100000-165535 $USER
```

### 3. CPU and Memory Limits
```bash
# Run with resource limits
podman run --cpus="2" --memory="4g" midnight-workstation
```

## Migration from Docker

### Docker Compose to Podman
```bash
# Install podman-compose
pip3 install podman-compose

# Use existing docker-compose.yml
podman-compose up
```

### Import Docker Images
```bash
# Export from Docker
docker save midnight-workstation > image.tar

# Import to Podman
podman load < image.tar
```

## Security Benefits

1. **No Root Daemon**: Eliminates attack surface of privileged daemon
2. **User Namespaces**: Better isolation between containers
3. **SELinux Integration**: Mandatory access controls
4. **Audit Logging**: Full audit trail of container operations

## Best Practices

1. **Always Run Rootless**: Unless absolutely necessary
2. **Use Fully Qualified Image Names**: `registry.io/namespace/image:tag`
3. **Sign Images**: Use `podman image sign` for production
4. **Regular Updates**: Keep Podman and dependencies updated
5. **Resource Limits**: Always set CPU/memory limits

## Additional Resources

- [Podman Documentation](https://docs.podman.io/)
- [Podman vs Docker](https://podman.io/whatis.html)
- [Rootless Containers](https://rootlesscontaine.rs/)
- [Podman Troubleshooting](https://github.com/containers/podman/blob/main/troubleshooting.md)