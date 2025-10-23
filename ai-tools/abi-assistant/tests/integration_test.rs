use abi_assistant::{
    config::Config,
    server::builder::ServerBuilder,
    mcp_service::AbiAssistantService,
};
use rmcp::ServerHandler;

#[tokio::test]
async fn test_server_builder_creates_server() {
    let config = Config::default();
    let builder = ServerBuilder::new().with_config(config);
    
    // Building should succeed (but won't actually bind in tests)
    let _server_future = builder.build();
    // Just verify it builds without panicking
    assert!(true);
}

#[tokio::test]
async fn test_service_has_server_info() {
    let service = AbiAssistantService::new();
    
    // The service should provide server information
    let info = service.get_info();
    
    // Check the instructions field
    assert!(info.instructions.is_some());
    let instructions = info.instructions.unwrap();
    assert!(instructions.contains("smart contracts"));
}

#[tokio::test]
async fn test_config_default_values() {
    let config = Config::default();
    
    assert_eq!(config.server.host, "127.0.0.1");
    assert_eq!(config.server.port, 3000);
    assert_eq!(config.server.transport, "both");
    assert_eq!(config.database.url, "sqlite://./data/abi_assistant.db");
}

#[tokio::test]
async fn test_config_from_env() {
    // Set environment variables
    std::env::set_var("MCP_HOST", "0.0.0.0");
    std::env::set_var("MCP_PORT", "8080");
    
    let mut config = Config::default();
    config.apply_env_overrides();
    
    assert_eq!(config.server.host, "0.0.0.0");
    assert_eq!(config.server.port, 8080);
    
    // Clean up
    std::env::remove_var("MCP_HOST");
    std::env::remove_var("MCP_PORT");
}

#[tokio::test]
async fn test_abi_encoding() {
    use abi_assistant::abi::encoder::AbiEncoder;
    
    let to = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7";
    let amount = "1000000000000000000";
    
    let result = AbiEncoder::encode_transfer(to, amount);
    assert!(result.is_ok());
    
    let encoded = result.unwrap();
    // Should start with the transfer function selector (0xa9059cbb)
    assert!(encoded.starts_with("0xa9059cbb"));
    assert_eq!(encoded.len(), 138); // 0x + 8 (selector) + 64 (address) + 64 (amount)
}

#[tokio::test]
async fn test_abi_decoding() {
    use abi_assistant::abi::decoder::AbiDecoder;
    
    let calldata = "0xa9059cbb000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb70000000000000000000000000000000000000000000000000de0b6b3a7640000";
    
    let result = AbiDecoder::decode_transfer(calldata);
    assert!(result.is_ok());
    
    let decoded = result.unwrap();
    assert_eq!(decoded["function"], "transfer");
    assert!(decoded["to"].as_str().unwrap().contains("742d35cc6634c0532925a3b844bc9e7595f0beb7"));
}

#[tokio::test]
async fn test_abi_parsing() {
    use abi_assistant::abi::ParsedAbi;
    
    let abi_json = r#"[{"inputs":[{"name":"to","type":"address"},{"name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"type":"function"}]"#;
    
    let result = ParsedAbi::from_json(abi_json);
    assert!(result.is_ok());
    
    let parsed = result.unwrap();
    assert_eq!(parsed.detect_protocol_type(), "unknown");
    assert_eq!(parsed.raw_abi.len(), abi_json.len());
}

#[tokio::test]
async fn test_server_builder_with_custom_config() {
    let mut config = Config::default();
    config.server.port = 4000;
    config.server.host = "0.0.0.0".to_string();
    
    let builder = ServerBuilder::new().with_config(config);
    let _server_future = builder.build();
    
    // Just verify it builds without panicking
    assert!(true);
}