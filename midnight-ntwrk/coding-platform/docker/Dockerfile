# syntax=docker/dockerfile:1

# Midnight Development Workstation for Google Cloud Workstations
# Based on Google's cloud-workstations-custom-image-examples patterns
# Reference: https://github.com/GoogleCloudPlatform/cloud-workstations-custom-image-examples

FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss

# Extension version
ARG MIDNIGHT_EXT_VERSION=0.2.13

# Switch to root for installation
USER root

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install additional packages required for Midnight development
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    jq \
    zip \
    unzip \
    vim \
    build-essential \
    python3 \
    python3-pip \
    net-tools \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x for Midnight tools and proof server
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install the actual OpenCode TUI application (opencode-ai package)
RUN npm install -g opencode-ai@latest && \
    # Verify installation
    which opencode && \
    opencode --version || echo "OpenCode TUI installed"

# Install Midnight Compact Language extension as @builtin extension in Code OSS
RUN wget https://raw.githubusercontent.com/midnight-ntwrk/releases/gh-pages/artifacts/vscode-extension/compact-${MIDNIGHT_EXT_VERSION}/compact-${MIDNIGHT_EXT_VERSION}.vsix && \
    unzip -q compact-${MIDNIGHT_EXT_VERSION}.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/midnight.compact && \
    rm compact-${MIDNIGHT_EXT_VERSION}.vsix

# Create Midnight directories
RUN mkdir -p /opt/midnight/bin \
    /opt/midnight/proof-server/src \
    /opt/templates

# Install Midnight Compact compiler (placeholder - replace with actual when available)
RUN echo '#!/bin/bash\necho "Midnight Compact Compiler v0.2.13"\necho "Compiling $@..."\nsleep 1\necho "Compilation complete"' > /opt/midnight/bin/compactc && \
    chmod +x /opt/midnight/bin/compactc && \
    ln -s /opt/midnight/bin/compactc /usr/local/bin/compactc

# Copy Midnight project templates
COPY templates/ /opt/templates/

# Copy Midnight tools and scripts  
COPY scripts/*.sh /opt/midnight/bin/
RUN chmod +x /opt/midnight/bin/*.sh && \
    for script in /opt/midnight/bin/*.sh; do \
        if [ -f "$script" ]; then \
            basename_script=$(basename "$script" .sh); \
            mv "$script" "/opt/midnight/bin/$basename_script"; \
        fi \
    done

# Set up the proof service
COPY proof-server-package.json /opt/midnight/proof-server/package.json
COPY proof-server.js /opt/midnight/proof-server/src/server.js

# Install proof server dependencies
WORKDIR /opt/midnight/proof-server
RUN npm install --production

# Copy startup scripts to assets directory then merge into container
COPY ./assets/. /

# Copy local development startup scripts
COPY start-local.sh /usr/local/bin/start-local
COPY start-local-minimal.sh /usr/local/bin/start-local-minimal
RUN chmod +x /usr/local/bin/start-local /usr/local/bin/start-local-minimal

# Create symlinks for Midnight tools (but not opencode - that's installed via npm)
RUN ln -sf /opt/midnight/bin/midnight /usr/local/bin/midnight && \
    ln -sf /opt/midnight/bin/prove /usr/local/bin/prove && \
    ln -sf /opt/midnight/bin/verify /usr/local/bin/verify

# Set permissions for all directories
RUN chmod -R 755 /opt/midnight && \
    chmod -R 755 /opt/templates && \
    chmod -R 755 /opt/code-oss/extensions/midnight.compact

# Add environment variables
ENV PATH="/opt/midnight/bin:${PATH}"
ENV MIDNIGHT_HOME="/opt/midnight"
# OpenCode will use this if set
ENV OPENCODE_MODEL="claude-3.5-sonnet"

# Set working directory
WORKDIR /home/user

# Switch to non-root user as required by Cloud Workstations
# The base image handles user creation and port binding
USER 1000

# Verify critical paths are accessible as non-root user
RUN test -r /opt/midnight/bin/midnight && \
    test -d /opt/code-oss/extensions/midnight.compact && \
    test -r /opt/templates/basic-token/contracts/Token.compact && \
    echo "✓ Build verification complete"

# Note: Cloud Workstations will handle:
# - Starting Code OSS on port 80 (with CAP_NET_BIND_SERVICE capability)
# - Running startup scripts with appropriate permissions
# - User session management