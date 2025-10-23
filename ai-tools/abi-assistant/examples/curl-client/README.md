# cURL Client Examples

Test the MCP server using cURL commands.

## Quick Start

1. **Start the server** (from project root):
```bash
cargo run
```

2. **Run quick test**:
```bash
./quick-test.sh
```

3. **Run full demo**:
```bash
./mcp-curl-demo.sh
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `quick-test.sh` | Quick connectivity test (7 checks) |
| `mcp-curl-demo.sh` | Complete feature demonstration |
| `defi-operations.sh` | DeFi-specific examples |

## Basic Usage

### Health Check
```bash
curl http://127.0.0.1:3000/health
```

### List Tools
```bash
curl -X POST http://127.0.0.1:3000/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

### Call a Tool
```bash
curl -X POST http://127.0.0.1:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "params":{
      "name":"interpret_intent",
      "arguments":{"intent":"swap ETH for USDC"}
    },
    "id":2
  }'
```

## Available Tools

- `interpret_intent` - Convert natural language to contract calls
- `encode_function_call` - Encode smart contract functions
- `decode_transaction` - Decode transaction data
- `estimate_gas` - Estimate gas costs

## Tips

- Use `jq` for pretty JSON output: `curl ... | jq`
- Set custom server URL: `MCP_SERVER_URL=http://localhost:8080 ./mcp-curl-demo.sh`
- Enable verbose mode: `VERBOSE=true ./mcp-curl-demo.sh`

## Troubleshooting

Server not responding?
```bash
# Check if running
curl http://127.0.0.1:3000/health

# Check logs
RUST_LOG=debug cargo run
```