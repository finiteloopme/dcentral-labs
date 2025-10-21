# Gemini CLI DeFi Agent

A complete example implementation of a DeFi agent using Gemini CLI with the ABI Assistant MCP server.

## Quick Start

```bash
# 1. Run setup script
./setup.sh

# 2. Start interacting
gemini chat "I want to swap 1000 USDC for ETH"
```

## Features

### 🔄 Token Swaps
```bash
gemini chat "Swap 500 DAI for USDC with minimal slippage"
```

### 💰 Yield Optimization
```bash
gemini chat "Find the best yield for my 10000 USDC"
```

### 🔍 Arbitrage Detection
```bash
gemini chat "Scan for arbitrage opportunities on major DEXes"
```

### 📊 Portfolio Management
```bash
gemini chat "Rebalance my portfolio to 60% ETH, 40% stables"
```

## Configuration

Edit `config.yaml` to customize:
- Preferred protocols
- Slippage tolerance
- Gas settings
- Safety limits

## Architecture

```
Gemini CLI
    ↓
MCP Client
    ↓
ABI Assistant MCP Server
    ↓
Blockchain RPCs
```

## Available MCP Tools

| Tool | Description | Example |
|------|-------------|---------|
| `interpret_intent` | Convert natural language to contract calls | "swap tokens" → Uniswap.swap() |
| `build_transaction` | Create unsigned transactions | Generates ready-to-sign tx |
| `simulate_transaction` | Test before execution | Validates tx will succeed |
| `export_for_signing` | Multiple signing formats | MetaMask, WalletConnect, etc |
| `find_best_path` | Optimize execution route | Best DEX for swap |
| `estimate_gas` | Calculate gas costs | Returns gwei and USD |

## Example Workflows

### Simple Swap
```bash
# User request
gemini chat "Swap 100 USDC for DAI"

# Agent actions:
# 1. Interprets intent → swap action
# 2. Finds best DEX (Curve for stablecoin swap)
# 3. Builds transaction
# 4. Simulates for safety
# 5. Returns signing options
```

### Complex DeFi Strategy
```bash
# User request
gemini chat "Borrow DAI against my ETH and farm yield"

# Agent actions:
# 1. Check ETH balance and health factor
# 2. Prepare borrow transaction on Aave
# 3. Find best yield opportunity for DAI
# 4. Build batch transaction
# 5. Simulate entire flow
# 6. Present complete strategy with risks
```

## Safety Features

- ✅ **Mandatory simulation** before presenting transactions
- ✅ **Slippage protection** with configurable limits
- ✅ **Gas estimation** with USD conversion
- ✅ **Risk warnings** for complex strategies
- ✅ **No private key handling** - only prepares transactions

## Multi-Agent Collaboration

This agent can collaborate with other agents in the network:

```bash
# Enable collaboration
gemini config set agent_network.enabled true

# Agent will automatically:
# - Share discovered opportunities
# - Receive strategy tips from other agents
# - Participate in coordinated strategies
```

## Monitoring

```bash
# Start monitoring dashboard
./monitor.py

# View logs
tail -f logs/gemini-agent.log
```

## Custom Prompts

Pre-configured prompts for specific strategies:
- `prompts/arbitrage.txt` - Arbitrage hunting
- `prompts/yield-farming.txt` - Yield optimization
- `prompts/portfolio-rebalance.txt` - Portfolio management
- `prompts/gas-optimization.txt` - Gas-efficient execution

## Troubleshooting

### MCP Connection Issues
```bash
# Check if ABI Assistant is running
curl http://localhost:3000/health

# Restart MCP server
cd ../.. && make dev
```

### Transaction Simulation Failures
- Check wallet has sufficient balance
- Verify token approvals
- Ensure gas price is reasonable

## Advanced Usage

### Custom Chain Configuration
```yaml
# In config.yaml
context:
  default_chain: polygon
  rpc_override: https://polygon-rpc.com
```

### High-Frequency Operations
```yaml
# Enable caching and optimization
monitoring:
  cache_ttl: 60  # seconds
  batch_simulations: true
```

## Security Notes

1. Never share your private keys
2. Always verify transaction details before signing
3. Start with small amounts when testing
4. Use hardware wallets for large transactions
5. Enable monitoring for automated strategies

## Support

- ABI Assistant Issues: [GitHub Issues](https://github.com/yourrepo/abi-assistant)
- Gemini CLI Docs: [Gemini Documentation](https://gemini-cli-docs.example)

## License

MIT - See LICENSE file in project root