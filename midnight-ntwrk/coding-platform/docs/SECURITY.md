# Security Considerations

## Container User Context

### Cloud Workstations vs Local Development

The container is designed to work in two different environments with different security requirements:

#### Cloud Workstations (Production)
- **Initial User**: Root (required by base image)
- **Runtime User**: Automatically switched to non-root by Cloud Workstations
- **Port**: 80 (managed by Cloud Workstations with proper capabilities)
- **Security**: Handled by Google Cloud platform

#### Local Development

```bash
make run-local
```
- **Mode**: Uses `--privileged` flag as per [Cloud Workstations documentation](https://cloud.google.com/workstations/docs/customize-container-images#test_your_custom_container_image)
- **Port**: 80 internally (mapped to host 8080)
- **User Management**: Handled by Cloud Workstations base image
- **Note**: This follows Google's official testing approach for Cloud Workstation images

## Best Practices

### For Local Development

1. **Use non-root mode when possible:**
   ```bash
   make run-local-secure
   ```

2. **If you must use root mode, limit exposure:**
   - Don't expose ports to public networks
   - Use only for local development
   - Don't run untrusted code

3. **API Keys and Secrets:**
   - Never commit API keys to the repository
   - Use Google Cloud IAM for authentication
   - OpenCode uses Vertex AI with gcloud credentials

### For Cloud Deployment

1. **Let Cloud Workstations handle security:**
   - Don't override the USER directive in production
   - Trust the platform's security model
   - Use IAM for access control

2. **Service Account Permissions:**
   - Use least-privilege principle
   - Grant only necessary roles
   - Regularly audit permissions

## Container Security Features

### Built-in Protections

1. **Non-root user available:**
   - UID 1000 user created in image
   - Can run services on high ports (>1024)
   - Sudo available for development tasks

2. **Capability controls:**
   - Only `CAP_NET_BIND_SERVICE` added when needed
   - No unnecessary privileges granted
   - Minimal attack surface

3. **Read-only filesystem options:**
   - Templates mounted read-only
   - System directories protected
   - User data in persistent volumes

## Security Checklist

Before deploying:

- [ ] Using non-root mode locally? (`make run-local-secure`)
- [ ] API keys set via environment variables only?
- [ ] No sensitive data in Dockerfile or scripts?
- [ ] Cloud Workstations IAM properly configured?
- [ ] Service account has minimal permissions?
- [ ] Firewall rules properly configured?
- [ ] No unnecessary ports exposed?
- [ ] Container image regularly updated?

## Vulnerability Management

1. **Keep base image updated:**
   ```bash
   docker pull us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest
   ```

2. **Scan for vulnerabilities:**
   ```bash
   gcloud container images scan IMAGE_URL
   ```

3. **Update dependencies regularly:**
   - Node.js packages
   - System packages
   - Midnight tools

## Reporting Security Issues

If you discover a security vulnerability:

1. Do NOT create a public issue
2. Email security details to: [security@midnight.network]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fixes (if any)