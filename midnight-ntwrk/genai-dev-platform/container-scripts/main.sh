#!/bin/bash
#
# Main container setup script
#
# This script orchestrates all container customization:
# 1. Install tools (Compact compiler, etc.)
# 2. Configure services (Code OSS, etc.)
# 3. Install profile scripts and CLI tools
#
# Usage: Called from Dockerfile during image build
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  Midnight Development Container Setup"
echo "========================================"
echo ""

# ------------------------------------------------------------------------------
# Install Tools
# ------------------------------------------------------------------------------

echo "[1/4] Installing tools..."

# Compact compiler
if [[ -x "${SCRIPT_DIR}/install/compact.sh" ]]; then
    "${SCRIPT_DIR}/install/compact.sh"
fi

echo ""

# ------------------------------------------------------------------------------
# Configure Services
# ------------------------------------------------------------------------------

echo "[2/4] Configuring services..."

# Code OSS runtime port detection
if [[ -x "${SCRIPT_DIR}/configure/codeoss.sh" ]]; then
    "${SCRIPT_DIR}/configure/codeoss.sh"
fi

echo ""

# ------------------------------------------------------------------------------
# Install Profile Scripts
# ------------------------------------------------------------------------------

echo "[3/4] Installing profile scripts..."

# Copy profile.d scripts for shell initialization
for script in "${SCRIPT_DIR}"/profile.d/*.sh; do
    if [[ -f "$script" ]]; then
        cp "$script" /etc/profile.d/
        chmod +x "/etc/profile.d/$(basename "$script")"
        echo "  Installed: $(basename "$script")"
    fi
done

echo ""

# ------------------------------------------------------------------------------
# Install CLI Tools
# ------------------------------------------------------------------------------

echo "[4/4] Installing CLI tools..."

# Copy bin scripts to /usr/local/bin
for bin in "${SCRIPT_DIR}"/bin/*; do
    if [[ -f "$bin" ]]; then
        cp "$bin" /usr/local/bin/
        chmod +x "/usr/local/bin/$(basename "$bin")"
        echo "  Installed: $(basename "$bin")"
    fi
done

echo ""

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

echo "Cleaning up..."
rm -rf "${SCRIPT_DIR}"

echo ""
echo "========================================"
echo "  Container setup complete!"
echo "========================================"
