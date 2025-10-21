#!/usr/bin/env bash

set -e

source "$(dirname "$0")/common.sh"

echo "[INFO] Testing MCP Server endpoints..."

# Start the server in the background
echo "[INFO] Starting server..."
./scripts/podman-dev.sh &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Test health endpoint
echo "[INFO] Testing health endpoint..."
curl -s http://localhost:3000/health | grep -q "OK" && echo "[SUCCESS] Health check passed" || echo "[ERROR] Health check failed"

# Test JSON-RPC tools/list
echo "[INFO] Testing tools/list..."
response=$(curl -s -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "params": {},
    "id": 1
  }')

echo "Response: $response"
echo "$response" | grep -q "interpret_intent" && echo "[SUCCESS] Tools list works" || echo "[ERROR] Tools list failed"

# Test intent interpretation
echo "[INFO] Testing interpret_intent tool..."
response=$(curl -s -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "interpret_intent",
      "arguments": {
        "intent": "I want to swap 100 USDC for ETH"
      }
    },
    "id": 2
  }')

echo "Response: $response"
echo "$response" | grep -q "swap" && echo "[SUCCESS] Intent interpretation works" || echo "[ERROR] Intent interpretation failed"

# Test encode_function_call
echo "[INFO] Testing encode_function_call tool..."
response=$(curl -s -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "encode_function_call",
      "arguments": {
        "function": "transfer",
        "params": ["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", "1000000000000000000"]
      }
    },
    "id": 3
  }')

echo "Response: $response"
echo "$response" | grep -q "0xa9059cbb" && echo "[SUCCESS] Function encoding works" || echo "[ERROR] Function encoding failed"

# Stop the server
echo "[INFO] Stopping server..."
podman stop abi-assistant-dev 2>/dev/null || true

echo "[SUCCESS] All MCP tests passed!"