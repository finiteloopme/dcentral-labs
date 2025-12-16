# Base image
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    curl git build-essential libssl-dev pkg-config unzip jq \
    python3-pip \
    podman \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js global packages (Node.js & yarn already in base image)
RUN npm install -g typescript ts-node

# Copy and run customization scripts
COPY container-scripts/ /tmp/container-scripts/

ENV COMPACT_HOME="/usr/local/share/compact"
ENV PATH="${COMPACT_HOME}:${PATH}"

RUN /tmp/container-scripts/install/podman.sh && \
    /tmp/container-scripts/install/compact.sh && \
    /tmp/container-scripts/configure/codeoss.sh && \
    cp /tmp/container-scripts/profile.d/* /etc/profile.d/ && \
    chmod +x /etc/profile.d/compact.sh && \
    rm -rf /tmp/container-scripts

# Fix home directory ownership (ubuntu user exists in base image)
RUN chown -R ubuntu:ubuntu /home/ubuntu
