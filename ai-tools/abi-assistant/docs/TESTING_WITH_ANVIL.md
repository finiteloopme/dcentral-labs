# Testing with Anvil

Anvil is a local Ethereum blockchain simulator that's perfect for testing smart contract interactions without using real ETH or connecting to live networks.

## Quick Start

### Terminal 1: Start Anvil
```bash
# Start a local Ethereum node on port 8545
make anvil

# Or with mainnet fork (requires RPC URL)
FORK_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY make anvil-fork
```

### Terminal 2: Run ABI Assistant
```bash
# Start the ABI Assistant (it will detect Anvil on localhost:8545)
ETH_RPC_URL=http://localhost:8545 make dev
```

### Terminal 3: Run Tests
```bash
# Check if everything is working
make test-integration
```

## Why Use Anvil?

1. **Instant Transactions**: No waiting for block confirmations
2. **Free Testing**: Unlimited test ETH for experiments
3. **Deterministic**: Same accounts and state every time
4. **Time Travel**: Fast-forward time for testing time-locks
5. **Mainnet Fork**: Test against real protocols like Uniswap, Aave

## Container Architecture

```
Terminal 1                    Terminal 2
┌─────────────────┐          ┌─────────────────┐
│  Anvil Container│          │   ABI Assistant │
│  Port: 8545     │◄─────────│   Port: 3000    │
│                 │          │                 │
│  - 10 accounts  │          │  - MCP Server   │
│  - 10000 ETH ea │          │  - Intent tools │
│  - Instant mine │          │  - ABI encoding │
└─────────────────┘          └─────────────────┘
```

## Test Accounts

Anvil provides 10 test accounts with 10,000 ETH each:

**Mnemonic**: `test test test test test test test test test test test junk`

**Account 0**: 
- Address: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Private Key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

**Account 1**:
- Address: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
- Private Key: `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`

## Common Use Cases

### 1. Testing Token Transfers
```bash
# The ABI Assistant can encode transfers
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "encode_function_call",
      "arguments": {
        "function": "transfer",
        "params": ["0x70997970C51812dc3A010C7d01b50e0d17dc79C8", "1000000000000000000"]
      }
    },
    "id": 1
  }'
```

### 2. Testing Intent Interpretation
```bash
# Natural language to contract calls
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "interpret_intent",
      "arguments": {
        "intent": "swap 100 USDC for ETH"
      }
    },
    "id": 1
  }'
```

### 3. Mainnet Fork Testing
```bash
# Fork mainnet to test real protocols
FORK_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY make anvil-fork

# Now you can test against:
# - Uniswap: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
# - USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
# - WETH: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
```

## Advanced Features

### State Snapshots
```bash
# Save current state
curl -X POST http://localhost:8545 \
  -d '{"jsonrpc":"2.0","method":"evm_snapshot","params":[],"id":1}'

# Restore to snapshot
curl -X POST http://localhost:8545 \
  -d '{"jsonrpc":"2.0","method":"evm_revert","params":["0x1"],"id":1}'
```

### Time Manipulation
```bash
# Fast forward 1 day
curl -X POST http://localhost:8545 \
  -d '{"jsonrpc":"2.0","method":"evm_increaseTime","params":[86400],"id":1}'
```

### Impersonate Accounts
```bash
# Act as any address (useful for testing)
curl -X POST http://localhost:8545 \
  -d '{"jsonrpc":"2.0","method":"anvil_impersonateAccount","params":["0x..."],"id":1}'
```

## Troubleshooting

### Port Already in Use
```bash
# Stop existing Anvil
podman stop abi-assistant-anvil
# Or kill process on port 8545
lsof -ti:8545 | xargs kill -9
```

### Connection Refused
- Make sure Anvil is running: `make anvil`
- Check logs: `podman logs abi-assistant-anvil`
- Verify port: `curl http://localhost:8545`

### Out of Gas
- Anvil accounts have 10,000 ETH each
- Use `--gas-limit` flag to increase block gas limit
- Check gas estimation before sending transactions

## Tips

1. **Keep Anvil Running**: Run in a dedicated terminal
2. **Use Fork for Realism**: Fork mainnet when testing real protocols
3. **Reset Between Tests**: Use snapshots or restart Anvil
4. **Monitor Logs**: Anvil shows all transactions in real-time
5. **Save Fork Cache**: Reuse forked state to speed up tests

## Example Workflow

```bash
# Terminal 1: Start Anvil
make anvil

# Terminal 2: Start ABI Assistant
ETH_RPC_URL=http://localhost:8545 make dev

# Terminal 3: Deploy test contract (if needed)
# Example: Deploy an ERC20 token or interact with existing contracts
# cast send --private-key 0xac09... --create <compiled_bytecode>

# Terminal 3: Test with ABI Assistant
curl -X POST http://localhost:3000/ -d '{"jsonrpc":"2.0","method":"tools/call","params":{...}}'

# Stop everything
make anvil-stop
make container-stop
```

This setup provides a complete local testing environment for smart contract interactions!