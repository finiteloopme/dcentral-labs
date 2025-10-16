#!/bin/bash
# Container runtime detection script
# Automatically detects and uses Podman or Docker

# Function to detect container runtime
detect_runtime() {
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo "none"
    fi
}

# Export the detected runtime
export CONTAINER_RUNTIME=$(detect_runtime)

# Wrapper function for container commands
container_cmd() {
    if [ "$CONTAINER_RUNTIME" = "none" ]; then
        echo "Error: No container runtime found. Please install Podman or Docker."
        echo "  Podman: https://podman.io/getting-started/installation"
        echo "  Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    $CONTAINER_RUNTIME "$@"
}

# Provide feedback about which runtime is being used
if [ "$CONTAINER_RUNTIME" != "none" ]; then
    echo "Using container runtime: $CONTAINER_RUNTIME"
fi

# Export the wrapper function for use in other scripts
export -f container_cmd