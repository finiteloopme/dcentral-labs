# Cloud Workstation Authentication Status

## Important: Authentication Architecture

### Cloud Workstations (Production)
- **Authentication**: Automatic via Workstation Service Account
- **User Action Required**: NONE
- **How it works**:
  - Cloud Workstations automatically provides credentials via metadata service
  - The workstation inherits permissions from its Service Account
  - No `gcloud auth login` needed
  - No credential mounting needed
  - OpenCode automatically uses the SA credentials for Vertex AI

### Local Development
- **Authentication**: Manual via developer's gcloud credentials
- **User Action Required**: 
  1. Run `gcloud auth application-default login` on host machine
  2. Then run `make run-local`
- **How it works**:
  - Mounts developer's local gcloud credentials into container
  - Copies credentials to writable location for gcloud operations
  - OpenCode uses these mounted credentials for Vertex AI

## Key Differences

| Aspect | Cloud Workstation | Local Development |
|--------|------------------|-------------------|
| Auth Method | Service Account (automatic) | User credentials (manual) |
| Setup Required | None | `gcloud auth login` on host |
| Credential Source | GCP metadata service | Mounted from `~/.config/gcloud` |
| User Prompts | Never | Only on host, before container |
| Vertex AI Access | Via SA permissions | Via user's project permissions |

## Implementation Notes

### Cloud Workstation Entrypoint
The production container should:
1. **NOT** prompt for authentication
2. **NOT** mount any credentials
3. **NOT** copy gcloud configs
4. Rely entirely on the metadata service
5. Use the default credentials chain (which automatically finds SA credentials)

### Local Development Entrypoint (`entrypoint-local.sh`)
The local container:
1. Mounts credentials from host to `/tmp/gcloud-config`
2. Copies them to `/home/ubuntu/.config/gcloud`
3. Sets proper ownership for the ubuntu user
4. Allows gcloud write operations (logs, cache, etc.)

## Testing Authentication

### In Cloud Workstation
```bash
# This should work automatically without any auth setup
gcloud config list
gcloud auth list  # Should show the Service Account

# OpenCode should work immediately
opencode  # Uses SA for Vertex AI
```

### In Local Development
```bash
# First on host machine:
gcloud auth application-default login

# Then in container:
make run-local
gcloud auth list  # Should show your user account
opencode  # Uses your credentials for Vertex AI
```

## Security Considerations

1. **Cloud Workstations**: 
   - SA permissions should be carefully scoped
   - Users inherit SA permissions, cannot escalate
   - No credential exposure risk

2. **Local Development**:
   - Credentials mounted read-only from host
   - Copied to container with user ownership
   - Container isolated from host system

## Current Status

✅ Local development authentication working with credential mounting
✅ Cloud workstation design maintains automatic SA authentication
✅ No authentication prompts in cloud workstations
✅ Clear separation between local and cloud auth flows