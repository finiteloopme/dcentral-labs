#!/bin/bash
#
# Install OpenCode AI coding agent.
# https://opencode.ai
#

set -euo pipefail

OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-/etc/opencode}"

echo "Installing OpenCode..."

# Install OpenCode via npm (already have Node.js in container)
npm install -g opencode-ai

# Create global config directory
mkdir -p "${OPENCODE_CONFIG_DIR}"

# Verify installation
if command -v opencode &> /dev/null; then
    echo "OpenCode installed successfully: $(opencode --version 2>/dev/null || echo 'version check skipped')"
else
    echo "ERROR: OpenCode installation failed"
    exit 1
fi

echo "OpenCode installation complete."
