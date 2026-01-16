#!/bin/bash
#
# Install OpenCode AI coding agent.
# https://opencode.ai
#
# Usage: ./opencode.sh [version]
#   version: npm package version (default: latest)
#

set -euo pipefail

VERSION="${1:-latest}"

echo "Installing OpenCode ${VERSION}..."

# Install OpenCode via npm (globally accessible to all users)
# This avoids the HOME directory permission issues with the official installer
if [[ "${VERSION}" == "latest" ]]; then
    npm install -g opencode-ai
else
    npm install -g "opencode-ai@${VERSION}"
fi

# Verify installation
if command -v opencode &> /dev/null; then
    echo "OpenCode installed successfully: $(opencode --version 2>/dev/null || echo 'version check skipped')"
else
    echo "Error: OpenCode installation failed" >&2
    exit 1
fi

echo "OpenCode installation complete."
