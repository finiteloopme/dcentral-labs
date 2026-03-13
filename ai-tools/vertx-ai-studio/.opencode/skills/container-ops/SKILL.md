---
name: container-ops
description: Podman container operations best practices and patterns
---

## What I do

- Guide Containerfile/Dockerfile authoring with best practices
- Provide patterns for multi-stage builds
- Document Podman-specific features and differences from Docker
- Cover image security and scanning practices

## When to use me

Use this skill when building container images, troubleshooting container
issues, or setting up containerized development environments.

## Podman vs Docker

Podman is a drop-in replacement for Docker with key differences:

| Feature | Podman | Docker |
|---------|--------|--------|
| Daemon | Daemonless | Requires dockerd |
| Root | Rootless by default | Root by default |
| Compose | `podman-compose` or `podman compose` | `docker compose` |
| Systemd | Native systemd integration | Requires configuration |
| Pods | Native pod support (like K8s) | Not supported |
| Socket | `podman.sock` | `docker.sock` |

## Containerfile Best Practices

### Multi-stage builds

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production=false
COPY . .
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
USER node
CMD ["node", "dist/index.js"]
```

### Layer optimization

1. Order instructions from least to most frequently changing
2. Combine RUN commands to reduce layers
3. Use `.containerignore` / `.dockerignore` to exclude unnecessary files
4. Pin base image versions (avoid `latest` tag)

### Security

1. Use non-root user: `USER node` or `USER 1000`
2. Use `COPY` instead of `ADD` (unless extracting archives)
3. Scan images: `podman image scan <image>`
4. Use minimal base images (`-alpine`, `-slim`, `distroless`)
5. Do not store secrets in images -- use runtime env vars or mounted secrets

## Common Podman Commands

```bash
# Build
podman build -t myapp:latest .

# Run (detached, with port mapping)
podman run -d --name myapp -p 8080:3000 myapp:latest

# View logs
podman logs -f myapp

# Execute command in running container
podman exec -it myapp sh

# Stop and remove
podman stop myapp && podman rm myapp

# List images and containers
podman images
podman ps -a

# Prune unused resources
podman system prune -a
```

## Podman Pods

Pods group containers that share network and IPC namespaces (similar to
Kubernetes pods):

```bash
# Create a pod
podman pod create --name mystack -p 8080:80

# Add containers to the pod
podman run -d --pod mystack --name web nginx
podman run -d --pod mystack --name api myapi:latest

# Manage the pod
podman pod ps
podman pod stop mystack
podman pod rm mystack
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Permission denied | Check rootless setup: `podman unshare cat /proc/self/uid_map` |
| Image pull fails | Check registry config: `cat /etc/containers/registries.conf` |
| Container won't start | Check logs: `podman logs <container>` |
| Port already in use | Find process: `ss -tlnp sport = :<port>` |
| Disk space full | Clean up: `podman system prune -a --volumes` |

## Agent Integration

- Build, run, and manage containers using Podman (not Docker).
- Container build files live in `cicd/`, not at the project root.
- NEVER delete containers, images, or volumes without user confirmation.
- ALWAYS show what will change before executing destructive container operations.
