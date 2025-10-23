# ABI Assistant Examples

This directory contains comprehensive examples demonstrating the ABI Assistant MCP server capabilities, with special focus on the Phase 2 intent resolution system.

## 📚 Available Examples

### 1. **Intent Resolution** (`intent-resolution.rs`) 🆕
Demonstrates the Phase 2 intent resolution system with:
- Local pattern-based resolution
- Gemini AI integration (mock)
- Hybrid resolution strategies (5 different modes)
- Caching system with query normalization
- Performance comparisons

```bash
# Run the example
cargo run --example intent-resolution
```

**Key Features Demonstrated:**
- Parse natural language DeFi intents
- Extract parameters (amounts, tokens, slippage)
- Suggest appropriate protocols
- Cache results for performance

### 2. **Library Usage** (`library-usage.rs`)
Shows how to embed ABI Assistant in your Rust application:
- Custom configuration
- Direct API usage
- Integration patterns

```bash
cargo run --example library-usage
```

### 3. **cURL Client** (`curl-client/`)
Shell scripts for testing MCP endpoints:

| Script | Purpose |
|--------|---------|
| `intent-resolution.sh` 🆕 | Test intent resolution via MCP |
| `mcp-curl-demo.sh` | Basic MCP protocol demo |
| `defi-operations.sh` | Common DeFi operations |
| `quick-test.sh` | Quick connectivity test |

```bash
cd curl-client
./intent-resolution.sh  # Test the new intent system
```

### 4. **Gemini Agent** (`gemini-agent/`)
Integration with Google's Gemini AI:

- **intent-integration.py** 🆕 - Shows the complete pipeline:
  1. Gemini enhances vague user requests
  2. ABI Assistant resolves to specific protocols
  3. Returns ready-to-execute parameters

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
# Test intent resolution
cargo run --example intent-resolution

# Test via HTTP/MCP
./curl-client/intent-resolution.sh

# Test with Gemini integration
cd gemini-agent && python intent-integration.py
```

## 🎯 Intent Resolution Examples

The Phase 2 intent system understands various natural language requests:

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

### Simple Intent
```bash
curl -X POST http://localhost:3000/sse/message \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"interpret_intent","arguments":{"intent":"swap USDC for ETH"}},"id":1}'
```

### Complex Multi-step
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