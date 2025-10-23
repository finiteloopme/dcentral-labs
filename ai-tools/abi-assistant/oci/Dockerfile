# Multi-stage build for ABI Assistant
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

# Copy Cargo files first for better caching
COPY Cargo.toml Cargo.lock* ./

# Create dummy main.rs to build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies only
RUN cargo build --release && rm -rf src

# Copy actual source code
COPY src ./src
COPY resources ./resources

# Build the actual application
RUN touch src/main.rs && cargo build --release

# Runtime stage
FROM docker.io/debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 -s /bin/bash abi-assistant

# Copy binary from builder
COPY --from=builder /app/target/release/abi-assistant /usr/local/bin/

# Create data directories
RUN mkdir -p /data /logs && \
    chown -R abi-assistant:abi-assistant /data /logs

# Switch to non-root user
USER abi-assistant

# Set working directory
WORKDIR /home/abi-assistant

# Expose MCP server port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Default command
CMD ["abi-assistant"]