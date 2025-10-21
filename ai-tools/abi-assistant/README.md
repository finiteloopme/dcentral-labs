# ABI Assistant

MCP server for Web3 agents to interact with EVM smart contracts through natural language intents.

## Overview

ABI Assistant bridges AI agents and blockchain smart contracts by:
- Interpreting natural language intents into contract calls
- Managing and validating contract ABIs
- Encoding/decoding transaction data
- Providing DeFi-specific utilities

## Quick Start

```bash
# Clone and enter the project
git clone https://github.com/yourusername/abi-assistant.git
cd abi-assistant

# Setup (builds container and initializes project)
make setup

# Configure environment (if not already done)
cp .env.example .env
# Edit .env with your RPC endpoints and API keys

# Run development server
make dev

# In another terminal, run tests
make test
```

### Alternative: Using Podman Compose

```bash
# Start development environment with auto-reload
podman-compose up dev

# Or run in background
podman-compose up -d dev
```

## Project Structure

```
abi-assistant/
├── src/                    # Rust source code
│   ├── server/            # MCP server implementation
│   ├── intent/            # Intent interpretation engine
│   ├── abi/               # ABI parsing and encoding
│   ├── protocol/          # Dynamic protocol discovery
│   └── tools/             # MCP tool definitions
├── scripts/               # Build and operational scripts
├── resources/             # Static resources
│   ├── abis/             # Pre-loaded contract ABIs
│   └── protocols/        # Protocol configurations
└── tests/                # Test suites
```

## Installation

### Prerequisites

- Podman (or Docker)
- Make

**Note**: All dependencies (Rust, SQLite, etc.) are handled within containers. No local installation required!

### Setup

```bash
# Clone repository
git clone https://github.com/yourusername/abi-assistant.git
cd abi-assistant

# Setup everything (builds container, creates directories, initializes DB)
make setup

# Configure environment
cp .env.example .env
# Edit .env with your RPC endpoints and API keys
```

### Using Podman Compose

```bash
# Start production server
podman-compose up abi-assistant

# Start development environment
podman-compose up dev

# Run in background
podman-compose up -d
```

## Usage

### Development (Container-based)

```bash
make dev          # Start development server in container
make test         # Run all tests in container
make lint         # Run linter in container
make format       # Format code in container

# Enter container shell for debugging
make container-shell

# View container logs
podman logs -f abi-assistant-dev
```

### Working with ABIs

```bash
make abi-fetch    # Fetch common protocol ABIs
make abi-validate # Validate stored ABIs
```

### Database

```bash
make db-setup     # Initialize database
make db-migrate   # Run migrations
make db-reset     # Reset database
```

## MCP Tools

### Intent Interpretation
- `interpret_intent` - Convert natural language to contract calls
- `find_best_path` - Find optimal execution path for intent

### ABI Management
- `parse_abi` - Validate and parse ABI JSON
- `store_abi` - Store ABI with metadata
- `search_abi` - Find ABIs by various criteria

### Contract Interaction
- `encode_function_call` - Encode function calls
- `decode_transaction` - Decode transaction data
- `estimate_gas` - Estimate transaction gas

### Protocol Discovery
- `discover_protocol` - Auto-detect protocol type from contract
- `analyze_protocol` - Classify protocol patterns
- `register_protocol` - Add protocol to registry

### Transaction Construction
- `build_transaction` - Create unsigned transactions
- `export_for_signing` - Export in multiple formats
- `simulate_transaction` - Test before execution

## Examples

### Interpreting Intent

```json
{
  "tool": "interpret_intent",
  "params": {
    "intent": "swap 100 USDC for ETH",
    "context": {
      "chain": "ethereum",
      "wallet": "0x..."
    }
  }
}
```

Response:
```json
{
  "protocol": "Uniswap V3",
  "contract": "0xE592427A0AEce92De3Edee1F18E0157C05861564",
  "function": "exactInputSingle",
  "parameters": {
    "tokenIn": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    "tokenOut": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    "fee": 3000,
    "recipient": "0x...",
    "amountIn": "100000000",
    "amountOutMinimum": "0",
    "sqrtPriceLimitX96": "0"
  }
}
```

### Encoding Function Call

```json
{
  "tool": "encode_function_call",
  "params": {
    "abi": "...",
    "function": "transfer",
    "args": ["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", "1000000000000000000"]
  }
}
```

## Configuration

Environment variables (`.env`):

```bash
# RPC Endpoints
ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY

# API Keys
ETHERSCAN_API_KEY=YOUR_KEY

# Database
DATABASE_URL=sqlite://./data/abi_assistant.db

# Server
MCP_HOST=127.0.0.1
MCP_PORT=3000
```

## Testing

```bash
# Run all tests
make test

# Run specific test suites
make test-unit        # Unit tests only
make test-integration # Integration tests
make test-forked      # Forked mainnet tests
```

## Building

```bash
# Development build
make build-debug

# Production build
make build

# Docker image
make docker-build
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`make test`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

MIT

## Support

For issues and questions:
- GitHub Issues: [github.com/yourusername/abi-assistant/issues](https://github.com/yourusername/abi-assistant/issues)
- Documentation: [docs/](./docs/)