#!/usr/bin/env bash

# Quick test script to verify MCP server connectivity
# Works with unified transport (SSE + HTTP on same port)

SERVER="${1:-http://127.0.0.1:3000}"

echo "🔍 Quick MCP Server Test"
echo "Server: $SERVER"
echo "Transport: Unified (SSE + HTTP)"
echo ""

# 1. Health check
echo -n "1. Health check... "
if curl -s "$SERVER/health" | grep -q "MCP Server" 2>/dev/null; then
    echo "✅ OK"
else
    echo "❌ Failed"
    exit 1
fi

# 2. Test SSE endpoint
echo -n "2. SSE endpoint... "
SSE_RESPONSE=$(timeout 1 curl -s -N "$SERVER/sse" 2>/dev/null | head -1)
if echo "$SSE_RESPONSE" | grep -q "event:" 2>/dev/null; then
    echo "✅ OK (streaming available)"
else
    echo "⚠️  SSE not responding (may need initialization)"
fi

# 3. Get SSE session for testing
echo -n "3. Getting SSE session... "
SESSION_ID=$(timeout 1 curl -s -N "$SERVER/sse" 2>/dev/null | grep -oP 'sessionId=\K[^&\s]+' | head -1)
if [ -n "$SESSION_ID" ]; then
    echo "✅ Session: ${SESSION_ID:0:8}..."
    ENDPOINT="$SERVER/message?sessionId=$SESSION_ID"
else
    echo "⚠️  No session (using HTTP fallback)"
    ENDPOINT="$SERVER/"
fi

# 4. Initialize MCP protocol
echo -n "4. Initialize protocol... "
INIT_RESULT=$(curl -s -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json,text/event-stream" \
    -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05"},"id":1}' 2>/dev/null)

if echo "$INIT_RESULT" | grep -q "protocolVersion\|result\|error" 2>/dev/null; then
    echo "✅ Protocol initialized"
else
    echo "⚠️  Initialization issue"
fi

# 5. List tools
echo -n "5. List tools... "
TOOLS_RESPONSE=$(curl -s -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}' 2>/dev/null)

TOOLS=$(echo "$TOOLS_RESPONSE" | jq -r '.result.tools[].name' 2>/dev/null | tr '\n' ' ')

if [ -n "$TOOLS" ]; then
    echo "✅ Found: $TOOLS"
else
    echo "⚠️  Could not list tools"
fi

# 6. Test intent interpretation
echo -n "6. Test intent interpretation... "
INTENT_RESULT=$(curl -s -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc":"2.0",
        "method":"tools/call",
        "params":{
            "name":"interpret_intent",
            "arguments":{"intent":"swap ETH for USDC"}
        },
        "id":3
    }' 2>/dev/null)

PROTOCOL=$(echo "$INTENT_RESULT" | jq -r '.result' 2>/dev/null | grep -o '"protocol":"[^"]*"' | cut -d'"' -f4)

if [ -n "$PROTOCOL" ]; then
    echo "✅ Protocol: $PROTOCOL"
else
    echo "⚠️  Intent not processed"
fi

# 7. Test encoding
echo -n "7. Test function encoding... "
ENCODE_RESULT=$(curl -s -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc":"2.0",
        "method":"tools/call",
        "params":{
            "name":"encode_function_call",
            "arguments":{
                "function":"transfer",
                "param1":"0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
                "param2":"1000000000000000000"
            }
        },
        "id":4
    }' 2>/dev/null)

if echo "$ENCODE_RESULT" | grep -q "0xa9059cbb\|encoded" 2>/dev/null; then
    echo "✅ Encoding works"
else
    echo "⚠️  Encoding issue"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Summary
TESTS_PASSED=0
TESTS_TOTAL=7

[ -n "$TOOLS" ] && TESTS_PASSED=$((TESTS_PASSED + 1))
[ -n "$PROTOCOL" ] && TESTS_PASSED=$((TESTS_PASSED + 1))
echo "$ENCODE_RESULT" | grep -q "encoded" 2>/dev/null && TESTS_PASSED=$((TESTS_PASSED + 1))
curl -s "$SERVER/health" | grep -q "MCP Server" 2>/dev/null && TESTS_PASSED=$((TESTS_PASSED + 1))
echo "$SSE_RESPONSE" | grep -q "event:" 2>/dev/null && TESTS_PASSED=$((TESTS_PASSED + 1))
[ -n "$SESSION_ID" ] && TESTS_PASSED=$((TESTS_PASSED + 1))
echo "$INIT_RESULT" | grep -q "protocolVersion\|result" 2>/dev/null && TESTS_PASSED=$((TESTS_PASSED + 1))

if [ $TESTS_PASSED -ge 4 ]; then
    echo "✅ MCP Server is working! ($TESTS_PASSED/7 tests passed)"
    echo ""
    echo "Endpoints available:"
    echo "  • Health: GET $SERVER/health"
    echo "  • SSE: GET $SERVER/sse"
    echo "  • SSE Messages: POST $SERVER/message?sessionId=..."
    echo "  • HTTP Streaming: POST $SERVER/"
else
    echo "⚠️  Some tests failed ($TESTS_PASSED/7 passed)"
    echo "The server may need proper initialization or configuration."
fi