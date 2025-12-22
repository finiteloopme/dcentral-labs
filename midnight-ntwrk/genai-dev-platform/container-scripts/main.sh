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

echo "[1/5] Installing tools..."

# Compact compiler
if [[ -x "${SCRIPT_DIR}/install/compact.sh" ]]; then
    "${SCRIPT_DIR}/install/compact.sh"
fi

# Verify midnight-node-toolkit (binary is copied via Dockerfile multi-stage build)
if [[ -x "${MIDNIGHT_TOOLKIT_PATH:-/usr/local/bin/midnight-node-toolkit}" ]]; then
    echo "  midnight-node-toolkit: installed"
else
    echo "  midnight-node-toolkit: not found (will use fallback extraction at runtime)"
fi

# OpenCode AI coding agent
if [[ -x "${SCRIPT_DIR}/install/opencode.sh" ]]; then
    "${SCRIPT_DIR}/install/opencode.sh"
fi

echo ""

# ------------------------------------------------------------------------------
# Configure Services
# ------------------------------------------------------------------------------

echo "[2/5] Configuring services..."

# Code OSS runtime port detection
if [[ -x "${SCRIPT_DIR}/configure/codeoss.sh" ]]; then
    "${SCRIPT_DIR}/configure/codeoss.sh"
fi

echo ""

# ------------------------------------------------------------------------------
# Install Profile Scripts
# ------------------------------------------------------------------------------

echo "[3/5] Installing profile scripts..."

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

echo "[4/5] Installing CLI tools..."

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
# Configure OpenCode
# ------------------------------------------------------------------------------

echo "[5/5] Configuring OpenCode..."

# Create global OpenCode config directory
OPENCODE_GLOBAL_CONFIG="/etc/opencode"
mkdir -p "${OPENCODE_GLOBAL_CONFIG}"

# Copy OpenCode configuration files
if [[ -d "${SCRIPT_DIR}/opencode" ]]; then
    cp "${SCRIPT_DIR}/opencode/opencode.json" "${OPENCODE_GLOBAL_CONFIG}/"
    cp "${SCRIPT_DIR}/opencode/AGENTS.md" "${OPENCODE_GLOBAL_CONFIG}/"
    chmod 644 "${OPENCODE_GLOBAL_CONFIG}/opencode.json"
    chmod 644 "${OPENCODE_GLOBAL_CONFIG}/AGENTS.md"
    echo "  Installed: opencode.json (Vertex AI + Gemini 2.5 Pro)"
    echo "  Installed: AGENTS.md (Midnight context)"
fi

# Create symlinks in user home for OpenCode to discover
# OpenCode looks in ~/.config/opencode/ for global config
USER_CONFIG_DIR="/home/ubuntu/.config/opencode"
mkdir -p "${USER_CONFIG_DIR}"
ln -sf "${OPENCODE_GLOBAL_CONFIG}/opencode.json" "${USER_CONFIG_DIR}/opencode.json"
ln -sf "${OPENCODE_GLOBAL_CONFIG}/AGENTS.md" "${USER_CONFIG_DIR}/AGENTS.md"
chown -R ubuntu:ubuntu /home/ubuntu/.config

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
