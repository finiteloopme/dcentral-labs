#!/bin/bash
#
# Install Podman and podman-compose for container orchestration.
#

set -euo pipefail

echo "Installing Podman and podman-compose..."

# Install podman-compose via pip
pip3 install --break-system-packages podman-compose

# Configure Podman for rootless operation (UID 1000)
# Note: The 'ubuntu' user exists in the base image and will be replaced
# by 'user' at container startup
touch /etc/subuid /etc/subgid
usermod --add-subuids 10000-75535 --add-subgids 10000-75535 ubuntu

echo "Podman installation complete."
