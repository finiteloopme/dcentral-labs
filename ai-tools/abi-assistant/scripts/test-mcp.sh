#!/usr/bin/env bash
# Test MCP server endpoints
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

# Default values
SERVER_URL="${1:-http://localhost:3000}"
TEST_MODE="${2:-basic}"  # basic or full

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0

# Test function
run_test() {
    local test_name="$1"
    local endpoint="$2"
    local data="$3"
    local expected="$4"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "Testing $test_name... "
    
    local response=$(curl -s -X POST "$SERVER_URL$endpoint" \
        -H "Content-Type: application/json" \
        -d "$data" 2>/dev/null || echo '{"error": "Connection failed"}')
    
    if echo "$response" | grep -q "$expected"; then
        echo -e "${GREEN}✓${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC}"
        echo "  Expected: $expected"
        echo "  Got: $response" | head -1
        return 1
    fi
}

log_info "Testing MCP Server at $SERVER_URL"

# Check if server is running
if ! curl -s "$SERVER_URL/health" &>/dev/null; then
    log_error "Server is not running at $SERVER_URL"
    log_info "Start the server with: make dev"
    exit 1
fi

# Basic tests
log_info "Running basic tests..."

# Test health endpoint
run_test "health endpoint" "/health" "" "OK\|ok\|healthy"

# Test SSE endpoint
if curl -s "$SERVER_URL/sse" --max-time 1 &>/dev/null; then
    log_success "SSE endpoint is accessible"
else
    log_warn "SSE endpoint not accessible or timed out"
fi

# Test tools/list
run_test "tools/list" "/" '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "params": {},
    "id": 1
}' "interpret_intent"

# Test interpret_intent
run_test "interpret_intent" "/" '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
        "name": "interpret_intent",
        "arguments": {
            "intent": "swap 100 USDC for ETH"
        }
    },
    "id": 2
}' "swap\|Swap"

if [[ "$TEST_MODE" == "full" ]]; then
    log_info "Running full test suite..."
    
    # Test encode_function_call
    run_test "encode_function_call" "/" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "encode_function_call",
            "arguments": {
                "abi": "[{\"inputs\":[{\"name\":\"to\",\"type\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\"}],\"name\":\"transfer\",\"outputs\":[{\"name\":\"\",\"type\":\"bool\"}],\"type\":\"function\"}]",
                "function_name": "transfer",
                "args": ["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", "1000000000000000000"]
            }
        },
        "id": 3
    }' "0xa9059cbb\|calldata"
    
    # Test decode_transaction
    run_test "decode_transaction" "/" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "decode_transaction",
            "arguments": {
                "abi": "[{\"inputs\":[{\"name\":\"to\",\"type\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\"}],\"name\":\"transfer\",\"outputs\":[{\"name\":\"\",\"type\":\"bool\"}],\"type\":\"function\"}]",
                "calldata": "0xa9059cbb000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb70000000000000000000000000000000000000000000000000de0b6b3a7640000"
            }
        },
        "id": 4
    }' "transfer\|742d35cc"
    
    # Test estimate_gas
    run_test "estimate_gas" "/" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "estimate_gas",
            "arguments": {
                "to": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
                "data": "0xa9059cbb000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb70000000000000000000000000000000000000000000000000de0b6b3a7640000"
            }
        },
        "id": 5
    }' "gas\|estimated"
fi

# Summary
echo ""
log_info "Test Summary: $TESTS_PASSED/$TESTS_RUN tests passed"

if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
    log_success "All tests passed!"
    exit 0
else
    log_error "Some tests failed"
    exit 1
fi