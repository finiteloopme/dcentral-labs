# Local Development Guide

This guide explains how to build and run the Web3 Workstation container on your local machine for development and testing.

## 🚀 Quick Start

### Option 1: Using Makefile (Easiest)

```bash
# Build and run with one command
make local-dev

# This will:
# 1. Build the container image locally
# 2. Create a persistent workspace at ~/web3-workspace
# 3. Start the container with port forwarding
# 4. Drop you into an interactive shell
```

### Option 2: Using the Local Development Script

```bash
# Build and run
./scripts/local-dev.sh

# Build only
./scripts/local-dev.sh --build-only

# Run only (if already built)
./scripts/local-dev.sh --run-only

# Run in background (detached)
./scripts/local-dev.sh --no-interactive
```

### Option 3: Manual Commands

```bash
# Build the image
cd docker
podman build -t web3-workstation:local .
# or
docker build -t web3-workstation:local .

# Run interactively
podman run -it --rm \
  -p 8080:8080 \
  -p 8000:80 \
  -v ~/web3-workspace:/home/user \
  --name web3-workstation-local \
  web3-workstation:local /bin/bash

# Run in background
podman run -d \
  -p 8080:8080 \
  -p 8000:80 \
  -v ~/web3-workspace:/home/user \
  --name web3-workstation-local \
  web3-workstation:local
```

## 📦 What Gets Built

The container includes:
- **Code-OSS IDE** with Remix IDE extension
- **Foundry** (forge, cast, anvil) for smart contract development
- **Node.js & npm** for JavaScript development
- **OpenCode TUI** accessible via web terminal
- **Git** and development tools
- **Podman** for nested container operations

## 🌐 Access Points

Once running, you can access:

| Service | URL | Description |
|---------|-----|-------------|
| **Code-OSS IDE** | http://localhost:8000 | Web-based VS Code editor |
| **OpenCode Terminal** | http://localhost:8080 | Web terminal with OpenCode TUI |

## 🗂️ Persistent Workspace

The container mounts a local directory for persistent storage:
- **Default location**: `~/web3-workspace`
- **Purpose**: Survives container restarts
- **Contents**:
  - `projects/` - Your development projects
  - `.config/` - Configuration files
  - `README.md` - Getting started guide

### Custom Workspace Location

```bash
# Use a different directory
./scripts/local-dev.sh --volume /path/to/my/workspace

# Or with Makefile
VOLUME_HOME=/path/to/my/workspace make local-dev
```

## 🔧 Configuration Options

### Resource Limits

```bash
# Allocate more resources
./scripts/local-dev.sh \
  --memory 8g \
  --cpus 4

# Or set via environment
MEMORY=8g CPUS=4 make local-dev
```

### Custom Ports

```bash
# Use different ports
./scripts/local-dev.sh \
  --ports "9090:8080,9000:80"

# Format: "host:container,host:container"
```

### Container Name

```bash
# Use custom container name
./scripts/local-dev.sh \
  --name my-web3-dev
```

## 📋 Common Workflows

### Start Development Session

```bash
# Start fresh
make local-dev

# Inside container, create a new project
forge init my-defi-project
cd my-defi-project
forge build
forge test

# Open another terminal for OpenCode
opencode
```

### Background Development

```bash
# Start in background
./scripts/local-dev.sh --no-interactive

# Access the IDE
open http://localhost:8000

# Access the terminal
open http://localhost:8080

# Enter the container shell when needed
podman exec -it web3-workstation-local /bin/bash
```

### Check Status

```bash
# Using Makefile
make local-status

# Using script
./scripts/local-dev.sh status

# Manual
podman ps | grep web3-workstation
```

### Stop Container

```bash
# Using Makefile
make local-stop

# Using script
./scripts/local-dev.sh stop

# Manual
podman stop web3-workstation-local
```

### Clean Up

```bash
# Remove container and image
make local-clean

# This will prompt to:
# 1. Remove the container
# 2. Remove the image
# 3. Optionally remove workspace directory
```

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Check what's using the ports
lsof -i :8080
lsof -i :8000

# Use different ports
./scripts/local-dev.sh --ports "9090:8080,9000:80"
```

### Permission Issues (Linux)

```bash
# For Podman (rootless)
./scripts/local-dev.sh  # Should work without sudo

# For Docker, add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Container Won't Start

```bash
# Check logs
podman logs web3-workstation-local

# Remove and recreate
podman rm -f web3-workstation-local
make local-dev
```

### Linux Specific

```bash
# Podman on Linux uses host network mode by default for better compatibility
make local
# Services available directly at localhost:8000 and localhost:8080
```

### macOS Specific

```bash
# If using Podman on macOS
podman machine init
podman machine start

# Then run normally
make local
```

## 🔄 Development Cycle

1. **Edit Code**: Make changes in your local editor or via Code-OSS
2. **Test in Container**: Run tests using Foundry tools
3. **Use OpenCode**: Access TUI for AI assistance
4. **Persist Work**: All changes saved to local workspace

## 💡 Tips

### Aliases for Convenience

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias web3-dev='make -C ~/path/to/project local-dev'
alias web3-stop='make -C ~/path/to/project local-stop'
alias web3-status='make -C ~/path/to/project local-status'
```

### VS Code Integration

Open your workspace in local VS Code:

```bash
code ~/web3-workspace
```

Then use the container for compilation and testing:

```bash
podman exec web3-workstation-local forge build
```

### Multiple Containers

Run multiple isolated environments:

```bash
# Development environment
./scripts/local-dev.sh --name web3-dev --ports "8080:8080,8000:80"

# Testing environment  
./scripts/local-dev.sh --name web3-test --ports "8081:8080,8001:80"

# Production-like environment
./scripts/local-dev.sh --name web3-prod --ports "8082:8080,8002:80"
```

## 🚢 Comparison with Cloud Workstation

| Feature | Local Container | Cloud Workstation |
|---------|----------------|-------------------|
| **Cost** | Free (local resources) | Pay per use |
| **Performance** | Depends on local machine | Consistent cloud resources |
| **Persistence** | Local directory | Cloud storage |
| **Accessibility** | Local only | Anywhere via browser |
| **Collaboration** | Limited | Easy sharing |
| **Setup Time** | Minutes | Minutes (after Terraform) |
| **Resource Limits** | Local hardware | Scalable |

## 📚 Next Steps

1. **Explore Foundry**: Run `forge --help` for smart contract tools
2. **Try OpenCode**: Access http://localhost:8080 and run `opencode`
3. **Install Extensions**: Use Code-OSS to add more VS Code extensions
4. **Create Projects**: Start building in `~/web3-workspace/projects/`

## 🤝 Contributing

To test changes to the container:

1. Modify `docker/Dockerfile`
2. Rebuild: `make build-local`
3. Test: `make local-dev`
4. Iterate quickly without pushing to registry

---

For production deployment, see the main [README.md](README.md).