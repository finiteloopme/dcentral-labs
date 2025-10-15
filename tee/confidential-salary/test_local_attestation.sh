#!/bin/bash

# Test attestation locally

echo "Starting local server for testing..."

# Kill any existing server
pkill -f "target/release/server" 2>/dev/null || true

# Start server in background
cd /home/kunall/scratchpad/dcentral-labs/tee/confidential-salary
RUST_LOG=debug TDX_ENABLED=1 ./target/release/server &
SERVER_PID=$!

# Wait for server to start
sleep 3

echo "Testing attestation endpoint..."

# Create a proper JSON request with nonce as byte array
curl -v -X POST http://localhost:8080/attest \
  -H "Content-Type: application/json" \
  -d '{"nonce": [1,2,3,4,5,6,7,8,9,10,11,12]}' \
  2>&1 | grep -E "< x-session-id:|< X-Session-Id:|{" | head -20

echo ""
echo "Stopping server..."
kill $SERVER_PID 2>/dev/null || true

echo "Done"