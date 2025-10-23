#!/usr/bin/env bash

# Example script demonstrating Phase 3 transaction tools via MCP
# This shows how to use the new encode_function_call, build_transaction, and export_for_signing tools

MCP_URL="http://localhost:3000/rpc"

echo "=== Phase 3: Transaction Tools Demo ==="
echo ""

# 1. Test encode_function_call with new generic encoding
echo "1. Testing encode_function_call tool..."
echo "----------------------------------------"

curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "encode_function_call",
      "arguments": {
        "signature": "transfer(address,uint256)",
        "parameters": ["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", "1000000000000000000"]
      }
    },
    "id": 1
  }' | jq '.result.content[0].text' -r | jq .

echo ""

# Test encoding a swap function
echo "Encoding a Uniswap swap function..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "encode_function_call",
      "arguments": {
        "signature": "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
        "parameters": [
          "1000000000000000000",
          "900000000000000000",
          ["0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"],
          "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
          "9999999999"
        ]
      }
    },
    "id": 2
  }' | jq '.result.content[0].text' -r | jq .

echo ""

# 2. Test decode_transaction
echo "2. Testing decode_transaction tool..."
echo "--------------------------------------"

# Decode a transfer transaction
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "decode_transaction",
      "arguments": {
        "data": "0xa9059cbb000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb70000000000000000000000000000000000000000000000000de0b6b3a7640000"
      }
    },
    "id": 3
  }' | jq '.result.content[0].text' -r | jq .

echo ""

# Decode an approval transaction
echo "Decoding an approval transaction..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "decode_transaction",
      "arguments": {
        "data": "0x095ea7b30000000000000000000000007a250d5630b4cf539739df2c5dacb4c659f2488d000000000000000000000000000000000000000000000000000000174876e800"
      }
    },
    "id": 4
  }' | jq '.result.content[0].text' -r | jq .

echo ""

# 3. Test build_transaction
echo "3. Testing build_transaction tool..."
echo "------------------------------------"

# Build a token transfer transaction
echo "Building ERC20 transfer transaction..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "build_transaction",
      "arguments": {
        "transaction_type": "transfer",
        "parameters": {
          "token_address": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
          "to": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
          "amount": "1000000000000000000",
          "from": "0x1234567890123456789012345678901234567890"
        }
      }
    },
    "id": 5
  }' | jq '.result.content[0].text' -r | jq .

echo ""

# Build an approval transaction
echo "Building approval transaction..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "build_transaction",
      "arguments": {
        "transaction_type": "approve",
        "parameters": {
          "token_address": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
          "spender": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
          "amount": "115792089237316195423570985008687907853269984665640564039457584007913129639935",
          "from": "0x1234567890123456789012345678901234567890"
        }
      }
    },
    "id": 6
  }' | jq '.result.content[0].text' -r | jq .

echo ""

# Build an ETH transfer transaction
echo "Building ETH transfer transaction..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "build_transaction",
      "arguments": {
        "transaction_type": "eth_transfer",
        "parameters": {
          "to": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
          "amount": "1000000000000000000",
          "from": "0x1234567890123456789012345678901234567890"
        }
      }
    },
    "id": 7
  }' | jq '.result.content[0].text' -r | jq .

echo ""

# Build a swap transaction
echo "Building Uniswap swap transaction..."
SWAP_RESULT=$(curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "build_transaction",
      "arguments": {
        "transaction_type": "swap",
        "parameters": {
          "router_address": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
          "amount_in": "1000000000000000000000",
          "amount_out_min": "300000000000000000",
          "path": ["0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"],
          "to": "0x1234567890123456789012345678901234567890",
          "deadline": "9999999999",
          "from": "0x1234567890123456789012345678901234567890"
        }
      }
    },
    "id": 8
  }')

echo "$SWAP_RESULT" | jq '.result.content[0].text' -r | jq .

# Extract the transaction object for export
TRANSACTION=$(echo "$SWAP_RESULT" | jq '.result.content[0].text' -r | jq '.transaction')

echo ""

# 4. Test export_for_signing
echo "4. Testing export_for_signing tool..."
echo "--------------------------------------"

# Export as raw JSON
echo "Exporting as raw JSON..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"export_for_signing\",
      \"arguments\": {
        \"transaction\": $TRANSACTION,
        \"format\": \"raw_json\"
      }
    },
    \"id\": 9
  }" | jq '.result.content[0].text' -r | jq .

echo ""

# Export as EIP-712 typed data
echo "Exporting as EIP-712 typed data..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"export_for_signing\",
      \"arguments\": {
        \"transaction\": $TRANSACTION,
        \"format\": \"eip712\"
      }
    },
    \"id\": 10
  }" | jq '.result.content[0].text' -r | jq '.data.primaryType, .data.domain'

echo ""

# Export as QR code data
echo "Exporting as QR code data..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"export_for_signing\",
      \"arguments\": {
        \"transaction\": $TRANSACTION,
        \"format\": \"qr_code\"
      }
    },
    \"id\": 11
  }" | jq '.result.content[0].text' -r | jq '.data.uri'

echo ""

# Export in all formats
echo "Exporting in all formats..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"export_for_signing\",
      \"arguments\": {
        \"transaction\": $TRANSACTION,
        \"format\": \"all\"
      }
    },
    \"id\": 12
  }" | jq '.result.content[0].text' -r | jq 'keys'

echo ""

# 5. Complete workflow example
echo "5. Complete Workflow: Swap DAI for ETH"
echo "---------------------------------------"

echo "Step 1: Using interpret_intent to understand user request..."
curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "interpret_intent",
      "arguments": {
        "intent": "I want to swap 1000 DAI for ETH on Uniswap"
      }
    },
    "id": 13
  }' | jq '.result.content[0].text' -r | jq '.category, .suggestions[0].protocol'

echo ""

echo "Step 2: Build approval transaction for DAI..."
APPROVE_TX=$(curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "build_transaction",
      "arguments": {
        "transaction_type": "approve",
        "parameters": {
          "token_address": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
          "spender": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
          "amount": "1000000000000000000000",
          "from": "0xUser0000000000000000000000000000000000"
        }
      }
    },
    "id": 14
  }' | jq '.result.content[0].text' -r | jq '.transaction')

echo "Approval transaction built ✓"

echo ""

echo "Step 3: Build swap transaction..."
SWAP_TX=$(curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "build_transaction",
      "arguments": {
        "transaction_type": "swap",
        "parameters": {
          "router_address": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
          "amount_in": "1000000000000000000000",
          "amount_out_min": "300000000000000000",
          "path": ["0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"],
          "to": "0xUser0000000000000000000000000000000000",
          "deadline": "9999999999",
          "from": "0xUser0000000000000000000000000000000000"
        }
      }
    },
    "id": 15
  }' | jq '.result.content[0].text' -r | jq '.transaction')

echo "Swap transaction built ✓"

echo ""

echo "Step 4: Export both transactions for MetaMask..."
echo "Batch transactions ready for signing:"
echo "  1. Approve DAI spending"
echo "  2. Swap DAI for ETH"
echo ""
echo "✅ Complete workflow ready for user signing!"

echo ""
echo "=== Demo Complete ===="