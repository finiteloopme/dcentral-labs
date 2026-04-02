## Stage 1: Build the Rust binary
FROM rust:1.85-slim-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config libssl-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY src/ src/

RUN cargo build --release

## Stage 2: Minimal runtime image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/cs-hello-world /usr/local/bin/cs-hello-world

# Confidential Space launch policies:
# - Allow the operator to pass ENVIRONMENT via tee-env-ENVIRONMENT metadata
# - Allow the operator to redirect container logs to Cloud Logging
LABEL "tee.launch_policy.allow_env_override"="ENVIRONMENT"
LABEL "tee.launch_policy.log_redirect"="always"

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/cs-hello-world"]
