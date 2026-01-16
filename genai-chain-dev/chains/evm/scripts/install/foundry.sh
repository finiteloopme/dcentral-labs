#!/bin/bash
# Install Foundry (forge, cast, anvil, chisel)
# Usage: ./foundry.sh [version]

set -euo pipefail

VERSION="${1:-nightly}"

echo "Installing Foundry ${VERSION}..."

# Install foundryup
curl -L https://foundry.paradigm.xyz | bash

# Source the foundry environment
export PATH="${HOME}/.foundry/bin:${PATH}"

# Install specific version
if [[ "${VERSION}" == "nightly" ]]; then
    foundryup
else
    foundryup --version "${VERSION}"
fi

# Verify installation
echo "Foundry installed successfully:"
echo "  forge: $(forge --version)"
echo "  cast: $(cast --version)"
echo "  anvil: $(anvil --version)"
