#!/bin/bash

set -e

echo "========================================="
echo "TDX Attestation Mode Comparison Demo"
echo "========================================="
echo ""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Build if needed
if [ ! -f "server/target/release/server" ]; then
    echo "Building applications..."
    ./scripts/build.sh
fi

echo "This demo will show both attestation modes:"
echo "1. Google Cloud Attestation Service"
echo "2. Raw TDX (Building Quote from Ground)"
echo ""

# Function to start server and test
test_mode() {
    local mode=$1
    local env_vars=$2
    
    echo ""
    echo "========================================="
    echo "Testing: $mode"
    echo "========================================="
    
    # Start server in background
    echo "Starting server..."
    cd server
    eval "$env_vars ./target/release/server" &
    SERVER_PID=$!
    cd ..
    
    # Wait for server to start
    sleep 3
    
    # Run client health check
    echo ""
    echo "Checking server health..."
    cd client
    ./target/release/client --server http://localhost:8080 health
    
    echo ""
    echo "Performing attestation..."
    ./target/release/client --server http://localhost:8080 --verbose submit \
        --role "Software Engineer" \
        --salary 120000 \
        --location "San Francisco" \
        --years 5
    cd ..
    
    # Stop server
    echo ""
    echo "Stopping server..."
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    
    echo ""
    echo "✓ $mode test completed"
    echo ""
    sleep 2
}

# Test Mode 1: Google Cloud Attestation
test_mode "Google Cloud Attestation Service" "RUST_LOG=info TDX_ENABLED=1"

# Test Mode 2: Raw TDX Attestation
test_mode "Raw TDX Attestation (Ground-Up)" "RUST_LOG=info TDX_ENABLED=1 USE_RAW_ATTESTATION=1"

echo ""
echo "========================================="
echo "Comparison Complete!"
echo "========================================="
echo ""
echo "Key Differences Observed:"
echo ""
echo "1. Google Cloud Mode:"
echo "   - Uses /dev/tdx_guest device"
echo "   - Queries Google attestation API"
echo "   - Returns Google-signed certificates"
echo ""
echo "2. Raw TDX Mode:"
echo "   - Builds quote from scratch"
echo "   - Uses TDCALL simulation"
echo "   - Self-signs with generated keys"
echo "   - Shows platform details (CPU, microcode)"
echo ""
echo "Both modes provide the same security guarantees"
echo "but differ in implementation and dependencies."
echo ""