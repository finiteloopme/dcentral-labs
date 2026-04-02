# ABI Assistant Examples

This directory contains comprehensive examples demonstrating the ABI Assistant MCP server capabilities, covering Phases 1-3 of the implementation.

## 📚 Available Examples

### 1. **Phase 3 Complete Demo** (`phase3-demo.rs`) ⭐ NEW
Comprehensive demonstration of all Phase 3 features:
- Generic ABI encoding for any function signature
- Enhanced transaction decoding with protocol detection
- Multi-protocol transaction building
- 6 export formats for different wallet types
- Complete non-custodial transaction lifecycle

```bash
# Run the complete demo
cargo run --example phase3-demo
```

### 2. **Transaction Building** (`transaction-building.rs`) - Phase 3
Detailed transaction construction examples:
- Build ERC20 transfers and approvals
- Uniswap swap transactions
- Aave lending operations
- Export in multiple wallet formats

```bash
# Run the example
cargo run --example transaction-building
```

**Key Features:**
- Build complex DeFi transactions
- Export in formats: JSON, EIP-712, QR Code, WalletConnect, Ethers.js, Raw Hex
- Support for Uniswap, Aave, Compound, Lido protocols
- Complete non-custodial workflow

### 3. **Intent Resolution** (`intent-resolution.rs`) - Phase 2
Advanced intent interpretation system:
- Local pattern-based resolution
- Gemini AI integration (mock)
- Hybrid resolution strategies (5 different modes)
- Caching system with query normalization
- Performance comparisons

```bash
# Run the example
cargo run --example intent-resolution
```

**Features:**
- Parse natural language DeFi intents
- Extract parameters (amounts, tokens, slippage)
- Suggest appropriate protocols
- Cache results for performance

### 4. **Library Usage** (`library-usage.rs`)
Shows how to embed ABI Assistant in your Rust application:
- Custom configuration
- Direct API usage
- Integration patterns

```bash
cargo run --example library-usage
```

### 5. **cURL Client** (`curl-client/`)
Shell scripts for testing MCP endpoints:

| Script | Purpose | Phase |
|--------|---------|-------|
| `transaction-tools.sh` ⭐ | Test Phase 3 transaction tools | 3 |
| `test-signing.sh` | Test transaction signing flow | 3 |
| `intent-resolution.sh` | Test intent resolution via MCP | 2 |
| `defi-operations.sh` | Common DeFi operations | 2 |
| `mcp-curl-demo.sh` | Basic MCP protocol demo | 1 |
| `quick-test.sh` | Quick connectivity test | 1 |

```bash
cd curl-client
./transaction-tools.sh  # Test Phase 3 transaction building
./intent-resolution.sh  # Test Phase 2 intent system
./test-signing.sh      # Test the signing workflow
```

### 6. **Gemini Agent** (`gemini-agent/`)
Integration with Google's Gemini AI:

- **intent-integration.py** - Complete AI-powered pipeline:
  1. Gemini enhances vague user requests
  2. ABI Assistant resolves to specific protocols
  3. Returns ready-to-execute parameters
  4. Builds and exports transactions for signing

```bash
cd gemini-agent
pip install -r requirements.txt
python intent-integration.py
```

## 🚀 Quick Start

1. **Start the MCP server**:
```bash
cd .. # Go to project root
cargo run
```

2. **Run examples** (in another terminal):
```bash
# Test Phase 3 - Complete Demo
cargo run --example phase3-demo

# Test Phase 3 - Transaction Building
cargo run --example transaction-building
./curl-client/transaction-tools.sh

# Test Phase 2 - Intent Resolution
cargo run --example intent-resolution
./curl-client/intent-resolution.sh

# Test with Gemini integration
cd gemini-agent && python intent-integration.py
```

## 🎯 Phase 3 Transaction Building

Build and export transactions in multiple formats:

### Supported Transaction Types
| Type | Protocols | Parameters |
|------|-----------|------------|
| `transfer` | ERC20 | token_address, to, amount |
| `approve` | ERC20 | token_address, spender, amount |
| `swap` | Uniswap V2/V3 | router, token_in, token_out, amount, slippage |
| `supply` | Aave, Compound | protocol, asset, amount |
| `borrow` | Aave, Compound | protocol, asset, amount, rate_mode |
| `stake` | Lido | amount |

### Export Formats
| Format | Use Case | Example Output |
|--------|----------|----------------|
| `raw_json` | Web3 libraries | `{"to": "0x...", "data": "0x...", "value": "0x0"}` |
| `eip712` | Smart wallets | Typed structured data |
| `qr_code` | Mobile wallets | QR code with transaction data |
| `wallet_connect` | WalletConnect | Deep link URL |
| `ethers_js` | Ethers.js apps | JavaScript code snippet |
| `raw_hex` | Direct signing | `0x...` hex string |

## 🎯 Phase 2 Intent Resolution

The intent system understands various natural language requests:

| User Input | Category | Confidence | Suggested Protocols |
|------------|----------|------------|-------------------|
| "swap 100 USDC for ETH" | Swap | 95% | Uniswap V3, V2 |
| "I want to earn yield on my DAI" | Lend | 90% | Aave V3, Compound |
| "stake 32 ETH" | Stake | 95% | Lido, RocketPool |
| "provide liquidity USDC/ETH" | ProvideLiquidity | 85% | Uniswap V3 |
| "borrow against my collateral" | Borrow | 88% | Aave, Compound |

### Resolution Strategies

Configure how intents are resolved:

```rust
// In your code
IntentStrategy::GeminiFirst  // Try AI first, fallback to local
IntentStrategy::LocalOnly    // Fast pattern matching only
IntentStrategy::Smart        // Automatic routing based on complexity
```

### Cache Performance

The caching system dramatically improves response times:

```
First query:  ~50-100ms  (pattern matching + protocol lookup)
Cached query: <1ms       (LRU cache hit)
Normalized:   <1ms       (handles variations like "SWAP" vs "swap")
```

## 🔧 Configuration

Examples support environment variables:

```bash
# Server location
export MCP_SERVER="http://localhost:3000"

# Gemini integration
export GEMINI_API_KEY="your-api-key"

# Intent strategy
export INTENT_STRATEGY="gemini_first"  # or "local_only", "smart"

# Cache settings
export CACHE_TTL="3600"  # 1 hour
export CACHE_SIZE="1000"  # max entries
```

## 📊 Performance Comparison

Run the intent-resolution example to see performance differences:

| Strategy | Latency | Accuracy | Use Case |
|----------|---------|----------|----------|
| Local Only | <10ms | Good | High-frequency trading bots |
| Gemini Only | 500-2000ms | Excellent | Complex multi-step intents |
| Gemini First | 500-2000ms | Excellent | User-facing applications |
| Local First | <10ms typical | Good+ | Performance-critical with AI fallback |
| Smart | Variable | Excellent | Adaptive based on query complexity |

## 🧪 Testing Different Scenarios

### Phase 3: Build & Export Transaction
```bash
# Build a token transfer
curl -X POST http://localhost:3000/sse/message \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "params":{
      "name":"build_transaction",
      "arguments":{
        "transaction_type":"transfer",
        "parameters":{
          "token_address":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
          "to":"0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
          "amount":"1000000000"
        }
      }
    },
    "id":1
  }'

# Export for MetaMask
curl -X POST http://localhost:3000/sse/message \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "params":{
      "name":"export_for_signing",
      "arguments":{
        "transaction": { ... },
        "format":"ethers_js"
      }
    },
    "id":2
  }'
```

### Phase 2: Intent Resolution
```bash
curl -X POST http://localhost:3000/sse/message \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"interpret_intent","arguments":{"intent":"swap USDC for ETH"}},"id":1}'
```

### Complex Multi-step Operation
```bash
# The system can understand complex operations
"borrow 5000 USDC against my ETH, then swap half for DAI and provide liquidity"
```

### Vague Intent (best with Gemini)
```bash
# Gemini enhances: "I want to make money with my tokens"
# Becomes: "lend 1000 USDC on Aave to earn 5% APY"
```

## 📝 Adding Your Own Examples

To add a new example:

1. **For Rust examples**, create the file and add to `Cargo.toml`:
```toml
[[example]]
name = "your-example"
path = "examples/your-example.rs"
```

2. **For shell scripts**, add to `curl-client/` with execute permissions:
```bash
chmod +x curl-client/your-script.sh
```

3. **For Python**, add to `gemini-agent/` with requirements:
```bash
echo "your-dependency" >> gemini-agent/requirements.txt
```

## 🔗 Related Documentation

- [Main README](../README.md) - Project overview
- [CONTEXT.md](../CONTEXT.md) - Architecture and Phase 2 details
- [CONFIG.md](../CONFIG.md) - Configuration options
- [Prompts](../prompts/) - Gemini prompt templates

## Need Help?

- Check individual example directories for specific READMEs
- Server issues? Check health: `curl http://localhost:3000/health`
- Intent not resolving? Try with `RUST_LOG=debug cargo run`