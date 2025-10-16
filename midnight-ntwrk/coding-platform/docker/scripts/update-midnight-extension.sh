#!/bin/bash
# Script to update the Midnight Compact VSCode extension

set -e

EXTENSION_VERSION="${1:-0.2.13}"
EXTENSION_URL="https://raw.githubusercontent.com/midnight-ntwrk/releases/gh-pages/artifacts/vscode-extension/compact-${EXTENSION_VERSION}/compact-${EXTENSION_VERSION}.vsix"

echo "Updating Midnight Compact VSCode extension to version ${EXTENSION_VERSION}..."

# Check if code-server is installed
if ! command -v code-server &> /dev/null; then
    echo "Error: code-server is not installed"
    exit 1
fi

# Download the extension
echo "Downloading extension from: ${EXTENSION_URL}"
mkdir -p /tmp/midnight-extension
curl -L -o /tmp/midnight-extension/compact.vsix "${EXTENSION_URL}"

if [ ! -f /tmp/midnight-extension/compact.vsix ]; then
    echo "Error: Failed to download extension"
    exit 1
fi

# Uninstall old version if exists
echo "Removing old version if exists..."
code-server --uninstall-extension midnight.compact 2>/dev/null || true

# Install new version
echo "Installing new version..."
code-server --install-extension /tmp/midnight-extension/compact.vsix

# Clean up
rm -rf /tmp/midnight-extension

echo "✓ Midnight Compact extension v${EXTENSION_VERSION} installed successfully"

# List installed extensions to verify
echo ""
echo "Installed extensions:"
code-server --list-extensions | grep -i midnight || echo "  (No Midnight extensions found - this might be normal if the extension has a different ID)"