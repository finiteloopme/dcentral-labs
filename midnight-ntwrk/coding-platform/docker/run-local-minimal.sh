#!/bin/bash
# Minimal local run script - just the essentials without Code OSS
# Perfect for CLI work and API testing

echo "Starting Midnight Workstation (Minimal Mode)..."
echo "=============================================="
echo ""

# Detect container runtime
if command -v podman &>/dev/null; then
    RUNTIME=podman
elif command -v docker &>/dev/null; then
    RUNTIME=docker
else
    echo "Error: No container runtime found (docker or podman)"
    exit 1
fi

echo "Using: $RUNTIME"

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

# Stop any existing container
$RUNTIME stop midnight-local 2>/dev/null || true
$RUNTIME rm midnight-local 2>/dev/null || true

# Run in minimal mode
echo ""
echo "Starting container in minimal mode..."
echo ""
$RUNTIME run -d \
    --name midnight-local \
    --entrypoint /usr/local/bin/start-local-minimal \
    -p 8080:8080 \
    -p 8081:8081 \
    $API_KEY_ARG \
    midnight-workstation:latest

echo ""
echo "Container started! Services available at:"
echo "  • Documentation: http://localhost:8080"
echo "  • Proof Server: http://localhost:8081"
echo ""
echo "To access the container shell:"
echo "  $RUNTIME exec -it midnight-local /bin/bash"
echo ""
echo "To use OpenCode:"
echo "  1. Access the container: $RUNTIME exec -it midnight-local /bin/bash"
echo "  2. Run: opencode"
echo ""
echo "To stop:"
echo "  $RUNTIME stop midnight-local"
echo ""
echo "To view logs:"
echo "  $RUNTIME logs -f midnight-local"