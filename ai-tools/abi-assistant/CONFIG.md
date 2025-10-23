# Configuration Guide

The ABI Assistant MCP Server uses a flexible configuration system that supports both file-based configuration and environment variable overrides.

## Configuration Files

The server looks for configuration in the following order:
1. File specified by `MCP_CONFIG_PATH` environment variable
2. `mcp-config.toml` in the current directory
3. `mcp-default-config.toml` (default configuration)
4. Built-in defaults if no file is found

## Quick Start

1. Copy the default configuration:
```bash
cp mcp-default-config.toml mcp-config.toml
```

2. Edit `mcp-config.toml` with your settings
3. Run the server - it will automatically load your configuration

## Environment Variable Overrides

Environment variables always take precedence over file configuration:

| Environment Variable | Description | Default |
|---------------------|-------------|---------|
| `MCP_CONFIG_PATH` | Path to custom config file | `mcp-config.toml` |
| `MCP_PORT` | Server port | `3000` |
| `MCP_TRANSPORT` | Transport mode: `sse`, `http`, or `both` | `both` |
| `DATABASE_URL` | Database connection URL | `sqlite://./data/abi_assistant.db` |
| `ETH_RPC_URL` | Ethereum RPC endpoint | `http://localhost:8545` |
| `POLYGON_RPC_URL` | Polygon RPC endpoint | (disabled) |
| `ARBITRUM_RPC_URL` | Arbitrum RPC endpoint | (disabled) |
| `OPTIMISM_RPC_URL` | Optimism RPC endpoint | (disabled) |
| `ETHERSCAN_API_KEY` | Etherscan API key | (empty) |
| `INFURA_API_KEY` | Infura API key | (empty) |
| `RUST_LOG` | Logging level | `info` |

## Configuration Sections

### Server Configuration
```toml
[server]
name = "abi-assistant"
version = "0.1.0"
host = "127.0.0.1"
port = 3000
transport = "both"  # "sse", "http", or "both"
```

### Transport Settings
```toml
[server.sse]
path = "/sse"
message_path = "/message"
keep_alive_interval = 30  # optional, in seconds

[server.http]
path = "/mcp"
health_path = "/health"
port_offset = 1  # HTTP port = main port + offset
```

### Blockchain Networks
```toml
[blockchain.ethereum]
rpc_url = "http://localhost:8545"
chain_id = 1
name = "Ethereum Mainnet"
enabled = true

# Add more chains as needed
[blockchain.polygon]
rpc_url = "https://polygon-rpc.com"
chain_id = 137
enabled = false  # Set to true to enable
```

### Feature Flags
```toml
[features]
fetch_abi_from_explorers = true
simulate_transactions = true
gas_optimization = true
mev_protection = false
cross_chain = false
cache_abis = true
debug_mode = false
```

### Intent Processing
```toml
[intent]
confidence_threshold = 0.7
max_suggestions = 3
fuzzy_matching = true

[intent.protocols]
uniswap = ["Uniswap", "UniswapV2", "UniswapV3", "uni"]
sushiswap = ["Sushiswap", "Sushi", "sushi"]
```

### Gas Settings
```toml
[gas]
default_gas_limit = 150000
price_strategy = "standard"  # "standard", "fast", "slow", "custom"
custom_gas_price = 30  # in gwei
gas_buffer_percent = 20
max_gas_price = 500  # safety limit in gwei
```

### Caching
```toml
[cache]
enabled = true
max_cached_abis = 100
abi_cache_ttl = 3600  # 1 hour
max_cached_intents = 50
intent_cache_ttl = 300  # 5 minutes
```

### Security
```toml
[security]
rate_limiting = true
max_requests_per_minute = 60
require_signatures = false
allowed_origins = ["*"]
max_body_size = 1048576  # 1MB
request_timeout = 30
```

## Examples

### Running with Custom Config
```bash
# Use a specific config file
MCP_CONFIG_PATH=/path/to/config.toml cargo run

# Override specific settings
MCP_PORT=8080 MCP_TRANSPORT=http cargo run

# Use production Ethereum RPC
ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY cargo run
```

### Docker Configuration
```dockerfile
# Copy your config into the container
COPY mcp-config.toml /app/mcp-config.toml

# Or use environment variables
ENV MCP_PORT=3000
ENV MCP_TRANSPORT=both
ENV DATABASE_URL=sqlite:///data/abi_assistant.db
```

### Development vs Production

**Development** (`mcp-config.dev.toml`):
```toml
[features]
debug_mode = true

[development]
hot_reload = true
log_requests = true
mock_mode = false
pretty_json = true
```

**Production** (`mcp-config.prod.toml`):
```toml
[server]
host = "0.0.0.0"  # Listen on all interfaces

[features]
debug_mode = false

[security]
rate_limiting = true
require_signatures = true
allowed_origins = ["https://your-domain.com"]

[logging]
level = "warn"
format = "json"
file = "/var/log/mcp-server.log"
```

## Best Practices

1. **Never commit sensitive data**: Keep API keys in environment variables or separate, gitignored files
2. **Use different configs for different environments**: `mcp-config.dev.toml`, `mcp-config.prod.toml`
3. **Override with environment variables**: Use env vars for deployment-specific settings
4. **Enable only needed features**: Disable unused features for better performance
5. **Set appropriate rate limits**: Adjust based on your expected traffic
6. **Configure proper logging**: Use JSON format and file output in production
7. **Test configuration changes**: Always test config changes in development first

## Troubleshooting

If the server doesn't start with your configuration:

1. Check for TOML syntax errors:
```bash
cat mcp-config.toml | toml-test
```

2. Run with debug logging:
```bash
RUST_LOG=debug cargo run
```

3. Verify file permissions:
```bash
ls -la mcp-config.toml
```

4. Test with minimal config:
```bash
echo '[server]
port = 3000' > test-config.toml
MCP_CONFIG_PATH=test-config.toml cargo run
```