# --- Stage 1: Builder ---
# This stage uses the official Rust image to compile our attestation server.
FROM rust:1-slim as builder

WORKDIR /usr/src/app

# Copy the server's source code and build it in release mode.
COPY attestation-server/ .
RUN cargo build --release

# --- Stage 2: Final Image ---
# This stage creates the final, lean image for our workload.
FROM debian:bookworm-slim

# Install necessary certificates for HTTPS communication.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the compiled Rust server binary from the builder stage.
COPY --from=builder /usr/src/app/target/release/attestation-server /usr/local/bin/

# Copy the Midnight proof server binary from its official image.
# COPY --from=midnightnetwork/proof-server:4.0.0 /usr/local/bin/midnight-proof-server /usr/local/bin/
# ARM
# COPY --from=midnightnetwork/proof-server:4.0.0 /nix/store/lp29qhv39shknjkcivv54xjfbygfd5by-ledger-4.0.0/bin/midnight-proof-server /usr/local/bin/
# AMD
COPY --from=midnightnetwork/proof-server:4.0.0 /nix/store/ahrfxbazglq2rh6vvyl3ffkcm230kxh1-ledger-4.0.0/bin/midnight-proof-server /usr/local/bin/


# Expose the port for the attestation server.
EXPOSE 8080

# Run both the Midnight proof server (background) and our attestation server (foreground).
# Using bash allows us to launch the proof server as a background process.
CMD ["/bin/bash", "-c", "/usr/local/bin/midnight-proof-server --network testnet --verbose & /usr/local/bin/attestation-server"]

