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

# Install code-server (VS Code in browser)
RUN curl -fsSL https://code-server.dev/install.sh | sh || true

# Install OpenCode AI - the actual package!
RUN npm install -g opencode-ai && \
    # Verify installation and create symlink if needed
    (which opencode || ln -s /usr/local/bin/opencode /usr/bin/opencode 2>/dev/null || true)

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
    cat > /etc/bash.bashrc.d/midnight.sh <<'EOF'
# Midnight Development Environment
export PATH="/opt/midnight/bin:$PATH"
export MIDNIGHT_HOME="/opt/midnight"
export PS1='\[\033[01;32m\]\u@midnight\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Aliases
alias ll="ls -la"
alias midnight="cd /workspace"
alias compactc="/opt/midnight/bin/compactc"
alias prove="/opt/midnight/bin/prove"
alias verify="/opt/midnight/bin/verify"
alias code="code-server"
# opencode is installed globally via npm, no alias needed

# Show welcome on first login
if [ ! -f ~/.midnight_welcomed ]; then
    echo "==========================================="
    echo "  Welcome to Midnight Development"
    echo "  Workstation"
    echo "==========================================="
    echo ""
    echo "Available tools:"
    echo "  - compactc: Compile Midnight contracts"
    echo "  - prove: Generate proofs"
    echo "  - verify: Verify proofs"
    echo ""
    echo "Get started:"
    echo "  cd /workspace"
    echo "  ls -la"
    echo ""
    touch ~/.midnight_welcomed
fi
EOF
RUN chmod +x /etc/bash.bashrc.d/midnight.sh

# Copy start-services script
COPY scripts/start-services.sh /opt/midnight/bin/start-services
RUN chmod +x /opt/midnight/bin/start-services

# Create a proper entrypoint that starts services
RUN cat > /docker-entrypoint.sh <<'EOF'
#!/bin/bash
set -e

# Source the midnight environment
if [ -f /etc/bash.bashrc.d/midnight.sh ]; then
    source /etc/bash.bashrc.d/midnight.sh
fi

# Configure AI credentials if available
if [ -f /opt/midnight/bin/configure-ai ]; then
    source /opt/midnight/bin/configure-ai
fi

# Only start heavy services if not in test mode
if [ "$MIDNIGHT_LIGHTWEIGHT" != "true" ]; then
    # Start ttyd only
    if command -v ttyd >/dev/null 2>&1; then
        echo "Starting web terminal on port 7681..."
        ttyd -p 7681 -W /bin/bash &
    fi
fi

# If no arguments, run bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    exec "$@"
fi
EOF
RUN chmod +x /docker-entrypoint.sh

# Add Midnight tools to system PATH
ENV PATH="/opt/midnight/bin:${PATH}"
ENV MIDNIGHT_HOME="/opt/midnight"

# Expose ports
EXPOSE 7681 8080 8443 3000

# Set working directory
WORKDIR /workspace

# Keep as root for compatibility (Cloud Workstations will handle user switching)
# Local development will also work fine as root in container

# Set entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/bin/bash"]