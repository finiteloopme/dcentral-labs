# Examples

Quick examples for using the ABI Assistant MCP Server.

## Available Examples

### 1. Library Usage (Rust)
Use the MCP server as a Rust library in your own application.

```bash
# Run the example
cargo run --example library-usage

# View the code
cat library-usage.rs
```

### 2. cURL Client
Test the server using command-line HTTP requests.

```bash
cd curl-client/

# Quick test
./quick-test.sh

# Full demo
./mcp-curl-demo.sh
```

### 3. Gemini Agent
Connect Google's Gemini CLI to the MCP server.

```bash
cd gemini-agent/

# Setup and run
./run-gemini.sh
```

## Quick Start

1. **Start the server** (from project root):
```bash
cargo run
```

2. **Choose an example** and follow its README:
- [Rust Library Usage](library-usage.rs) - Embed the server in your app
- [cURL Examples](curl-client/README.md) - HTTP/SSE testing
- [Gemini Integration](gemini-agent/README.md) - AI agent integration

## Server Endpoints

Default server runs at `http://127.0.0.1:3000` with:
- `/health` - Health check
- `/sse` - Server-Sent Events
- `/` - HTTP streaming (MCP protocol)

## Need Help?

- Check individual example READMEs for detailed instructions
- Server configuration: See [CONFIG.md](../CONFIG.md)
- Main documentation: See [README.md](../README.md)