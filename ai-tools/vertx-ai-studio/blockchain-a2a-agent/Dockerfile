# Build Stage
FROM rust:1.85-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev cmake g++ && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
COPY src/ src/
RUN cargo build --release

# Runtime Stage
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/blockchain-a2a-agent .
EXPOSE 8080
CMD ["./blockchain-a2a-agent"]
