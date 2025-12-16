#!/bin/bash
# Midnight VS Code Extensions Setup
# Installs Midnight Compact extension for Code OSS

set -e

echo "🔧 Installing Midnight VS Code extensions..."

# Create temp directory for extension downloads
mkdir -p /tmp/vscode-extensions
cd /tmp/vscode-extensions

# Download Midnight Compact extension
echo "Downloading Midnight Compact extension..."
curl -L -o compact-0.2.13.vsix https://raw.githubusercontent.com/midnight-ntwrk/releases/gh-pages/artifacts/vscode-extension/compact-0.2.13/compact-0.2.13.vsix

# Install Midnight Compact extension
echo "Installing Midnight Compact extension..."
/opt/code-oss/bin/codeoss-cloudworkstations --install-extension /tmp/vscode-extensions/compact-0.2.13.vsix

echo "✅ Midnight Compact extension installed successfully!"

# Install other useful extensions for Midnight development
echo "Installing additional development extensions..."
/opt/code-oss/bin/codeoss-cloudworkstations --install-extension ms-vscode.vscode-typescript-next
/opt/code-oss/bin/codeoss-cloudworkstations --install-extension rust-lang.rust-analyzer
/opt/code-oss/bin/codeoss-cloudworkstations --install-extension ms-vscode.cpptools-extension-pack

echo "✅ Additional development extensions installed!"

# Cleanup
rm -rf /tmp/vscode-extensions