#!/bin/bash
# Simple local run script that bypasses the Cloud Workstations initialization

echo "Starting Midnight Workstation locally..."
echo ""

# Detect container runtime
if command -v docker &>/dev/null; then
    RUNTIME=docker
elif command -v podman &>/dev/null; then
    RUNTIME=podman
else
    echo "Error: No container runtime found (docker or podman)"
    exit 1
fi

# Build if needed
if ! $RUNTIME image inspect midnight-workstation:latest &>/dev/null; then
    echo "Building image..."
    $RUNTIME build -t midnight-workstation:latest .
fi

# Check if API key is provided
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "✓ Anthropic API key detected"
    API_KEY_ARG="-e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
else
    echo "ℹ️  No Anthropic API key set (OpenCode will require manual setup)"
    API_KEY_ARG=""
fi

# Run with simple overrides
echo "Starting container..."
echo ""
$RUNTIME run -it --rm \
    --name midnight-local \
    --entrypoint /usr/local/bin/start-local \
    -p 8080:8080 \
    -p 8081:8081 \
    $API_KEY_ARG \
    midnight-workstation:latest