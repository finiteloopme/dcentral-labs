#!/bin/bash
#
# Install the Midnight Compact compiler toolchain.
#

set -euo pipefail

COMPACT_HOME="${COMPACT_HOME:-/usr/local/share/compact}"
COMPACT_VERSION="${COMPACT_VERSION:-0.26.0}"

echo "Installing Compact toolchain to ${COMPACT_HOME}..."

# Create installation directory
mkdir -p "${COMPACT_HOME}"

# Download and run the installer for the compact CLI
curl --proto '=https' --tlsv1.2 -LsSf \
    https://github.com/midnightntwrk/compact/releases/latest/download/compact-installer.sh \
    -o /tmp/compact-installer.sh

COMPACT_UNMANAGED_INSTALL="${COMPACT_HOME}" sh /tmp/compact-installer.sh

# Cleanup installer
rm /tmp/compact-installer.sh

# Set permissions for all users
chmod -R a+rx "${COMPACT_HOME}"

# Install the default compiler version
# The compact tool downloads compilers to COMPACT_DIRECTORY (default: ~/.compact)
# We set it to a shared location so all users can access it
export COMPACT_DIRECTORY="/usr/local/share/compact-compilers"
mkdir -p "${COMPACT_DIRECTORY}"

echo "Installing Compact compiler version ${COMPACT_VERSION}..."
"${COMPACT_HOME}/compact" update "${COMPACT_VERSION}"

# Set as default
echo "${COMPACT_VERSION}" > "${COMPACT_DIRECTORY}/default"

# Set permissions for all users
chmod -R a+rx "${COMPACT_DIRECTORY}"

echo "Compact installation complete (toolchain + compiler v${COMPACT_VERSION})."
