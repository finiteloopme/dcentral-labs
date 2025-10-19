# Start with base Cloud Workstations image
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# Switch to root for installation
USER root

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install additional packages including ttyd for web terminal
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    zip \
    unzip \
    vim \
    htop \
    sudo \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd (web terminal)
RUN wget -O /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 && \
    chmod +x /usr/local/bin/ttyd

# Install Node.js for OpenCode and other tools
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# VS Code is already included in the base Code OSS image - no need to install code-server

# Install OpenCode AI
RUN npm install -g opencode-ai

# Also install other useful AI tools
RUN npm install -g --force \
    @anthropic/claude-cli \
    aider-chat \
    2>/dev/null || true

# Create Midnight directories
RUN mkdir -p /opt/midnight/bin \
    /opt/midnight/lib \
    /opt/midnight/config \
    /workspace/templates \
    /workspace/projects

# Copy script files (excluding opencode to avoid conflicts)
COPY scripts/*.sh /opt/midnight/bin/
COPY scripts/opencode-config-template.json /opt/midnight/config/
RUN chmod +x /opt/midnight/bin/*.sh && \
    for script in /opt/midnight/bin/*.sh; do \
        if [ -f "$script" ]; then \
            basename_script=$(basename "$script" .sh); \
            # Skip opencode.sh to avoid conflict with real opencode-ai
            if [ "$basename_script" != "opencode" ]; then \
                mv "$script" "/opt/midnight/bin/$basename_script"; \
            else \
                rm "$script"; \
            fi \
        fi \
    done

# Set permissions for all users to access midnight tools
RUN chmod -R 755 /opt/midnight && \
    chmod -R 777 /workspace

# Set up environment variables globally
RUN echo 'PATH="/opt/midnight/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/environment && \
    echo 'MIDNIGHT_HOME="/opt/midnight"' >> /etc/environment

# Create a global bashrc addition for all users
RUN mkdir -p /etc/bash.bashrc.d && \
    echo '#!/bin/bash' > /etc/bash.bashrc.d/midnight.sh && \
    echo '# Midnight Development Environment' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'export PATH="/opt/midnight/bin:$PATH"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'export MIDNIGHT_HOME="/opt/midnight"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'export PS1="\[\033[01;32m\]\u@midnight\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '# Aliases' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'alias ll="ls -la"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'alias midnight="cd /workspace"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'alias compactc="/opt/midnight/bin/compactc"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'alias prove="/opt/midnight/bin/prove"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'alias verify="/opt/midnight/bin/verify"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'alias code="code-server"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '# Show welcome on first login' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'if [ ! -f ~/.midnight_welcomed ]; then' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "==========================================="' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "  Welcome to Midnight Development"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "  Workstation"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "==========================================="' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo ""' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "Available tools:"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "  - compactc: Compile Midnight contracts"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "  - prove: Generate proofs"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "  - verify: Verify proofs"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo ""' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "Get started:"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "  cd /workspace"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo "  ls -la"' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    echo ""' >> /etc/bash.bashrc.d/midnight.sh && \
    echo '    touch ~/.midnight_welcomed' >> /etc/bash.bashrc.d/midnight.sh && \
    echo 'fi' >> /etc/bash.bashrc.d/midnight.sh
RUN chmod +x /etc/bash.bashrc.d/midnight.sh

# Copy start-services script
COPY scripts/start-services.sh /opt/midnight/bin/start-services
RUN chmod +x /opt/midnight/bin/start-services

# Don't override the base image's entrypoint for Cloud Workstations
# Just add our initialization script
RUN echo '#!/bin/bash' > /opt/midnight/bin/init-midnight && \
    echo 'set -e' >> /opt/midnight/bin/init-midnight && \
    echo '' >> /opt/midnight/bin/init-midnight && \
    echo '# Source the midnight environment' >> /opt/midnight/bin/init-midnight && \
    echo 'if [ -f /etc/bash.bashrc.d/midnight.sh ]; then' >> /opt/midnight/bin/init-midnight && \
    echo '    source /etc/bash.bashrc.d/midnight.sh' >> /opt/midnight/bin/init-midnight && \
    echo 'fi' >> /opt/midnight/bin/init-midnight && \
    echo '' >> /opt/midnight/bin/init-midnight && \
    echo '# Configure AI credentials if available' >> /opt/midnight/bin/init-midnight && \
    echo 'if [ -f /opt/midnight/bin/configure-ai ]; then' >> /opt/midnight/bin/init-midnight && \
    echo '    source /opt/midnight/bin/configure-ai' >> /opt/midnight/bin/init-midnight && \
    echo 'fi' >> /opt/midnight/bin/init-midnight && \
    echo '' >> /opt/midnight/bin/init-midnight && \
    echo 'echo "Midnight tools initialized"' >> /opt/midnight/bin/init-midnight
RUN chmod +x /opt/midnight/bin/init-midnight

# Add initialization to bashrc so it runs when terminal opens
RUN echo "source /opt/midnight/bin/init-midnight" >> /etc/bash.bashrc

# Add Midnight tools to system PATH
ENV PATH="/opt/midnight/bin:${PATH}"
ENV MIDNIGHT_HOME="/opt/midnight"

# Expose ports (80 for Cloud Workstations, 8080 for local Code OSS)
EXPOSE 80 8080 3000 22

# Set working directory
WORKDIR /workspace

# Keep as root for compatibility (Cloud Workstations will handle user switching)
# Local development will also work fine as root in container

# Copy our wrapper script that handles port configuration
COPY scripts/start-code-oss.sh /opt/midnight/bin/start-code-oss
RUN chmod +x /opt/midnight/bin/start-code-oss

# Override entrypoint to use our wrapper for environment detection
ENTRYPOINT ["/opt/midnight/bin/start-code-oss"]