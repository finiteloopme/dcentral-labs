# Build stage
FROM rust:1.75 as builder

WORKDIR /app

# Copy Cargo files
COPY Cargo.toml Cargo.lock ./
COPY crates ./crates

# Build dependencies first (for better caching)
RUN cargo build --release --workspace

# Build the application
RUN cargo build --release --bin bitvm3-server

# Runtime stage
FROM debian:bookworm-slim

# Install required dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/target/release/bitvm3-server /app/

# Create data directory
RUN mkdir -p /app/data

# Expose ports
EXPOSE 3000 50051

# Run the server
CMD ["./bitvm3-server"]