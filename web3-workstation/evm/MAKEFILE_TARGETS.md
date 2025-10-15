# Makefile Targets Reference

Complete list of all available Makefile targets.

## Main Commands

```bash
make help         # Show help with common commands
make quick-start  # Complete setup and cloud deployment
make local        # Run locally without cloud
make deploy       # Deploy to Google Cloud
make status       # Show deployment status
make clean        # Clean local resources
make destroy      # Destroy cloud infrastructure
```

## Local Development

```bash
make local-dev    # Start local development environment
make local-stop   # Stop local container
make local-clean  # Remove local container and image
```

## Container Management

```bash
make build        # Build container image
make push         # Push to Artifact Registry
make test         # Test container image
```

## Terraform Operations

```bash
make terraform-init   # Initialize Terraform
make terraform-plan   # Plan infrastructure changes  
make terraform-apply  # Apply infrastructure changes
```

## Documentation

```bash
make docs         # Show all documentation
make targets      # Show this file
```

## Utilities

```bash
make install-deps # Install missing dependencies
```

## Environment Variables

```bash
# Required for cloud
export PROJECT_ID=your-gcp-project-id

# Optional overrides
export REGION=us-central1
export IMAGE_TAG=latest
export MEMORY=8g         # For local dev
export CPUS=4           # For local dev
```

## Advanced Usage

### Custom Builds

```bash
# Build with specific tag
IMAGE_TAG=v1.0.0 make build push

# Deploy to different region
REGION=europe-west1 make deploy
```

### Local Development Options

```bash
# Custom resources
MEMORY=8g CPUS=4 make local

# Custom workspace
VOLUME_HOME=/my/workspace make local
```

### Direct Script Access

All make targets call scripts in the `scripts/` directory:

```bash
./scripts/quick-start.sh      # Full deployment
./scripts/local-dev.sh        # Local development
./scripts/build-and-push.sh   # Container operations
./scripts/deploy.sh           # Cloud deployment
./scripts/status.sh           # Status check
./scripts/cleanup.sh          # Cleanup operations
./scripts/test.sh             # Testing
```

## Troubleshooting

```bash
# Check what will run
make -n <target>

# Run with verbose output  
make <target> VERBOSE=1

# Debug Terraform
cd terraform && terraform plan
```