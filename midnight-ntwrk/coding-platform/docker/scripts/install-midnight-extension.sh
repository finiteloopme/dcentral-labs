#!/bin/bash
# Install or verify Midnight Compact VSCode extension

set -e

echo "=== Midnight Compact VSCode Extension Installer ==="
echo ""

EXTENSION_VERSION="${1:-0.2.13}"
EXTENSION_CACHED="/opt/midnight/extensions/compact-${EXTENSION_VERSION}.vsix"
EXTENSION_URL="https://raw.githubusercontent.com/midnight-ntwrk/releases/gh-pages/artifacts/vscode-extension/compact-${EXTENSION_VERSION}/compact-${EXTENSION_VERSION}.vsix"

# Function to install extension for Code OSS
install_for_code_oss() {
    echo "Installing for Code OSS..."
    
    # Code OSS extension directory locations
    EXTENSION_DIRS=(
        "/home/user/.local/share/code-server/extensions"
        "/home/user/.vscode-server/extensions"
        "/home/user/.vscode-oss/extensions"
        "$HOME/.local/share/code-server/extensions"
        "$HOME/.vscode-server/extensions"
        "$HOME/.vscode-oss/extensions"
        "/usr/share/code/resources/app/extensions"
    )
    
    # Find the correct extension directory
    INSTALL_DIR=""
    for dir in "${EXTENSION_DIRS[@]}"; do
        if [ -d "$(dirname "$dir")" ]; then
            INSTALL_DIR="$dir"
            mkdir -p "$INSTALL_DIR"
            break
        fi
    done
    
    if [ -z "$INSTALL_DIR" ]; then
        # Create default directory
        INSTALL_DIR="$HOME/.local/share/code-server/extensions"
        mkdir -p "$INSTALL_DIR"
    fi
    
    echo "Using extension directory: $INSTALL_DIR"
    
    # Extract the extension
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Copy and extract the VSIX file
    cp "$EXTENSION_FILE" extension.vsix
    unzip -q extension.vsix || {
        echo "Failed to extract extension"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    # Find the extension manifest
    if [ -f extension/package.json ]; then
        # Get extension ID from package.json
        PUBLISHER=$(jq -r '.publisher // "midnight"' extension/package.json)
        NAME=$(jq -r '.name // "compact"' extension/package.json)
        VERSION=$(jq -r '.version // "0.2.13"' extension/package.json)
        
        EXTENSION_ID="${PUBLISHER}.${NAME}-${VERSION}"
        
        # Install to extensions directory
        TARGET_DIR="${INSTALL_DIR}/${EXTENSION_ID}"
        echo "Installing to: $TARGET_DIR"
        
        rm -rf "$TARGET_DIR"
        mv extension "$TARGET_DIR"
        
        echo "✓ Extension installed successfully"
    else
        echo "✗ Could not find extension manifest"
    fi
    
    cd - >/dev/null
    rm -rf "$TEMP_DIR"
}

# Determine which VS Code variant we have
VSCODE_CMD=""
VSCODE_TYPE=""

# Check for different VS Code variants
if command -v code-oss &> /dev/null; then
    VSCODE_CMD="code-oss"
    VSCODE_TYPE="code-oss"
    echo "✓ Found Code OSS"
elif command -v code-server &> /dev/null; then
    VSCODE_CMD="code-server"
    VSCODE_TYPE="code-server"
    echo "✓ Found code-server"
elif command -v code &> /dev/null; then
    VSCODE_CMD="code"
    VSCODE_TYPE="code"
    echo "✓ Found VS Code"
else
    echo "✗ No VS Code installation found"
    echo ""
    echo "This extension requires VS Code, Code OSS, or code-server to be installed."
    exit 1
fi

# Check if extension is already installed
echo ""
echo "Checking installed extensions..."

INSTALLED=false
if [ "$VSCODE_TYPE" = "code-oss" ]; then
    # For Code OSS, check extension directories
    EXTENSION_DIRS=(
        "/home/user/.local/share/code-server/extensions"
        "/home/user/.vscode-server/extensions"
        "/home/user/.vscode-oss/extensions"
        "$HOME/.local/share/code-server/extensions"
        "$HOME/.vscode-server/extensions"
        "$HOME/.vscode-oss/extensions"
    )
    
    for dir in "${EXTENSION_DIRS[@]}"; do
        if [ -d "$dir" ] && ls "$dir" 2>/dev/null | grep -qi "midnight\|compact"; then
            echo "✓ Midnight Compact extension appears to be installed in $dir"
            INSTALLED=true
            break
        fi
    done
else
    # For code-server and regular VS Code
    if $VSCODE_CMD --list-extensions 2>/dev/null | grep -qi "midnight\|compact"; then
        echo "✓ Midnight Compact extension appears to be installed"
        INSTALLED=true
    fi
fi

if [ "$INSTALLED" = true ]; then
    echo ""
    read -p "Extension may already be installed. Reinstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation skipped."
        exit 0
    fi
fi

# Find the extension file
EXTENSION_FILE=""
if [ -f "$EXTENSION_CACHED" ]; then
    echo "✓ Found cached extension: $EXTENSION_CACHED"
    EXTENSION_FILE="$EXTENSION_CACHED"
else
    echo "✗ Cached extension not found at: $EXTENSION_CACHED"
    echo ""
    echo "Downloading extension from GitHub..."
    mkdir -p /tmp/midnight-extension
    
    if curl -L -o /tmp/midnight-extension/compact.vsix "${EXTENSION_URL}"; then
        echo "✓ Downloaded extension successfully"
        EXTENSION_FILE="/tmp/midnight-extension/compact.vsix"
        
        # Cache for future use
        echo "Caching extension for future use..."
        mkdir -p /opt/midnight/extensions
        cp "$EXTENSION_FILE" "$EXTENSION_CACHED" 2>/dev/null || echo "Note: Could not cache extension (permission issue)"
    else
        echo "✗ Failed to download extension from: ${EXTENSION_URL}"
        exit 1
    fi
fi

# Install the extension
echo ""
echo "Installing Midnight Compact extension v${EXTENSION_VERSION}..."

# Try standard installation first
if [ "$VSCODE_TYPE" = "code-oss" ]; then
    # Code OSS might not support --install-extension with VSIX files
    # Use manual installation
    install_for_code_oss
else
    # Try standard installation for code-server and VS Code
    if $VSCODE_CMD --install-extension "$EXTENSION_FILE" 2>/dev/null; then
        echo "✓ Extension installed successfully using $VSCODE_CMD"
    else
        echo "Standard installation failed, trying manual installation..."
        install_for_code_oss
    fi
fi

# Clean up temporary files
if [ -d /tmp/midnight-extension ]; then
    rm -rf /tmp/midnight-extension
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "The Midnight Compact extension provides:"
echo "  - Syntax highlighting for .compact files"
echo "  - Code completion and IntelliSense"
echo "  - Error checking and diagnostics"
echo "  - Integrated compiler support"
echo ""

# List installed extensions
echo "Checking installed extensions:"
if [ "$VSCODE_TYPE" = "code-oss" ]; then
    # Check extension directories
    EXTENSION_DIRS=(
        "/home/user/.local/share/code-server/extensions"
        "/home/user/.vscode-server/extensions"
        "/home/user/.vscode-oss/extensions"
        "$HOME/.local/share/code-server/extensions"
        "$HOME/.vscode-server/extensions"
        "$HOME/.vscode-oss/extensions"
    )
    
    for dir in "${EXTENSION_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "Extensions in $dir:"
            ls "$dir" 2>/dev/null | grep -i "midnight\|compact" || echo "  (none found)"
        fi
    done
else
    $VSCODE_CMD --list-extensions | head -20
fi

echo ""
echo "Note: You may need to reload VS Code for the extension to appear."
echo "In VS Code, press Ctrl+Shift+P and run 'Developer: Reload Window'"