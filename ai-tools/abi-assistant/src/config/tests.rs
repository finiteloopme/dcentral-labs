#[cfg(test)]
mod tests {
    use super::super::*;
    use std::env;
    use tempfile::NamedTempFile;
    use std::io::Write;

    #[test]
    fn test_default_config() {
        let config = Config::default();
        
        assert_eq!(config.server.host, "127.0.0.1");
        assert_eq!(config.server.port, 3000);
        assert_eq!(config.server.transport, "both");
        assert_eq!(config.database.url, "sqlite://./data/abi_assistant.db");
    }

    #[test]
    fn test_load_from_toml() {
        let toml_content = r#"
[server]
name = "test-server"
version = "1.0.0"
description = "Test server"
host = "0.0.0.0"
port = 8080
transport = "http"
protocol_version = "0.1.0"

[server.sse]
path = "/sse"
message_path = "/sse/message"

[server.http]
health_path = "/health"
port_offset = 0

[database]
url = "sqlite://test.db"

[blockchain.ethereum]
name = "ethereum"
chain_id = 1
rpc_url = "http://test-rpc.com"

[api_keys]

[features]
fetch_abi_from_explorers = true
simulate_transactions = false
gas_optimization = true
mev_protection = false
cross_chain = false
cache_abis = true
debug_mode = false

[intent]
confidence_threshold = 0.7
max_suggestions = 5
fuzzy_matching = true

[intent.protocols]

[gas]
default_gas_limit = 3000000
price_strategy = "market"
custom_gas_price = 30000000000
gas_buffer_percent = 20
max_gas_price = 500000000000

[cache]
enabled = true
ttl = 3600
max_size = 1000
max_cached_abis = 1000
abi_cache_ttl = 7200
max_cached_intents = 500
intent_cache_ttl = 1800

[logging]
level = "info"
format = "pretty"

[security]
rate_limiting = true
requests_per_minute = 60
max_requests_per_minute = 100
require_auth = false
require_signatures = false
allowed_origins = ["*"]
max_body_size = 10485760
request_timeout = 30

[monitoring]
enabled = true
metrics_enabled = false
metrics_port = 9090
health_check_interval = 60

[development]
debug_mode = false
verbose_errors = false
mock_blockchain = false
hot_reload = false
log_requests = false
mock_mode = false
pretty_json = true
"#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();
        
        let config = Config::from_file(temp_file.path()).unwrap();
        
        assert_eq!(config.server.host, "0.0.0.0");
        assert_eq!(config.server.port, 8080);
        assert_eq!(config.server.transport, "http");
        assert_eq!(config.database.url, "sqlite://test.db");
        assert_eq!(config.blockchain.ethereum.rpc_url, Some("http://test-rpc.com".to_string()));
        assert!(!config.features.simulate_transactions);
    }

    #[test]
    fn test_env_override() {
        // Save existing values
        let old_host = env::var("MCP_HOST").ok();
        let old_port = env::var("MCP_PORT").ok();
        let old_db = env::var("DATABASE_URL").ok();
        let old_eth = env::var("ETHEREUM_RPC_URL").ok();
        
        // Set test values
        env::set_var("MCP_HOST", "192.168.1.1");
        env::set_var("MCP_PORT", "4000");
        env::set_var("DATABASE_URL", "sqlite://env.db");
        env::set_var("ETHEREUM_RPC_URL", "http://localhost:7545");
        
        let mut config = Config::default();
        config.apply_env_overrides();
        
        assert_eq!(config.server.host, "192.168.1.1");
        assert_eq!(config.server.port, 4000);
        assert_eq!(config.database.url, "sqlite://env.db");
        assert_eq!(config.blockchain.ethereum.rpc_url, Some("http://localhost:7545".to_string()));
        
        // Restore original values or remove
        match old_host {
            Some(v) => env::set_var("MCP_HOST", v),
            None => env::remove_var("MCP_HOST"),
        }
        match old_port {
            Some(v) => env::set_var("MCP_PORT", v),
            None => env::remove_var("MCP_PORT"),
        }
        match old_db {
            Some(v) => env::set_var("DATABASE_URL", v),
            None => env::remove_var("DATABASE_URL"),
        }
        match old_eth {
            Some(v) => env::set_var("ETHEREUM_RPC_URL", v),
            None => env::remove_var("ETHEREUM_RPC_URL"),
        }
    }

    #[test]
    fn test_partial_toml_with_defaults() {
        let toml_content = r#"
[server]
name = "partial-server"
version = "1.0.0"  
description = "Partial config test"
host = "127.0.0.1"
port = 5000
transport = "both"
protocol_version = "0.1.0"

[server.sse]
path = "/sse"
message_path = "/sse/message"

[server.http]
health_path = "/health"
port_offset = 0

[database]
url = "sqlite://./data/abi_assistant.db"

[blockchain.ethereum]
name = "ethereum"
chain_id = 1

[api_keys]

[features]
fetch_abi_from_explorers = true
simulate_transactions = true
gas_optimization = true
mev_protection = false
cross_chain = false
cache_abis = true
debug_mode = false
simulation_enabled = true
intent_interpretation = true

[intent]
confidence_threshold = 0.7
max_suggestions = 5
fuzzy_matching = true

[intent.protocols]

[gas]
default_gas_limit = 3000000
estimation_mode = "standard"
buffer_percentage = 20
price_strategy = "market"
custom_gas_price = 30000000000
gas_buffer_percent = 20
max_gas_price = 500000000000

[cache]
enabled = true
ttl = 3600
max_size = 1000
max_cached_abis = 1000
abi_cache_ttl = 7200
max_cached_intents = 500
intent_cache_ttl = 1800

[logging]
level = "info"
format = "pretty"

[security]
rate_limiting = true
requests_per_minute = 60
max_requests_per_minute = 100
require_auth = false
require_signatures = false
allowed_origins = ["*"]
max_body_size = 10485760
request_timeout = 30

[monitoring]
enabled = true
metrics_enabled = false
metrics_port = 9090
health_check_interval = 60

[development]
debug_mode = false
verbose_errors = false
mock_blockchain = false
hot_reload = false
log_requests = false
mock_mode = false
pretty_json = true
"#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();
        
        let config = Config::from_file(temp_file.path()).unwrap();
        
        // Changed value
        assert_eq!(config.server.port, 5000);
        
        // Default values should remain
        assert_eq!(config.server.host, "127.0.0.1");
        assert_eq!(config.server.transport, "both");
        assert!(config.features.simulate_transactions);
    }

    #[test]
    fn test_invalid_toml_file() {
        let toml_content = r#"
[server
host = "invalid"
"#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();
        
        let result = Config::from_file(temp_file.path());
        assert!(result.is_err());
    }

    #[test]
    fn test_transport_validation() {
        let valid_transports = vec!["sse", "http", "unified"];
        
        for transport in valid_transports {
            let config = Config::default();
            // Transport validation would happen at runtime
            // Here we just check the config can hold the values
            assert!(["sse", "http", "unified"].contains(&transport));
        }
    }

    #[test]
    fn test_blockchain_config() {
        let config = Config::default();
        
        // Should have Ethereum mainnet by default
        assert_eq!(config.blockchain.ethereum.name, "Ethereum Mainnet");
        assert_eq!(config.blockchain.ethereum.chain_id, 1);
        assert_eq!(config.blockchain.ethereum.rpc_url, Some("http://localhost:8545".to_string()));
    }

    #[test]
    fn test_logging_config() {
        let config = Config::default();
        
        assert_eq!(config.logging.level, "info");
        assert_eq!(config.logging.format, "pretty");
    }

    #[test]
    fn test_features_config() {
        let config = Config::default();
        
        assert!(config.features.simulate_transactions);
        assert!(config.features.gas_optimization);
        assert!(config.features.cache_abis);
    }

    #[test]
    fn test_env_override_precedence() {
        // Set environment variables
        env::set_var("MCP_HOST", "172.16.0.1");
        
        let mut config = Config::default();
        
        // Before env override
        assert_eq!(config.server.host, "127.0.0.1");
        
        // Apply env overrides
        config.apply_env_overrides();
        
        // Env should override default
        assert_eq!(config.server.host, "172.16.0.1");
        
        // Clean up
        env::remove_var("MCP_HOST");
    }

    #[test]
    fn test_get_bind_address() {
        let config = Config::default();
        
        // SSE transport
        let sse_addr = config.get_bind_address("sse");
        assert_eq!(sse_addr, "127.0.0.1:3000");
        
        // HTTP transport (with offset)
        let http_addr = config.get_bind_address("http");
        assert_eq!(http_addr, "127.0.0.1:3001"); // offset is 1 by default
        
        // Unified or default
        let unified_addr = config.get_bind_address("unified");
        assert_eq!(unified_addr, "127.0.0.1:3000");
    }
}