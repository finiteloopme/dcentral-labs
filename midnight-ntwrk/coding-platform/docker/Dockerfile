# Start with base Cloud Workstations image
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install additional packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    zip \
    unzip \
    vim \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Create Midnight directories
RUN mkdir -p /opt/midnight/bin \
    /opt/midnight/lib \
    /opt/midnight/config \
    /workspace/templates \
    /workspace/projects

# Copy script files if they exist (using conditional approach)
RUN mkdir -p /etc/workstation-startup.d
COPY scripts/*.sh /opt/midnight/bin/
RUN chmod +x /opt/midnight/bin/*.sh && \
    for script in /opt/midnight/bin/*.sh; do \
        if [ -f "$script" ]; then \
            basename_script=$(basename "$script" .sh); \
            mv "$script" "/opt/midnight/bin/$basename_script"; \
        fi \
    done

# Setup basic configuration
WORKDIR /workspace

# Create welcome script using echo commands
RUN echo '#!/bin/bash' > /workspace/welcome.sh && \
    echo 'echo "==========================================="' >> /workspace/welcome.sh && \
    echo 'echo "  Welcome to Midnight Development"' >> /workspace/welcome.sh && \
    echo 'echo "  Workstation"' >> /workspace/welcome.sh && \
    echo 'echo "==========================================="' >> /workspace/welcome.sh && \
    echo 'echo ""' >> /workspace/welcome.sh && \
    echo 'echo "Available tools:"' >> /workspace/welcome.sh && \
    echo 'echo "  - compactc: Compile Midnight contracts"' >> /workspace/welcome.sh && \
    echo 'echo "  - prove: Generate proofs"' >> /workspace/welcome.sh && \
    echo 'echo "  - verify: Verify proofs"' >> /workspace/welcome.sh && \
    echo 'echo ""' >> /workspace/welcome.sh && \
    echo 'echo "Get started:"' >> /workspace/welcome.sh && \
    echo 'echo "  cd /workspace/templates"' >> /workspace/welcome.sh && \
    echo 'echo "  ls -la"' >> /workspace/welcome.sh && \
    echo 'echo ""' >> /workspace/welcome.sh && \
    chmod +x /workspace/welcome.sh

# Create entrypoint script using echo commands
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Run startup scripts' >> /entrypoint.sh && \
    echo 'for script in /etc/workstation-startup.d/*.sh; do' >> /entrypoint.sh && \
    echo '    if [ -r "$script" ]; then' >> /entrypoint.sh && \
    echo '        echo "Running $(basename $script)..."' >> /entrypoint.sh && \
    echo '        . "$script" || true' >> /entrypoint.sh && \
    echo '    fi' >> /entrypoint.sh && \
    echo 'done' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Show welcome message' >> /entrypoint.sh && \
    echo '/workspace/welcome.sh || true' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Keep container running' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Add Midnight tools to PATH
ENV PATH="/opt/midnight/bin:${PATH}"

# Expose ports
EXPOSE 7681 8080 8443

# Set working directory
WORKDIR /workspace

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]