#!/bin/bash

# Test attestation endpoint directly

SERVER_URL="${1:-http://localhost:8080}"

echo "Testing attestation at $SERVER_URL"
echo ""

# Generate a test nonce
NONCE=$(echo -n "test-nonce-123" | base64)

echo "1. Testing health endpoint..."
curl -s "$SERVER_URL/health" | jq . || echo "Health check failed"
echo ""

echo "2. Testing attestation endpoint..."
echo "Sending nonce: $NONCE"
echo ""

# Make attestation request and capture headers
RESPONSE=$(curl -s -i -X POST "$SERVER_URL/attest" \
  -H "Content-Type: application/json" \
  -d "{\"nonce\": \"$NONCE\"}")

echo "Full response:"
echo "$RESPONSE" | head -20
echo ""

# Extract headers
echo "Headers:"
echo "$RESPONSE" | sed -n '1,/^\r$/p'
echo ""

# Extract body
echo "Body (first 500 chars):"
echo "$RESPONSE" | sed '1,/^\r$/d' | head -c 500
echo ""

# Check for session ID header
if echo "$RESPONSE" | grep -i "x-session-id"; then
    echo "✓ Session ID header found"
else
    echo "✗ Session ID header NOT found"
fi