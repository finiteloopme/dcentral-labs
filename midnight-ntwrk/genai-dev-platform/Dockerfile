# Midnight GenAI Development Platform
#
# Base image: Cloud Workstations Code OSS
# Includes: Compact compiler, Midnight CLI, gcloud SDK

FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

USER root

# System dependencies (suppress mandb warnings from base image permission issues)
RUN apt-get update && apt-get install -y \
    curl git build-essential libssl-dev pkg-config unzip jq netcat-openbsd \
    2>&1 | grep -v "mandb" || true \
    && rm -rf /var/lib/apt/lists/*

# Update npm and install global packages
RUN npm install -g npm@latest typescript ts-node

# Environment
ENV COMPACT_HOME="/usr/local/share/compact"
ENV PATH="${COMPACT_HOME}:${PATH}"
ENV CHAIN_ENVIRONMENT="standalone"
ENV MIDNIGHT_NETWORK="standalone"

# Container customization (installs Compact, configures Code OSS, etc.)
COPY container-scripts/ /tmp/container-scripts/
RUN chmod +x /tmp/container-scripts/main.sh && /tmp/container-scripts/main.sh

# Midnight CLI
COPY cli/ /opt/midnight-cli/
RUN cd /opt/midnight-cli && npm install && npm run build && \
    chmod +x /opt/midnight-cli/dist/index.js

# Environment setup script
COPY .devcontainer/setup-env.sh /opt/midnight-cli/setup-env.sh
RUN chmod +x /opt/midnight-cli/setup-env.sh

# Fix home directory ownership
RUN chown -R ubuntu:ubuntu /home/ubuntu
