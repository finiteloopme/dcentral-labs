#!/usr/bin/env bash
# Test intent resolution via MCP protocol

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Server configuration
MCP_SERVER="${MCP_SERVER:-http://localhost:3000}"
SSE_ENDPOINT="${MCP_SERVER}/sse/message"

# Session ID for this client
SESSION_ID="intent-test-$(date +%s)"

echo -e "${BLUE}=== ABI Assistant Intent Resolution Tests ===${NC}\n"

# Function to send MCP request
send_request() {
    local method=$1
    local params=$2
    local id=$3
    
    echo -e "${YELLOW}Request:${NC} $method"
    
    curl -s -X POST "$SSE_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -d "{
            \"jsonrpc\": \"2.0\",
            \"method\": \"$method\",
            \"params\": $params,
            \"id\": $id
        }" | jq '.' || true
    
    echo
}

# 1. Initialize session
echo -e "${GREEN}1. Initializing MCP session...${NC}"
send_request "initialize" '{
    "protocolVersion": "0.1.0",
    "capabilities": {
        "tools": true
    },
    "clientInfo": {
        "name": "intent-resolution-test",
        "version": "1.0.0"
    }
}' 1

# 2. List available tools
echo -e "${GREEN}2. Listing available tools...${NC}"
send_request "tools/list" '{}' 2

# 3. Test intent interpretation with various examples
echo -e "${GREEN}3. Testing intent interpretation...${NC}\n"

# Example 1: Simple swap
echo -e "${BLUE}Example 1: Simple swap${NC}"
send_request "tools/call" '{
    "name": "interpret_intent",
    "arguments": {
        "intent": "swap 100 USDC for ETH"
    }
}' 3

# Example 2: Lending with specific protocol
echo -e "${BLUE}Example 2: Lending with protocol mention${NC}"
send_request "tools/call" '{
    "name": "interpret_intent",
    "arguments": {
        "intent": "lend 1000 DAI on Aave"
    }
}' 4

# Example 3: Complex intent with constraints
echo -e "${BLUE}Example 3: Complex intent with constraints${NC}"
send_request "tools/call" '{
    "name": "interpret_intent",
    "arguments": {
        "intent": "swap 500 USDC for ETH with 0.5% slippage on Uniswap"
    }
}' 5

# Example 4: Staking
echo -e "${BLUE}Example 4: Staking${NC}"
send_request "tools/call" '{
    "name": "interpret_intent",
    "arguments": {
        "intent": "stake 32 ETH for Ethereum 2.0"
    }
}' 6

# Example 5: Liquidity provision
echo -e "${BLUE}Example 5: Liquidity provision${NC}"
send_request "tools/call" '{
    "name": "interpret_intent",
    "arguments": {
        "intent": "provide liquidity with 1000 USDC and 0.3 ETH to Uniswap V3"
    }
}' 7

# Example 6: Multi-step operation
echo -e "${BLUE}Example 6: Multi-step operation${NC}"
send_request "tools/call" '{
    "name": "interpret_intent",
    "arguments": {
        "intent": "borrow 5000 USDC against my ETH collateral then swap half for DAI"
    }
}' 8

# 4. Test with different confidence thresholds
echo -e "${GREEN}4. Testing ambiguous intents...${NC}\n"

echo -e "${BLUE}Ambiguous intent:${NC}"
send_request "tools/call" '{
    "name": "interpret_intent",
    "arguments": {
        "intent": "do something with my tokens"
    }
}' 9

# 5. Test parameter extraction
echo -e "${GREEN}5. Testing parameter extraction...${NC}\n"

echo -e "${BLUE}Intent with multiple parameters:${NC}"
send_request "tools/call" '{
    "name": "interpret_intent",
    "arguments": {
        "intent": "swap exactly 123.456 USDC for at least 0.05 ETH with 1% slippage before block 12345678"
    }
}' 10

echo -e "${GREEN}✓ Intent resolution tests complete!${NC}"