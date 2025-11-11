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

# Install Midnight Compact Tool
RUN curl --proto '=https' --tlsv1.2 -LsSf https://github.com/midnightntwrk/compact/releases/latest/download/compact-installer.sh | sh || true
ENV PATH="/root/.compact/bin:${PATH}"

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
RUN sudo mkdir -p /opt/midnight-dev/{logs,data,config} && \
    sudo chmod -R 755 /opt/midnight-dev

# Create Midnight Services Startup Script
COPY config/110_start-code-oss-custom.sh /etc/workstation-startup.d/110_start-code-oss-custom.sh
RUN sudo chmod +x /etc/workstation-startup.d/110_start-code-oss-custom.sh

COPY config/120_code-oss-port-config.sh /etc/workstation-startup.d/120_code-oss-port-config.sh
RUN sudo chmod +x /etc/workstation-startup.d/120_code-oss-port-config.sh

COPY config/200_midnight-services.sh /etc/workstation-startup.d/200_midnight-services.sh
RUN sudo chmod +x /etc/workstation-startup.d/200_midnight-services.sh

# Create Default Code OSS Settings for Midnight Development


# Configure Vertex AI and IDE environment
COPY config/220_vertex-ide-config.sh /etc/workstation-startup.d/220_vertex-ide-config.sh
RUN sudo chmod +x /etc/workstation-startup.d/220_vertex-ide-config.sh

# Copy Indexer Config
COPY config/indexer-simple.yaml /opt/midnight-dev/config/indexer-simple.yaml
COPY config/midnight-node-config.toml /opt/midnight-dev/config/midnight-node-config.toml

# Use Cloud Workstations entrypoint
ENTRYPOINT ["/google/scripts/entrypoint.sh"]