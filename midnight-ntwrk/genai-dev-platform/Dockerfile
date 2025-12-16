# =========================================
# Midnight Vibe Platform - Cloud Workstations Image
# =========================================
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install Midnight Platform Dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    curl git build-essential pkg-config libssl-dev jq unzip \
    netcat-openbsd procps \
    && sudo apt-get clean

# Install Rust Toolchain
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo PATH=/usr/local/cargo/bin:$PATH
RUN sudo mkdir -p $RUSTUP_HOME $CARGO_HOME && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo sh -s -- -y --no-modify-path && \
    sudo chmod -R a+w $RUSTUP_HOME $CARGO_HOME

# Install Node.js and Java 22
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
    sudo apt-get install -y nodejs && \
    sudo wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo apt-key add - && \
    sudo echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list && \
    sudo apt-get update && sudo apt-get install -y temurin-22-jdk && \
    sudo update-alternatives --set java /usr/lib/jvm/temurin-22-jdk-amd64/bin/java

# Install Midnight Binaries (stable versions from example)
# Copy proof-server with Nix dependencies (try newer 4.0.0 version)
COPY --from=midnightnetwork/proof-server:4.0.0 /nix/store/ /usr/local/nix/store/
COPY --from=midnightnetwork/midnight-node:0.8.0 /midnight-node /usr/local/bin/
COPY --from=midnightnetwork/midnight-node:0.8.0 /res/ /usr/local/bin/res/
COPY --from=midnightnetwork/midnight-pubsub-indexer:2.3.0 /midnight-indexer/ /usr/local/bin/midnight-indexer/

# Find and move proof-server binary to correct location
RUN sudo find /usr/local/nix/store -name "*proof-server*" -type f -executable | head -1 | xargs -I {} sudo cp {} /usr/local/bin/midnight-proof-server && \
    sudo chmod +x /usr/local/bin/midnight-proof-server \
                   /usr/local/bin/midnight-node \
                   /usr/local/bin/midnight-indexer/bin/midnight-pubsub-indexer-server && \
    sudo ln -sf /usr/local/bin/midnight-indexer/opentelemetry-javaagent /usr/local/opentelemetry-javaagent && \
    sudo ln -sf /usr/local/bin/midnight-indexer/bin/midnight-pubsub-indexer-server /usr/local/bin/midnight-pubsub-indexer

# Install Midnight development tools and utilities
RUN sudo apt-get update && sudo apt-get install -y \
    netcat-openbsd \
    procps \
    curl \
    jq \
    && sudo apt-get clean

# Install Midnight Compact Tool for npm-based development workflow
RUN curl --proto '=https' --tlsv1.2 -LsSf https://github.com/midnightntwrk/compact/releases/latest/download/compact-installer.sh | sh && \
    sudo mv /root/.local/bin/compact /usr/local/bin/compact && \
    sudo chmod +x /usr/local/bin/compact && \
    sudo -u root compact update 0.25.0 && \
    # Copy compactc binary to system-wide PATH for npm scripts
    sudo cp /root/.compact/versions/0.25.0/x86_64-unknown-linux-musl/compactc /usr/local/bin/compactc && \
    sudo cp /root/.compact/versions/0.25.0/x86_64-unknown-linux-musl/compactc.bin /usr/local/bin/compactc.bin && \
    sudo chmod +x /usr/local/bin/compactc /usr/local/bin/compactc.bin && \
    # Create system-wide compact configuration for npm workflow
    sudo mkdir -p /usr/local/share/compact && \
    sudo cp -r /root/.compact/* /usr/local/share/compact/ && \
    sudo chmod -R 755 /usr/local/share/compact && \
    # Create npm configuration template for Midnight development
    sudo mkdir -p /etc/skel && \
    echo '# Midnight Development Configuration' | sudo tee /etc/skel/.npmrc && \
    echo 'script-shell=/bin/bash' | sudo tee -a /etc/skel/.npmrc && \
    sudo chmod 644 /etc/skel/.npmrc

# Install OpenCode AI Assistant to system-wide location
RUN mkdir -p /usr/local/opencode && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; fi && \
    curl -L "https://github.com/sst/opencode/releases/latest/download/opencode-linux-${ARCH}.zip" -o /tmp/opencode.zip && \
    unzip -p /tmp/opencode.zip opencode > /usr/local/opencode/opencode && \
    chmod +x /usr/local/opencode/opencode && \
    rm /tmp/opencode.zip
ENV PATH="/usr/local/opencode:${PATH}"

# Create Midnight development directories
RUN sudo mkdir -p /opt/midnight-dev/{logs,data,config,bin} && \
    sudo chmod -R 755 /opt/midnight-dev

# Copy Midnight configuration files to temp location for runtime setup
COPY config/ /tmp/midnight-config/

# Copy Midnight startup scripts following Cloud Workstations conventions
COPY config/110_start-code-oss-custom.sh /etc/workstation-startup.d/110_start-code-oss-custom.sh
COPY config/120_code-oss-port-config.sh /etc/workstation-startup.d/120_code-oss-port-config.sh
COPY config/130_vscode-extensions.sh /etc/workstation-startup.d/130_vscode-extensions.sh
COPY config/220_vertex-ide-config.sh /etc/workstation-startup.d/220_vertex-ide-config.sh
COPY config/230_opencode-user-config.sh /etc/workstation-startup.d/230_opencode-user-config.sh

# Midnight platform setup script (runs after user creation)
COPY config/300_midnight-setup.sh /etc/workstation-startup.d/300_midnight-setup.sh

# Copy Midnight Developer Helper (npm-based workflow)
COPY config/midnight-dev-helper /usr/local/bin/midnight-dev

# Make all startup scripts executable
RUN sudo chmod +x /etc/workstation-startup.d/*.sh && \
    sudo chmod +x /usr/local/bin/midnight-dev && \
    # Fix home directory permissions for ubuntu user to allow compact setup
    sudo mkdir -p /home/ubuntu && \
    sudo chown -R ubuntu:ubuntu /home/ubuntu && \
    sudo chmod 755 /home/ubuntu

# Use Cloud Workstations entrypoint
ENTRYPOINT ["/google/scripts/entrypoint.sh"]