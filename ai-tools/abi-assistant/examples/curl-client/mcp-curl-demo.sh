#!/usr/bin/env bash

# =============================================================================
# MCP Server cURL Demo - Complete Examples for ABI Assistant
# =============================================================================
# This script demonstrates all available MCP server endpoints using curl
# Works with the unified transport mode (both SSE and HTTP on same port)
# =============================================================================

set -e

# Configuration
SERVER_URL="${MCP_SERVER_URL:-http://127.0.0.1:3000}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_section() {
    echo -e "\n${YELLOW}▶ $1${NC}"
    echo -e "${YELLOW}$(printf '%.0s─' {1..60})${NC}"
}

execute_curl() {
    local description="$1"
    local curl_cmd="$2"
    
    echo -e "${GREEN}📝 ${description}${NC}"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${MAGENTA}Command:${NC}"
        echo "$curl_cmd"
    fi
    
    echo -e "${CYAN}Response:${NC}"
    eval "$curl_cmd" 2>/dev/null | jq '.' 2>/dev/null || eval "$curl_cmd" 2>/dev/null
    echo ""
}

check_server() {
    if ! curl -s "$SERVER_URL/health" > /dev/null 2>&1; then
        echo -e "${RED}❌ MCP Server is not running on $SERVER_URL${NC}"
        echo -e "${YELLOW}Please start the server with: cd ../.. && cargo run${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ MCP Server is running on $SERVER_URL${NC}"
}

# =============================================================================
# Main Demo Script
# =============================================================================

print_header "ABI Assistant MCP Server - cURL Demo"

echo -e "${BOLD}This demo showcases all MCP server capabilities using curl${NC}"
echo -e "Server URL: ${CYAN}$SERVER_URL${NC}"
echo -e "Transport: ${CYAN}Unified (SSE + HTTP on same port)${NC}"
echo ""

# Check if server is running
check_server

# =============================================================================
# 1. BASIC CONNECTIVITY
# =============================================================================

print_section "1. BASIC CONNECTIVITY"

execute_curl "Health Check" \
    "curl -s $SERVER_URL/health"

# =============================================================================
# 2. SSE (SERVER-SENT EVENTS) CONNECTION
# =============================================================================

print_section "2. SSE ENDPOINTS - Real-time Streaming"

echo -e "${GREEN}📝 Testing SSE connection (GET /sse)${NC}"
echo -e "${CYAN}Response (first 3 lines):${NC}"
timeout 1 curl -N "$SERVER_URL/sse" 2>/dev/null | head -3 || echo "SSE stream timeout (normal behavior)"
echo ""

# Get session ID for SSE
echo -e "${GREEN}📝 Getting SSE session ID${NC}"
SESSION_ID=$(timeout 1 curl -s -N "$SERVER_URL/sse" 2>/dev/null | grep -oP 'sessionId=\K[^&]+' | head -1)
if [ -n "$SESSION_ID" ]; then
    echo -e "${CYAN}Session ID: $SESSION_ID${NC}"
else
    echo -e "${YELLOW}Could not extract session ID (SSE may need initialization)${NC}"
fi
echo ""

# =============================================================================
# 3. MCP INITIALIZATION
# =============================================================================

print_section "3. MCP PROTOCOL INITIALIZATION"

# For SSE endpoints, we need to send to the message endpoint with session ID
if [ -n "$SESSION_ID" ]; then
    execute_curl "Initialize MCP protocol via SSE" \
        "curl -s -X POST '$SERVER_URL/message?sessionId=$SESSION_ID' \\
            -H 'Content-Type: application/json' \\
            -d '{\"jsonrpc\":\"2.0\",\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{}},\"id\":1}'"
else
    echo -e "${YELLOW}Skipping SSE initialization (no session ID)${NC}"
fi

# For HTTP streaming (fallback), initialize directly
execute_curl "Initialize MCP protocol via HTTP streaming" \
    "curl -s -X POST '$SERVER_URL/' \\
        -H 'Content-Type: application/json' \\
        -H 'Accept: application/json,text/event-stream' \\
        -d '{\"jsonrpc\":\"2.0\",\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{}},\"id\":1}'"

# =============================================================================
# 4. LISTING AVAILABLE TOOLS
# =============================================================================

print_section "4. LISTING AVAILABLE TOOLS"

# List tools via SSE session if available
if [ -n "$SESSION_ID" ]; then
    execute_curl "List all available MCP tools (SSE)" \
        "curl -s -X POST '$SERVER_URL/message?sessionId=$SESSION_ID' \\
            -H 'Content-Type: application/json' \\
            -d '{\"jsonrpc\":\"2.0\",\"method\":\"tools/list\",\"params\":{},\"id\":2}'"
fi

# Extract tool names
echo -e "${GREEN}📝 Available tool names:${NC}"
if [ -n "$SESSION_ID" ]; then
    curl -s -X POST "$SERVER_URL/message?sessionId=$SESSION_ID" \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}' \
        | jq -r '.result.tools[].name' 2>/dev/null | sed 's/^/  • /' || echo "  (Could not extract tool names)"
fi
echo ""

# =============================================================================
# 5. INTENT INTERPRETATION EXAMPLES
# =============================================================================

print_section "5. INTENT INTERPRETATION - Natural Language to Smart Contracts"

# Use session if available, otherwise try direct
ENDPOINT="$SERVER_URL/"
if [ -n "$SESSION_ID" ]; then
    ENDPOINT="$SERVER_URL/message?sessionId=$SESSION_ID"
fi

# Swap tokens
execute_curl "Intent: Swap USDC for ETH" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"interpret_intent\",
                \"arguments\":{
                    \"intent\":\"swap 100 USDC for ETH on Uniswap\"
                }
            },
            \"id\":3
        }'"

# Transfer tokens
execute_curl "Intent: Transfer tokens" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"interpret_intent\",
                \"arguments\":{
                    \"intent\":\"send 50 DAI to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb\"
                }
            },
            \"id\":4
        }'"

# Approve spending
execute_curl "Intent: Approve token spending" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"interpret_intent\",
                \"arguments\":{
                    \"intent\":\"approve Uniswap router to spend my USDC\"
                }
            },
            \"id\":5
        }'"

# =============================================================================
# 6. FUNCTION ENCODING EXAMPLES
# =============================================================================

print_section "6. FUNCTION ENCODING - Encode Smart Contract Calls"

# Encode transfer function
execute_curl "Encode ERC20 transfer function" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"encode_function_call\",
                \"arguments\":{
                    \"function\":\"transfer\",
                    \"param1\":\"0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb\",
                    \"param2\":\"1000000000000000000\"
                }
            },
            \"id\":6
        }'"

# Encode approve function
execute_curl "Encode ERC20 approve function (max approval)" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"encode_function_call\",
                \"arguments\":{
                    \"function\":\"approve\",
                    \"param1\":\"0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D\",
                    \"param2\":\"115792089237316195423570985008687907853269984665640564039457584007913129639935\"
                }
            },
            \"id\":7
        }'"

# =============================================================================
# 7. TRANSACTION DECODING EXAMPLES
# =============================================================================

print_section "7. TRANSACTION DECODING - Decode Transaction Data"

# Decode a transfer transaction
execute_curl "Decode ERC20 transfer transaction" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"decode_transaction\",
                \"arguments\":{
                    \"data\":\"0xa9059cbb000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb70000000000000000000000000000000000000000000000000de0b6b3a7640000\"
                }
            },
            \"id\":8
        }'"

# =============================================================================
# 8. GAS ESTIMATION
# =============================================================================

print_section "8. GAS ESTIMATION"

execute_curl "Estimate gas for a transaction" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"estimate_gas\",
                \"arguments\":{}
            },
            \"id\":9
        }'"

# =============================================================================
# 9. REAL-WORLD DEFI SCENARIOS
# =============================================================================

print_section "9. REAL-WORLD DEFI SCENARIOS"

# Complex swap with slippage
execute_curl "Complex swap with specific parameters" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"interpret_intent\",
                \"arguments\":{
                    \"intent\":\"swap 1000 USDC for ETH with 0.5% slippage on Uniswap V3\"
                }
            },
            \"id\":10
        }'"

# Liquidity provision
execute_curl "Add liquidity to a pool" \
    "curl -s -X POST '$ENDPOINT' \\
        -H 'Content-Type: application/json' \\
        -d '{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"interpret_intent\",
                \"arguments\":{
                    \"intent\":\"add liquidity to ETH/USDC pool with 1 ETH and 3000 USDC\"
                }
            },
            \"id\":11
        }'"

# =============================================================================
# 10. PERFORMANCE METRICS
# =============================================================================

print_section "10. PERFORMANCE METRICS"

echo -e "${GREEN}📝 Measuring response times (5 requests)${NC}"
total_time=0
for i in {1..5}; do
    start_time=$(date +%s%N)
    curl -s "$SERVER_URL/health" > /dev/null 2>&1
    end_time=$(date +%s%N)
    elapsed_time=$((($end_time - $start_time) / 1000000))
    total_time=$(($total_time + $elapsed_time))
    echo -e "  Request $i: ${CYAN}${elapsed_time}ms${NC}"
done
avg_time=$(($total_time / 5))
echo -e "${BOLD}Average response time: ${GREEN}${avg_time}ms${NC}"

# =============================================================================
# SUMMARY
# =============================================================================

print_header "DEMO COMPLETE!"

echo -e "${BOLD}${GREEN}Summary of MCP Server Capabilities:${NC}"
echo -e "  ${CYAN}•${NC} Natural language intent interpretation"
echo -e "  ${CYAN}•${NC} Smart contract function encoding/decoding"
echo -e "  ${CYAN}•${NC} Gas estimation for transactions"
echo -e "  ${CYAN}•${NC} Support for multiple DeFi protocols"
echo -e "  ${CYAN}•${NC} SSE for real-time streaming"
echo -e "  ${CYAN}•${NC} HTTP streaming for request/response"
echo ""
echo -e "${BOLD}${YELLOW}Server Endpoints (Unified Mode):${NC}"
echo -e "  ${CYAN}•${NC} SSE: GET $SERVER_URL/sse"
echo -e "  ${CYAN}•${NC} SSE Messages: POST $SERVER_URL/message?sessionId=..."
echo -e "  ${CYAN}•${NC} HTTP Streaming: POST $SERVER_URL/"
echo -e "  ${CYAN}•${NC} Health: GET $SERVER_URL/health"
echo ""
echo -e "${BOLD}${MAGENTA}Available Tools:${NC}"
echo -e "  ${CYAN}•${NC} interpret_intent - Convert natural language to contract calls"
echo -e "  ${CYAN}•${NC} encode_function_call - Encode smart contract functions"
echo -e "  ${CYAN}•${NC} decode_transaction - Decode transaction data"
echo -e "  ${CYAN}•${NC} estimate_gas - Estimate gas for transactions"
echo ""
echo -e "${GREEN}Thank you for using ABI Assistant MCP Server!${NC}"