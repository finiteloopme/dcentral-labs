# =========================================
# Midnight Vibe Platform - Cloud Workstations Image
# =========================================
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install Midnight Platform Dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    curl git build-essential pkg-config libssl-dev jq unzip \
    postgresql postgresql-contrib \
    supervisor \
    && sudo apt-get clean

# Install Rust Toolchain
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo PATH=/usr/local/cargo/bin:$PATH
RUN sudo mkdir -p $RUSTUP_HOME $CARGO_HOME && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo sh -s -- -y --no-modify-path && \
    sudo chmod -R a+w $RUSTUP_HOME $CARGO_HOME

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
    sudo apt-get install -y nodejs

# Install Midnight Binaries
COPY --from=midnightnetwork/proof-server:latest /nix/store/ahrfxbazglq2rh6vvyl3ffkcm230kxh1-ledger-4.0.0/bin/midnight-proof-server /usr/local/bin/
COPY --from=midnightnetwork/midnight-node:latest /midnight-node /usr/local/bin/
COPY --from=midnightntwrk/indexer-standalone:latest /usr/local/bin/indexer-standalone /usr/local/bin/midnight-indexer-standalone

RUN sudo chmod +x /usr/local/bin/midnight-proof-server \
                  /usr/local/bin/midnight-node \
                  /usr/local/bin/midnight-indexer-standalone

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

# Setup PostgreSQL
RUN sudo mkdir -p /var/lib/postgresql/data && \
    sudo chown -R postgres:postgres /var/lib/postgresql && \
    sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/data && \
    echo "host all  all    127.0.0.1/32  trust" | sudo tee -a /var/lib/postgresql/data/pg_hba.conf && \
    echo "listen_addresses='*'" | sudo tee -a /var/lib/postgresql/data/postgresql.conf

# Create Midnight Services Startup Script
COPY config/110_start-code-oss-custom.sh /etc/workstation-startup.d/110_start-code-oss-custom.sh
RUN sudo chmod +x /etc/workstation-startup.d/110_start-code-oss-custom.sh

COPY config/120_code-oss-port-config.sh /etc/workstation-startup.d/120_code-oss-port-config.sh
RUN sudo chmod +x /etc/workstation-startup.d/120_code-oss-port-config.sh

COPY config/200_midnight-services.sh /etc/workstation-startup.d/200_midnight-services.sh
RUN sudo chmod +x /etc/workstation-startup.d/200_midnight-services.sh

# Create Default Code OSS Settings for Midnight Development
COPY config/210_default-ide-settings.sh /etc/workstation-startup.d/210_default-ide-settings.sh
RUN sudo chmod +x /etc/workstation-startup.d/210_default-ide-settings.sh

# Configure Vertex AI and IDE environment
COPY config/220_vertex-ide-config.sh /etc/workstation-startup.d/220_vertex-ide-config.sh
RUN sudo chmod +x /etc/workstation-startup.d/220_vertex-ide-config.sh

# Copy Indexer Config
COPY config/indexer-config.yaml /tmp/indexer-config.yaml
COPY config/midnight-node-config.toml /tmp/midnight-node-config.toml

# Use Cloud Workstations entrypoint
ENTRYPOINT ["/google/scripts/entrypoint.sh"]