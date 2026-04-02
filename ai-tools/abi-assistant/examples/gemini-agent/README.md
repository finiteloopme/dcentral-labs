# Gemini Agent Integration

Connect Google's Gemini CLI to the ABI Assistant MCP Server.

## Prerequisites

1. **Gemini CLI**: Install globally
```bash
npm install -g @google/gemini-cli
```

2. **Google API Key**: Get from [Google AI Studio](https://makersuite.google.com/app/apikey)
```bash
# Add to .env file
echo "GOOGLE_API_KEY=your-key-here" > .env
```

## Quick Start

1. **Start MCP server** (from project root):
```bash
cargo run
```

2. **Run Gemini agent**:
```bash
./run-gemini.sh
```

3. **Try these commands**:
```
> What tools do you have?
> Help me swap 100 USDC for ETH
> Encode a transfer function for sending 1 ETH
> What's the gas estimate for a transaction?
```

## Configuration

The MCP server is already configured in `.gemini/settings.json`:
```json
{
  "mcpServers": {
    "abi-assistant": {
      "transport": "sse",
      "url": "http://127.0.0.1:3000/sse"
    }
  }
}
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `run-gemini.sh` | Start Gemini CLI with MCP |
| `demo.sh` | Run example prompts |

## Custom Prompts

Check the `prompts/` directory for DeFi-specific prompts:
- `arbitrage.txt` - Find arbitrage opportunities
- `yield-farming.txt` - Optimize yield strategies

Use them:
```bash
gemini -m gemini-2.5-pro < prompts/yield-farming.txt
```

## Direct API Usage

You can also use Gemini's API directly:
```bash
python example.py
```

## Intent Resolution Integration (Phase 2)

The `intent-integration.py` example shows how to:
1. Use Gemini to enhance vague user requests
2. Send clarified intents to ABI Assistant
3. Process structured responses with protocol suggestions
4. Build transactions ready for signing

```bash
# Install dependencies
pip install -r requirements.txt

# Run the integration example
python intent-integration.py
```

This demonstrates the full pipeline:
- User: "I want to trade some tokens"
- Gemini: Enhances to "swap 100 USDC for ETH"
- ABI Assistant: Returns protocol suggestions (Uniswap, Sushiswap, etc.)
- Result: Ready-to-execute transaction parameters

## Transaction Building (Phase 3)

The system now supports complete transaction lifecycle:

### Build Transactions
```python
# Using the MCP API
response = mcp_call("build_transaction", {
    "transaction_type": "swap",
    "protocol": "uniswap_v2",
    "parameters": {
        "router": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        "token_in": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",  # USDC
        "token_out": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", # WETH
        "amount_in": "1000000000",  # 1000 USDC
        "slippage": "0.5"
    }
})
```

### Export for Signing
```python
# Export in various formats
response = mcp_call("export_for_signing", {
    "transaction": tx_data,
    "format": "ethers_js"  # or: raw_json, eip712, qr_code, wallet_connect, raw_hex
})
```

## Troubleshooting

### Gemini not connecting?
```bash
# Check MCP server
curl http://127.0.0.1:3000/health

# List MCP servers
gemini mcp list

# Re-add if needed
gemini mcp remove abi-assistant
gemini mcp add abi-assistant http://127.0.0.1:3000/sse
```

### API Key issues?
```bash
# Verify .env file
cat .env

# Test API key
gemini -m gemini-2.5-pro "Hello"
```

## Tips

- Use model `gemini-2.5-pro` for best results
- The MCP tools are automatically available to Gemini
- Check `GEMINI.md` for agent instructions