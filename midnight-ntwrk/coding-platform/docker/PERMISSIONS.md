# Permissions and Security Model

This document explains how the Midnight Development Platform Docker image handles permissions to comply with Google Cloud Workstations requirements.

## Key Principles

1. **Non-Root Runtime**: The container runs as UID 1000 (non-root user) by default
2. **No Elevated Privileges Required**: All application functionality works without root permissions
3. **Cloud Workstations Compatible**: Fully compliant with Google Cloud Workstations security requirements

## Build vs Runtime Permissions

### Build Time (Root Required)
- System packages installation (apt-get)
- Global npm packages installation
- System directory creation (/opt/midnight, /opt/templates)
- File permission setup

### Runtime (Non-Root, UID 1000)
- All Midnight tools execution
- OpenCode AI assistant
- Proof server operation
- Code editing and compilation

## Directory Permissions

| Directory | Owner | Permissions | Purpose |
|-----------|-------|-------------|---------|
| `/opt/midnight` | root | 755 | Midnight tools (readable/executable by all) |
| `/opt/templates` | root | 755 | Project templates (readable by all) |
| `/opt/code-oss` | root | 755 | Code OSS installation |
| `/home/user` | 1000 | 755 | User workspace |
| `/tmp` | all | 777 | Temporary files and logs |

## Port Bindings

| Service | Cloud Workstations | Local Development | Notes |
|---------|-------------------|-------------------|-------|
| Code OSS | 80 | 8080 | Cloud uses CAP_NET_BIND_SERVICE for port 80 |
| SSH | 22 | - | Cloud Workstations only |
| Proof Server | 8081 | 8081 | Non-privileged port |

## Startup Scripts

All startup scripts in `/etc/workstation-startup.d/` include permission checks:

```bash
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  # Running as root, switch to user
  exec runuser user "${BASH_SOURCE[0]}"
fi
```

This ensures:
- Scripts work in Cloud Workstations (starts as root, switches to user)
- Scripts work in local development (runs as non-root)
- No elevated permissions are required for functionality

## Security Features

### What Works Without Root
✅ All Midnight CLI tools (midnight, compactc, prove, verify)
✅ OpenCode AI assistant
✅ Proof server on non-privileged port
✅ File editing and project creation
✅ npm package installations (local to user)
✅ Writing to /tmp for logs and temporary files

### What Requires Root (Build Time Only)
⚠️ Installing system packages
⚠️ Global npm installations
⚠️ Creating system directories
⚠️ Binding to privileged ports (<1024)

## Cloud Workstations Integration

Google Cloud Workstations handles:
- Initial container startup as root
- User creation and switching
- CAP_NET_BIND_SERVICE capability for port 80
- SSH server management
- Container lifecycle

Our image provides:
- Non-root runtime operation
- All tools accessible to UID 1000
- Startup scripts that handle permission switching
- No requirement for sudo or elevated privileges

## Testing Permissions

### Test Non-Root Operation
```bash
# Run container as non-root user
podman run --rm --user 1000 midnight-workstation:latest bash -c 'id && which opencode'
```

### Test Tool Access
```bash
# Verify tools work without root
podman run --rm --entrypoint="" midnight-workstation:latest bash -c '
  echo "User: $(id -u)"
  opencode --version
  midnight --help
  compactc --version
'
```

### Test Cloud Workstations Mode
```bash
# Simulate Cloud Workstations startup (requires root initially)
podman run --rm --user root midnight-workstation:latest
```

## Troubleshooting

### Permission Denied Errors
- Ensure container is built with correct USER directive
- Check file ownership in /opt directories
- Verify startup scripts have execute permissions

### Port Binding Issues
- Use non-privileged ports (>1024) for local development
- Cloud Workstations provides CAP_NET_BIND_SERVICE for port 80
- Proof server uses 8081 to avoid conflicts

### File Access Issues
- All tools in /opt/midnight should be world-readable (755)
- User workspace should be owned by UID 1000
- Use /tmp for runtime file creation

## Compliance

This image complies with:
- ✅ Google Cloud Workstations security requirements
- ✅ Docker best practices (non-root runtime)
- ✅ Principle of least privilege
- ✅ No sudo or setuid binaries required