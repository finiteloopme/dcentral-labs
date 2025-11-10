# OpenCode TUI Access

## 🎯 **Option 1: OpenCode TUI Port (Added)**

The platform now exposes port **3000** for OpenCode TUI access:

```bash
# After running 'make run', access OpenCode TUI at:
http://localhost:3000
```

## 🌐 **Option 2: Google Cloud Workstation Built-in IDE**

For production deployment on Google Cloud Workstations:

1. **Access**: Go to your Workstation URL
2. **Login**: Use your Google account  
3. **VS Code**: Full IDE experience in browser
4. **Terminal**: Built-in terminal for `make` commands

## 🔄 **Development Workflow**

### Local Development (with OpenCode TUI)
```bash
make run
# Access OpenCode TUI: http://localhost:3000
# Access services: http://localhost:PORTS
```

### Google Cloud Workstation (Production)
```bash
# Deploy to GCR
make build && podman push gcr.io/your-project/midnight-vibe-platform

# Configure in GCP Console
# - Container: gcr.io/your-project/midnight-vibe-platform
# - Machine type: e2-standard-4+
# - No port mapping needed (uses GCP networking)
```

## 📊 **Service Access Comparison**

| Environment | OpenCode TUI | Services | IDE |
|-------------|---------------|---------|-----|
| **Local** | http://localhost:3000 | localhost:PORTS | External |
| **GCP Workstation** | Not needed | workstation-ip:PORTS | Built-in VS Code |

## 🚀 **Recommendations**

**For Local Development**: Use OpenCode TUI + service URLs
**For Production**: Use Google Cloud Workstation's built-in VS Code

The OpenCode TUI provides a lightweight, terminal-based development experience!