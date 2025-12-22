# Midnight GenAI Development Platform
#
# Base image: Cloud Workstations Code OSS
# Includes: Compact compiler, Midnight CLI, midnight-node-toolkit, gcloud SDK
#
# Requires pre-built SDK image: make build-sdk
# The SDK image contains /opt/vendor with Midnight SDK 3.x packages built from source.

# ==============================================================================
# BUILD ARGS
# ==============================================================================
ARG SDK_IMAGE=midnight-sdk:latest
ARG MIDNIGHT_TOOLKIT_VERSION=0.18.0

# ==============================================================================
# Stage: sdk - Pre-built SDK packages
# ==============================================================================
FROM ${SDK_IMAGE} AS sdk

# ==============================================================================
# Stage: toolkit - Extract midnight-node-toolkit binary
# ==============================================================================
FROM docker.io/midnightntwrk/midnight-node-toolkit:${MIDNIGHT_TOOLKIT_VERSION} AS toolkit

# ==============================================================================
# Stage: final - Production image
# ==============================================================================
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

USER root

# System dependencies (suppress mandb warnings from base image permission issues)
RUN apt-get update && apt-get install -y \
    curl git build-essential libssl-dev pkg-config unzip jq netcat-openbsd \
    xz-utils sudo \
    2>&1 | grep -v "mandb" || true \
    && rm -rf /var/lib/apt/lists/*

# Update npm and install global packages
RUN npm install -g npm@latest typescript ts-node turbo

# Environment
ENV COMPACT_HOME="/usr/local/share/compact"
ENV PATH="${COMPACT_HOME}:${PATH}"
ENV CHAIN_ENVIRONMENT="standalone"
ENV MIDNIGHT_NETWORK="standalone"
ENV MIDNIGHT_TOOLKIT_PATH="/usr/local/bin/midnight-node-toolkit"

# OpenCode configuration
# Uses Vertex AI with workstation service account for authentication (ADC)
# GOOGLE_CLOUD_PROJECT is set by Cloud Workstations automatically
ENV VERTEX_LOCATION="global"

# Copy toolkit binary from the toolkit image
COPY --from=toolkit /midnight-node-toolkit ${MIDNIGHT_TOOLKIT_PATH}
RUN chmod +x ${MIDNIGHT_TOOLKIT_PATH}

# Container customization (installs Compact, configures Code OSS, etc.)
COPY container-scripts/ /tmp/container-scripts/
RUN chmod +x /tmp/container-scripts/main.sh && /tmp/container-scripts/main.sh

# ==============================================================================
# Vendor packages - Midnight SDK 3.x (from pre-built SDK image)
# ==============================================================================
COPY --from=sdk /opt/vendor /opt/vendor

# Debug: Show what packages are available
RUN echo "=== Vendor packages ===" && \
    cat /opt/vendor/manifest.txt 2>/dev/null || \
    find /opt/vendor -name "package.json" -exec dirname {} \; | sort

# ------------------------------------------------------------------------------
# Patch missing dependencies in wallet-sdk packages
# 
# Some wallet-sdk packages import @midnight-ntwrk/wallet-sdk-runtime but don't
# declare it as a dependency in their package.json. This works in the Yarn
# monorepo due to hoisting, but fails with npm install. We patch the missing
# dependency before running npm install.
# ------------------------------------------------------------------------------
RUN echo "=== Patching missing wallet-sdk-runtime dependency ===" && \
    for pkg in unshielded-wallet dust-wallet; do \
        pkgfile="/opt/vendor/wallet/$pkg/package.json"; \
        if [ -f "$pkgfile" ]; then \
            echo "Patching: $pkgfile"; \
            jq '.dependencies["@midnight-ntwrk/wallet-sdk-runtime"] = "file:/opt/vendor/wallet/runtime"' "$pkgfile" > "$pkgfile.tmp" && \
            mv "$pkgfile.tmp" "$pkgfile"; \
        fi; \
    done && \
    echo "=== Patching complete ==="

# ------------------------------------------------------------------------------
# Install production dependencies in vendor packages
# 
# ESM module resolution requires dependencies to be in the package's own
# node_modules or an ancestor directory. Since vendor packages are symlinked
# from /opt/midnight-cli/node_modules, their transitive deps (like 'effect')
# are not found. This step installs each vendor package's dependencies locally.
# ------------------------------------------------------------------------------
RUN echo "=== Installing production dependencies in vendor packages ===" && \
    for pkgdir in /opt/vendor/wallet/* /opt/vendor/js/* /opt/vendor/compact-js/*; do \
        if [ -f "$pkgdir/package.json" ]; then \
            echo "Installing deps in: $pkgdir"; \
            cd "$pkgdir" && \
            npm install --production --ignore-scripts --no-audit --no-fund 2>&1 | tail -5 || true; \
        fi; \
    done && \
    echo "=== Vendor dependency installation complete ==="

# ------------------------------------------------------------------------------
# Deduplicate ledger-v6 across all vendor packages
#
# npm install creates separate copies of ledger-v6 in each package's node_modules.
# This causes class identity issues (DustParameters from one copy isn't recognized
# by DustWallet from another copy). We replace all copies with symlinks to the
# canonical ledger-v6 at /opt/vendor/ledger/ledger-v6.
# ------------------------------------------------------------------------------
RUN echo "=== Deduplicating ledger-v6 across vendor packages ===" && \
    CANONICAL_LEDGER="/opt/vendor/ledger/ledger-v6" && \
    find /opt/vendor -path "*/node_modules/@midnight-ntwrk/ledger-v6" -type d | while read ledger_copy; do \
        if [ "$ledger_copy" != "$CANONICAL_LEDGER" ]; then \
            echo "Replacing $ledger_copy with symlink to $CANONICAL_LEDGER"; \
            rm -rf "$ledger_copy" && \
            ln -s "$CANONICAL_LEDGER" "$ledger_copy"; \
        fi; \
    done && \
    echo "=== ledger-v6 deduplication complete ==="

# ==============================================================================
# Midnight CLI
# ==============================================================================
COPY cli/ /opt/midnight-cli/

# Install CLI dependencies and build
# package.json uses file:/opt/vendor/... references
RUN cd /opt/midnight-cli && npm install && npm run build && \
    chmod +x /opt/midnight-cli/dist/index.js

# ------------------------------------------------------------------------------
# Final ledger-v6 deduplication (after CLI install)
#
# CLI npm install may create additional ledger-v6 copies in the CLI's node_modules
# or reinstall them in vendor packages. Run deduplication again to ensure only
# one copy exists (prevents DustParameters class identity issues).
# ------------------------------------------------------------------------------
RUN echo "=== Final ledger-v6 deduplication ===" && \
    CANONICAL_LEDGER="/opt/vendor/ledger/ledger-v6" && \
    find /opt/midnight-cli/node_modules /opt/vendor -path "*/node_modules/@midnight-ntwrk/ledger-v6" -type d 2>/dev/null | while read ledger_copy; do \
        if [ "$ledger_copy" != "$CANONICAL_LEDGER" ]; then \
            echo "Replacing $ledger_copy with symlink to $CANONICAL_LEDGER"; \
            rm -rf "$ledger_copy" && \
            ln -s "$CANONICAL_LEDGER" "$ledger_copy"; \
        fi; \
    done && \
    echo "=== Final ledger-v6 deduplication complete ==="

# Environment setup script
COPY .devcontainer/setup-env.sh /opt/midnight-cli/setup-env.sh
RUN chmod +x /opt/midnight-cli/setup-env.sh

# Fix home directory ownership
RUN chown -R ubuntu:ubuntu /home/ubuntu
