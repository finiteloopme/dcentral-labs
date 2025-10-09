# Using Podman with BitVM3

This project supports both Docker and Podman. Podman is a daemonless, rootless container engine that's fully compatible with Docker but more secure.

## 🚀 Quick Start with Podman

### 1. Install Podman

Run our setup script:
```bash
make setup-podman
```

Or install manually:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y podman podman-compose
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install -y podman podman-compose
```

**macOS:**
```bash
brew install podman podman-compose
podman machine init
podman machine start
```

**Arch Linux:**
```bash
sudo pacman -S podman podman-compose
```

### 2. Install podman-compose

If not included with Podman:
```bash
pip3 install --user podman-compose
```

## 📋 Configuration

The project automatically detects whether you have Podman or Docker installed and uses the appropriate tool.

### Key Differences from Docker

1. **Rootless by default** - More secure, no daemon required
2. **SELinux support** - Volumes use `:Z` flag for proper labeling
3. **User namespace mapping** - Uses `userns_mode: keep-id` for file permissions
4. **Systemd integration** - Better process management on Linux

## 🛠️ Usage

All Makefile commands work with both Podman and Docker:

```bash
# Start services (uses podman-compose if available)
make docker-up

# Stop services
make docker-down

# View logs
make docker-logs

# Check status
make docker-ps
```

## 🔄 Docker Compatibility

Podman provides Docker-compatible commands:

```bash
# Instead of docker
podman run -it alpine sh

# Instead of docker-compose
podman-compose up -d

# List containers
podman ps

# Build images
podman build -t myimage .
```

## 📝 Podman-Specific Features

### Pods
Create a pod (group of containers):
```bash
podman pod create --name bitvm3-pod -p 3000:3000 -p 3001:3001
podman run -d --pod bitvm3-pod bitvm3-backend
podman run -d --pod bitvm3-pod bitvm3-frontend
```

### Generate Systemd Services
```bash
# Generate systemd service files
podman generate systemd --new --name bitvm3-backend > ~/.config/systemd/user/bitvm3-backend.service

# Enable and start service
systemctl --user enable bitvm3-backend.service
systemctl --user start bitvm3-backend.service
```

### Rootless Networking
```bash
# Check port availability for rootless containers
podman unshare --rootless-netns ss -tulpn
```

## 🔐 Security Benefits

1. **No Daemon** - No persistent privileged process
2. **Rootless** - Containers run as your user, not root
3. **User Namespaces** - Better isolation between containers and host
4. **SELinux Integration** - Mandatory access controls on Linux
5. **Seccomp Profiles** - System call filtering

## 🐛 Troubleshooting

### Permission Issues
If you encounter permission errors:
```bash
# Reset ownership
podman unshare chown -R 0:0 /path/to/volume

# Or use --userns=keep-id
podman run --userns=keep-id -v ./data:/data:Z myimage
```

### Networking Issues
For rootless networking:
```bash
# Check if slirp4netns is installed
sudo apt-get install slirp4netns

# Use host networking if needed
podman run --network host myimage
```

### macOS Issues
On macOS, ensure the Podman machine is running:
```bash
podman machine start
podman machine ssh  # To access the VM
```

### Volume Mount Issues
Use the `:Z` flag for SELinux systems:
```bash
podman run -v ./data:/data:Z myimage
```

## 📊 Performance Comparison

| Feature | Docker | Podman |
|---------|--------|--------|
| Startup Time | ~2s | ~1s |
| Memory Usage | Higher (daemon) | Lower (no daemon) |
| Security | Root daemon | Rootless |
| Compatibility | 100% Docker | 99% Docker compatible |
| systemd Integration | Limited | Native |

## 🔗 Resources

- [Podman Documentation](https://docs.podman.io/)
- [Migrating from Docker](https://podman.io/getting-started/migrating-from-docker)
- [Podman Compose](https://github.com/containers/podman-compose)
- [Rootless Containers](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)

## 💡 Tips

1. **Alias Docker to Podman:**
   ```bash
   echo "alias docker=podman" >> ~/.bashrc
   echo "alias docker-compose=podman-compose" >> ~/.bashrc
   source ~/.bashrc
   ```

2. **Use Podman Desktop** for GUI management:
   ```bash
   # Download from https://podman-desktop.io/
   ```

3. **Check Podman info:**
   ```bash
   podman info
   podman version
   ```

4. **Clean up:**
   ```bash
   podman system prune -a  # Remove all unused data
   podman volume prune     # Remove unused volumes
   ```