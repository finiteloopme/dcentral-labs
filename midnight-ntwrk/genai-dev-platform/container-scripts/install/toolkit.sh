#!/bin/bash
# Install midnight-node-toolkit binary
#
# This script extracts the midnight-node-toolkit binary from the official Docker image.
# The toolkit provides commands for wallet operations, transfers, and DUST management.
#
# Usage: ./toolkit.sh
#
# Environment Variables:
#   MIDNIGHT_TOOLKIT_VERSION - Toolkit version to install (default: 0.18.0)
#   MIDNIGHT_TOOLKIT_PATH    - Installation path (default: /usr/local/bin/midnight-node-toolkit)

set -e

TOOLKIT_VERSION="${MIDNIGHT_TOOLKIT_VERSION:-0.18.0}"
TOOLKIT_IMAGE="docker.io/midnightntwrk/midnight-node-toolkit:${TOOLKIT_VERSION}"
INSTALL_PATH="${MIDNIGHT_TOOLKIT_PATH:-/usr/local/bin/midnight-node-toolkit}"

echo "Installing midnight-node-toolkit ${TOOLKIT_VERSION}..."

# Detect container runtime (podman or docker)
if command -v podman &> /dev/null; then
    CONTAINER_RUNTIME="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_RUNTIME="docker"
else
    echo "Error: Neither podman nor docker found. Cannot extract toolkit binary."
    exit 1
fi

echo "Using container runtime: ${CONTAINER_RUNTIME}"

# Create a temporary container to extract the binary
container_id=$($CONTAINER_RUNTIME create "${TOOLKIT_IMAGE}" 2>/dev/null)

if [ -z "$container_id" ]; then
    echo "Error: Failed to create container from ${TOOLKIT_IMAGE}"
    exit 1
fi

# Extract the binary
echo "Extracting binary from container..."
$CONTAINER_RUNTIME cp "${container_id}:/midnight-node-toolkit" "${INSTALL_PATH}"

# Clean up the temporary container
$CONTAINER_RUNTIME rm "${container_id}" > /dev/null

# Make executable
chmod +x "${INSTALL_PATH}"

# Verify installation
if [ -x "${INSTALL_PATH}" ]; then
    echo "Successfully installed midnight-node-toolkit to ${INSTALL_PATH}"
    "${INSTALL_PATH}" version 2>/dev/null || echo "  Version: ${TOOLKIT_VERSION}"
else
    echo "Error: Installation failed - binary not executable"
    exit 1
fi
