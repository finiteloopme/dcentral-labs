FROM rust:latest as builder

WORKDIR /app

# Copy Cargo files
COPY ../tee-service/Cargo.toml ../tee-service/Cargo.lock ./

# Create dummy main.rs to cache dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# Copy source code
COPY ../tee-service/src ./src

# Build the application
RUN cargo build --release

# Runtime image
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -r -s /bin/false teeuser

# Copy binary
COPY --from=builder /app/target/release/tee-service /usr/local/bin/tee-service

# Set permissions
RUN chmod +x /usr/local/bin/tee-service

# Switch to non-root user (commented out for debugging)
# USER teeuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Run the application
CMD ["tee-service"]