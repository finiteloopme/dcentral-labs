#!/bin/bash
#
# Create user directories at container startup.
#
# This script runs after user creation (010_add-user.sh) but before
# Code OSS startup (110_start-code-oss.sh) to create required directories
# with proper ownership for the 'user' account.
#
# Installed to: /etc/workstation-startup.d/015_user-dirs.sh
# Runs after: 010_add-user.sh (user creation)
# Runs before: 110_start-code-oss.sh (Code OSS startup)
#
# Directories created:
#   - /home/user/.config/gcloud/     - gcloud config (for disable_gcloud_gce_check.sh)
#   - /home/user/.config/opencode/   - OpenCode config
#   - /home/user/.cache/             - Code OSS extensions cache
#   - /home/user/.codeoss-cloudworkstations/ - Code OSS data
#

set -euo pipefail

echo "Creating user directories..."

# The 'user' account was just created by 010_add-user.sh

# Create .config directories
mkdir -p /home/user/.config/gcloud
mkdir -p /home/user/.config/opencode
chown -R user:user /home/user/.config

# Create .cache directory (Code OSS extensions need this)
mkdir -p /home/user/.cache
chown -R user:user /home/user/.cache

# Create .codeoss-cloudworkstations directory for extensions
mkdir -p /home/user/.codeoss-cloudworkstations/extensions
mkdir -p /home/user/.codeoss-cloudworkstations/data/logs
chown -R user:user /home/user/.codeoss-cloudworkstations

echo "  Created /home/user/.config/gcloud/"
echo "  Created /home/user/.config/opencode/"
echo "  Created /home/user/.cache/"
echo "  Created /home/user/.codeoss-cloudworkstations/"

# Persist container environment variables to a file that profile.d scripts can source.
# This is needed because 'su - user' (login shell) clears the environment.
# We save key env vars to /etc/container-env.sh which is sourced by profile.d/container-env.sh
ENV_FILE="/etc/container-env.sh"
echo "# Container environment variables (generated at startup)" > "$ENV_FILE"

# Persist GOOGLE_CLOUD_PROJECT if set (for Vertex AI)
if [[ -n "${GOOGLE_CLOUD_PROJECT:-}" ]]; then
    echo "export GOOGLE_CLOUD_PROJECT='$GOOGLE_CLOUD_PROJECT'" >> "$ENV_FILE"
    echo "  Persisted GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT"
fi

# Persist chain-specific overrides if set
if [[ -n "${RPC_URL:-}" ]]; then
    echo "export RPC_URL='$RPC_URL'" >> "$ENV_FILE"
    echo "  Persisted RPC_URL=$RPC_URL"
fi

if [[ -n "${CHAIN_ID:-}" ]]; then
    echo "export CHAIN_ID='$CHAIN_ID'" >> "$ENV_FILE"
    echo "  Persisted CHAIN_ID=$CHAIN_ID"
fi

if [[ -n "${EXPLORER_URL:-}" ]]; then
    echo "export EXPLORER_URL='$EXPLORER_URL'" >> "$ENV_FILE"
fi

if [[ -n "${FAUCET_URL:-}" ]]; then
    echo "export FAUCET_URL='$FAUCET_URL'" >> "$ENV_FILE"
fi

chmod 644 "$ENV_FILE"
