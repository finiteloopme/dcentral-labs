#!/bin/bash
#
# Install the Midnight Compact compiler.
#

set -euo pipefail

COMPACT_HOME="${COMPACT_HOME:-/usr/local/share/compact}"

echo "Installing Compact compiler to ${COMPACT_HOME}..."

# Create installation directory
mkdir -p "${COMPACT_HOME}"

# Download and run the installer
curl --proto '=https' --tlsv1.2 -LsSf \
    https://github.com/midnightntwrk/compact/releases/latest/download/compact-installer.sh \
    -o /tmp/compact-installer.sh

COMPACT_UNMANAGED_INSTALL="${COMPACT_HOME}" sh /tmp/compact-installer.sh

# Cleanup
rm /tmp/compact-installer.sh

# Set permissions for all users
chmod -R a+rx "${COMPACT_HOME}"

echo "Compact installation complete."
