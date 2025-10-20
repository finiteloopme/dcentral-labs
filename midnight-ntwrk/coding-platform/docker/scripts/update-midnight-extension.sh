#!/bin/bash
# Script to update the Midnight Compact VSCode extension

set -e

EXTENSION_VERSION="${1:-0.2.13}"
EXTENSION_CACHED="/opt/midnight/extensions/compact-${EXTENSION_VERSION}.vsix"
EXTENSION_URL="https://raw.githubusercontent.com/midnight-ntwrk/releases/gh-pages/artifacts/vscode-extension/compact-${EXTENSION_VERSION}/compact-${EXTENSION_VERSION}.vsix"

echo "Updating Midnight Compact VSCode extension to version ${EXTENSION_VERSION}..."

# Determine which VS Code command to use
if command -v code-server &> /dev/null; then
    VSCODE_CMD="code-server"
elif command -v code &> /dev/null; then
    VSCODE_CMD="code"
else
    echo "Error: Neither code-server nor code is installed"
    exit 1
fi

# Check if we have a cached version
if [ -f "$EXTENSION_CACHED" ]; then
    echo "Using cached extension from: $EXTENSION_CACHED"
    EXTENSION_FILE="$EXTENSION_CACHED"
else
    # Download the extension
    echo "Downloading extension from: ${EXTENSION_URL}"
    mkdir -p /tmp/midnight-extension
    curl -L -o /tmp/midnight-extension/compact.vsix "${EXTENSION_URL}"
    
    if [ ! -f /tmp/midnight-extension/compact.vsix ]; then
        echo "Error: Failed to download extension"
        exit 1
    fi
    EXTENSION_FILE="/tmp/midnight-extension/compact.vsix"
fi

# Uninstall old version if exists
echo "Removing old version if exists..."
$VSCODE_CMD --uninstall-extension midnight.compact 2>/dev/null || true

# Install new version
echo "Installing new version..."
$VSCODE_CMD --install-extension "$EXTENSION_FILE"

# Clean up temporary files if we downloaded
if [ -d /tmp/midnight-extension ]; then
    rm -rf /tmp/midnight-extension
fi

# Cache the extension for future use if not already cached
if [ "$EXTENSION_FILE" != "$EXTENSION_CACHED" ] && [ ! -f "$EXTENSION_CACHED" ]; then
    mkdir -p /opt/midnight/extensions
    cp "$EXTENSION_FILE" "$EXTENSION_CACHED" 2>/dev/null || true
fi

echo "✓ Midnight Compact extension v${EXTENSION_VERSION} installed successfully"

# List installed extensions to verify
echo ""
echo "Installed extensions:"
$VSCODE_CMD --list-extensions | grep -i midnight || $VSCODE_CMD --list-extensions | grep -i compact || echo "  (Checking all extensions...)"
echo ""
echo "All VS Code extensions:"
$VSCODE_CMD --list-extensions