#!/usr/bin/env bash

# Run Gemini CLI with proper configuration

echo "🚀 Gemini CLI with ABI Assistant"
echo "================================"
echo ""

# Check if Gemini CLI is installed
if ! command -v gemini &> /dev/null; then
    echo "❌ Gemini CLI not found"
    echo "Install with: npm install -g @google/gemini-cli"
    exit 1
fi

# Check if MCP server is running
if ! curl -4 -s http://127.0.0.1:3000/ > /dev/null 2>&1; then
    echo "⚠️  MCP server not running on port 3000"
    echo "   Start it with: cd ../.. && ./scripts/dev.sh"
    echo ""
fi

# Set the model to use Gemini 2.5 Pro Experimental
MODEL="gemini-2.5-pro"

echo "✅ Using model: $MODEL"
echo ""

if [ $# -eq 0 ]; then
    # Interactive mode
    echo "Starting interactive mode..."
    echo "Type 'exit' to quit"
    echo ""
    gemini -m "$MODEL"
else
    # Single prompt mode
    gemini -m "$MODEL" "$@"
fi