# Midnight GenAI Development Platform
#
# Base image: Cloud Workstations Code OSS
# Includes: Compact compiler, Midnight CLI, midnight-node-toolkit, gcloud SDK
#
# Requires pre-built SDK image: make build-sdk
# The SDK image contains /opt/vendor with Midnight SDK 3.x packages built from source.

# ==============================================================================
# BUILD ARGS
# ==============================================================================
ARG SDK_IMAGE=midnight-sdk:latest
ARG MIDNIGHT_TOOLKIT_VERSION=0.18.0

# ==============================================================================
# Stage: sdk - Pre-built SDK packages
# ==============================================================================
FROM ${SDK_IMAGE} AS sdk

# ==============================================================================
# Stage: toolkit - Extract midnight-node-toolkit binary
# ==============================================================================
FROM docker.io/midnightntwrk/midnight-node-toolkit:${MIDNIGHT_TOOLKIT_VERSION} AS toolkit

# ==============================================================================
# Stage: final - Production image
# ==============================================================================
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

USER root

# System dependencies (suppress mandb warnings from base image permission issues)
RUN apt-get update && apt-get install -y \
    curl git build-essential libssl-dev pkg-config unzip jq netcat-openbsd \
    xz-utils sudo \
    2>&1 | grep -v "mandb" || true \
    && rm -rf /var/lib/apt/lists/*

# Update npm and install global packages
RUN npm install -g npm@latest typescript ts-node turbo

# Environment
ENV COMPACT_HOME="/usr/local/share/compact"
ENV PATH="${COMPACT_HOME}:${PATH}"
ENV CHAIN_ENVIRONMENT="standalone"
ENV MIDNIGHT_NETWORK="standalone"
ENV MIDNIGHT_TOOLKIT_PATH="/usr/local/bin/midnight-node-toolkit"

# Copy toolkit binary from the toolkit image
COPY --from=toolkit /midnight-node-toolkit ${MIDNIGHT_TOOLKIT_PATH}
RUN chmod +x ${MIDNIGHT_TOOLKIT_PATH}

# Container customization (installs Compact, configures Code OSS, etc.)
COPY container-scripts/ /tmp/container-scripts/
RUN chmod +x /tmp/container-scripts/main.sh && /tmp/container-scripts/main.sh

# ==============================================================================
# Vendor packages - Midnight SDK 3.x (from pre-built SDK image)
# ==============================================================================
COPY --from=sdk /opt/vendor /opt/vendor

# Debug: Show what packages are available
RUN echo "=== Vendor packages ===" && \
    cat /opt/vendor/manifest.txt 2>/dev/null || \
    find /opt/vendor -name "package.json" -exec dirname {} \; | sort

# ==============================================================================
# Midnight CLI
# ==============================================================================
COPY cli/ /opt/midnight-cli/

# Install CLI dependencies and build
# package.json uses file:/opt/vendor/... references
RUN cd /opt/midnight-cli && npm install && npm run build && \
    chmod +x /opt/midnight-cli/dist/index.js

# Environment setup script
COPY .devcontainer/setup-env.sh /opt/midnight-cli/setup-env.sh
RUN chmod +x /opt/midnight-cli/setup-env.sh

# Fix home directory ownership
RUN chown -R ubuntu:ubuntu /home/ubuntu
