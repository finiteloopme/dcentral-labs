#!/usr/bin/env bash

# Gemini CLI demo with ABI Assistant MCP Server

echo "🎭 Gemini + ABI Assistant Demo"
echo "==============================="
echo ""

# Check if server is running
if ! curl -4 -s -X POST http://localhost:3000/ \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' \
    > /dev/null 2>&1; then
    echo "❌ MCP server not found on port 3000"
    echo "   Start it with: cd ../.. && cargo run"
    exit 1
fi

echo "✅ MCP server is running"
echo ""

# Check if Gemini CLI is installed
if ! command -v gemini &> /dev/null; then
    echo "❌ Gemini CLI not found"
    echo "   Install it with: npm install -g @google/gemini-cli"
    exit 1
fi

echo "✅ Gemini CLI is installed"
echo ""

# Check if MCP server is configured in Gemini
if ! gemini mcp list 2>/dev/null | grep -q "abi-assistant"; then
    echo "📝 Adding ABI Assistant to Gemini MCP servers..."
    gemini mcp add abi-assistant --transport http http://localhost:3000
    echo ""
fi

# Function to run Gemini chat commands
gemini_chat() {
    local prompt=$1
    echo "🤖 Prompt: $prompt"
    echo "---"
    gemini chat "$prompt" --allowed-mcp-server-names abi-assistant 2>/dev/null || echo "Note: Gemini may need API key configuration"
    echo ""
}

# Demo different DeFi intents using Gemini
echo "📝 Testing DeFi Operations with Gemini:"
echo "----------------------------------------"
echo ""

gemini_chat "Using the MCP server, interpret this intent: swap 100 USDC for ETH"

gemini_chat "Using the MCP server, encode a transfer function call to send 1 ETH to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7"

gemini_chat "List all available tools from the MCP server and explain what each one does"

echo "💡 Interactive Mode:"
echo "-------------------"
echo "You can now chat with Gemini and use the MCP server interactively:"
echo ""
echo "  gemini chat --allowed-mcp-server-names abi-assistant"
echo ""
echo "Example prompts to try:"
echo "  • 'Help me swap tokens on Uniswap'"
echo "  • 'How do I approve a contract to use my tokens?'"
echo "  • 'Encode a function call to transfer ERC20 tokens'"
echo "  • 'What DeFi operations can you help me with?'"
echo ""

# Optional: Start interactive session
read -p "Would you like to start an interactive Gemini session? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting Gemini interactive mode..."
    echo "(Use the MCP server by asking about blockchain operations)"
    echo ""
    gemini chat --allowed-mcp-server-names abi-assistant
fi