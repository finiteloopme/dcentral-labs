#!/bin/bash

set -e

echo "========================================="
echo "Deterministic Build for TDX MRTD"
echo "========================================="
echo ""
echo "This script ensures reproducible builds for consistent MRTD measurements"
echo ""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Set deterministic build environment variables
export SOURCE_DATE_EPOCH=1700000000  # Fixed timestamp: Nov 14, 2023
export TZ=UTC
export LC_ALL=C
export LANG=C

# Rust-specific deterministic settings
export RUSTFLAGS="-C link-arg=-Wl,--build-id=none -C link-arg=-Wl,--hash-style=gnu"
export CARGO_CFG_DISABLE_RNG_SEEDING=1

# Create a Docker container for fully reproducible environment
cat > Dockerfile.deterministic <<'EOF'
FROM rust:1.75.0-slim-bookworm

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    gcc \
    libc6-dev \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set deterministic environment
ENV SOURCE_DATE_EPOCH=1700000000
ENV TZ=UTC
ENV LC_ALL=C
ENV LANG=C
ENV RUSTFLAGS="-C link-arg=-Wl,--build-id=none -C link-arg=-Wl,--hash-style=gnu -C opt-level=3 -C codegen-units=1"

WORKDIR /build
EOF

echo "Building Docker image for deterministic builds..."
docker build -f Dockerfile.deterministic -t tdx-deterministic-builder .

echo ""
echo "Building server in deterministic environment..."
docker run --rm \
    -v "$PWD:/build" \
    -e SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH \
    tdx-deterministic-builder \
    bash -c "cd /build && cargo build --release --manifest-path server/Cargo.toml"

echo ""
echo "Calculating measurements..."

# Calculate SHA-384 hash of the binary (simulating MRTD)
SERVER_BINARY="server/target/release/server"
if [ -f "$SERVER_BINARY" ]; then
    # Strip non-deterministic sections
    cp "$SERVER_BINARY" "$SERVER_BINARY.stripped"
    strip --strip-all "$SERVER_BINARY.stripped" 2>/dev/null || true
    
    # Calculate MRTD (SHA-384 of the binary)
    MRTD=$(sha384sum "$SERVER_BINARY.stripped" | cut -d' ' -f1)
    
    # Also calculate SHA-256 for comparison
    SHA256=$(sha256sum "$SERVER_BINARY.stripped" | cut -d' ' -f1)
    
    # Get file size
    SIZE=$(stat -c%s "$SERVER_BINARY.stripped")
    
    echo "========================================="
    echo "Build Measurements:"
    echo "========================================="
    echo "Binary: $SERVER_BINARY"
    echo "Size: $SIZE bytes"
    echo "SHA-256: $SHA256"
    echo "MRTD (SHA-384): ${MRTD:0:64}..."
    echo ""
    
    # Save measurements to file
    cat > measurements.json <<EOF
{
    "binary": "server/target/release/server",
    "size": $SIZE,
    "sha256": "$SHA256",
    "mrtd": "$MRTD",
    "build_timestamp": $SOURCE_DATE_EPOCH,
    "rust_version": "1.75.0",
    "build_flags": "$RUSTFLAGS"
}
EOF
    
    echo "Measurements saved to measurements.json"
    
    # Clean up
    rm -f "$SERVER_BINARY.stripped"
else
    echo "Error: Server binary not found!"
    exit 1
fi

echo ""
echo "✓ Deterministic build complete!"
echo ""
echo "To verify MRTD matches across builds:"
echo "1. Run this script on different machines"
echo "2. Compare the MRTD values"
echo "3. They should be identical if the source code hasn't changed"
echo ""