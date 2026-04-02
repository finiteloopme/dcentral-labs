# Multi-stage build for ABI Assistant - Platform Agnostic
# This Dockerfile works across all platforms: local, GCP Cloud Run, AWS ECS, etc.

# Build stage - Using latest stable Rust
FROM docker.io/rust:latest AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy Cargo files for dependency caching
COPY Cargo.toml Cargo.lock* ./

# Pre-build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy source code
COPY src ./src
COPY resources ./resources

# Build application
RUN touch src/main.rs && cargo build --release

# Runtime stage - lightweight and secure
FROM docker.io/debian:bookworm-slim

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    sqlite3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 -s /bin/bash appuser

# Copy artifacts from builder
COPY --from=builder /app/target/release/abi-assistant /usr/local/bin/
COPY --from=builder /app/resources /app/resources

# Create data directory with proper permissions
RUN mkdir -p /data /tmp && \
    chown -R appuser:appuser /data /tmp /app

# Create flexible entrypoint script
RUN cat <<'EOF' > /usr/local/bin/docker-entrypoint.sh
#!/bin/bash
set -e

# Handle platform-specific PORT variable (Cloud Run, Heroku, etc.)
if [ -n "$PORT" ]; then
    export MCP_PORT="${MCP_PORT:-$PORT}"
fi

# Set default values if not provided
export MCP_PORT="${MCP_PORT:-3000}"
export MCP_HOST="${MCP_HOST:-0.0.0.0}"
export MCP_TRANSPORT="${MCP_TRANSPORT:-unified}"
export DATABASE_URL="${DATABASE_URL:-sqlite:///data/abi_assistant.db}"
export RUST_LOG="${RUST_LOG:-info}"

# Initialize database if needed
if [ ! -f "/data/abi_assistant.db" ] && [[ "$DATABASE_URL" == sqlite:///data/* ]]; then
    echo "Initializing database..."
    mkdir -p /data
    touch /data/abi_assistant.db
fi

# Execute the application
exec abi-assistant "$@"
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to non-root user
USER appuser
WORKDIR /app

# Default environment variables (can be overridden)
ENV RUST_LOG=info \
    DATABASE_URL=sqlite:///data/abi_assistant.db \
    MCP_HOST=0.0.0.0 \
    MCP_PORT=3000 \
    MCP_TRANSPORT=unified

# Expose both standard ports (platforms will map as needed)
EXPOSE 3000 8080

# Health check (works across platforms)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${MCP_PORT:-3000}/health || exit 1

# Use entrypoint script for flexibility
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]