use serde_json::{json, Value};

/// Handler for health check endpoint
pub async fn health_check() -> Value {
    json!({
        "status": "healthy",
        "version": env!("CARGO_PKG_VERSION"),
        "service": "abi-assistant"
    })
}

/// Handler for MCP info endpoint
pub async fn mcp_info() -> Value {
    json!({
        "protocolVersion": "1.0",
        "serverName": "ABI Assistant",
        "serverVersion": env!("CARGO_PKG_VERSION"),
        "capabilities": {
            "tools": true,
            "intents": true,
            "encoding": true,
            "decoding": true
        }
    })
}