#!/bin/bash
# Install common development tools
# This is typically run during container build

set -euo pipefail

echo "Installing common development tools..."

apt-get update

apt-get install -y --no-install-recommends \
    jq \
    curl \
    wget \
    git \
    unzip \
    netcat-openbsd \
    ca-certificates

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Common tools installed successfully"
