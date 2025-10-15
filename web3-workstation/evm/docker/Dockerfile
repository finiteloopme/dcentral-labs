# Use Ubuntu as base for local development (Cloud Workstation image may not be accessible)
FROM ubuntu:22.04

# Set up Podman-compatible environment
ENV container=podman

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    sudo \
    vim \
    nano \
    unzip \
    zip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install code-server (VS Code in browser)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install Google Cloud SDK for Vertex AI access
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk && \
    rm -rf /var/lib/apt/lists/*

# Install Vertex AI Python SDK
RUN pip3 install --upgrade google-cloud-aiplatform google-auth

# Create a non-root user for development
RUN useradd -m -s /bin/bash -u 1000 developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash && \
    /root/.foundry/bin/foundryup && \
    cp /root/.foundry/bin/* /usr/local/bin/

# Install OpenCode using the official installer
RUN curl -fsSL https://opencode.ai/install | bash

# Copy OpenCode configuration and setup script
COPY opencode-config.jsonc /home/developer/.config/opencode/opencode.jsonc
COPY setup-vertex-ai.sh /usr/local/bin/setup-vertex-ai.sh
RUN chmod +x /usr/local/bin/setup-vertex-ai.sh && \
    mkdir -p /home/developer/.config/opencode && \
    chown -R developer:developer /home/developer/.config

# Create directory for web terminal server
WORKDIR /opt/opencode-server

# Copy server files
COPY server/package.json ./
RUN npm install

COPY server/server.js ./
COPY server/index.html ./

# Install VS Code extensions for code-server
RUN sudo -u developer code-server --install-extension remixproject.ethereum-remix || true

# Create startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start-services.sh && \
    echo 'echo "Starting Web3 Workstation services..."' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Set up environment for Vertex AI' >> /usr/local/bin/start-services.sh && \
    echo 'export GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT:-${CLOUDSDK_CORE_PROJECT}}' >> /usr/local/bin/start-services.sh && \
    echo 'export VERTEX_AI_LOCATION=${VERTEX_AI_LOCATION:-us-central1}' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Run Vertex AI setup' >> /usr/local/bin/start-services.sh && \
    echo '/usr/local/bin/setup-vertex-ai.sh' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Start the OpenCode web terminal server' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Starting OpenCode terminal on port 8080..."' >> /usr/local/bin/start-services.sh && \
    echo 'cd /opt/opencode-server && node server.js &' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Start code-server on port 8000 (non-privileged)' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Starting VS Code on port 8000..."' >> /usr/local/bin/start-services.sh && \
    echo 'exec sudo -u developer code-server --bind-addr 0.0.0.0:8000 --auth none --disable-telemetry' >> /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/start-services.sh

# Expose ports (8000 for VS Code, 8080 for terminal)
EXPOSE 8000 8080

# Set working directory
WORKDIR /home/developer

# Switch to developer user for better security (but start script needs root)
USER root

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/start-services.sh"]