/// Example: Using abi-assistant as a library
/// 
/// This example demonstrates how to use the abi-assistant MCP server
/// as a library in your own Rust application.

use abi_assistant::{
    server::Server,
    config::Config,
    mcp_service::AbiAssistantService,
};
use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    // Example 1: Simple server with default configuration
    simple_server().await?;
    
    // Example 2: Custom configuration
    // custom_config_server().await?;
    
    // Example 3: Custom service factory
    // custom_service_server().await?;
    
    // Example 4: Programmatic server without database
    // programmatic_server().await?;
    
    Ok(())
}

/// Example 1: Simple server with default configuration
async fn simple_server() -> Result<()> {
    println!("Starting simple server with defaults...");
    
    let server = Server::builder()
        .with_default_config()?
        .build()
        .await?;
    
    server.run().await?;
    Ok(())
}

/// Example 2: Server with custom configuration
#[allow(dead_code)]
async fn custom_config_server() -> Result<()> {
    println!("Starting server with custom configuration...");
    
    // Create custom configuration
    let mut config = Config::load()?;
    config.server.port = 8080;
    config.server.transport = "http".to_string();
    
    let server = Server::builder()
        .with_config(config)
        .build()
        .await?;
    
    server.run().await?;
    Ok(())
}

/// Example 3: Server with custom service factory
#[allow(dead_code)]
async fn custom_service_server() -> Result<()> {
    println!("Starting server with custom service factory...");
    
    let server = Server::builder()
        .with_default_config()?
        .with_service_factory(|| {
            // You could customize the service here
            println!("Creating custom service instance");
            AbiAssistantService::new()
        })
        .build()
        .await?;
    
    server.run().await?;
    Ok(())
}

/// Example 4: Programmatic server for testing/development
#[allow(dead_code)]
async fn programmatic_server() -> Result<()> {
    println!("Starting programmatic server...");
    
    let server = Server::builder()
        .with_default_config()?
        .init_logging(true)      // Initialize logging
        .init_database(false)    // Skip database initialization
        .log_config(false)       // Don't log configuration
        .build()
        .await?;
    
    // You can also run specific transport modes
    // server.run_sse().await?;
    // server.run_http().await?;
    // server.run_unified().await?;
    
    server.run().await?;
    Ok(())
}

/// Example 5: Server with custom configuration from code
#[allow(dead_code)]
async fn fully_custom_server() -> Result<()> {
    use abi_assistant::config::*;
    use std::collections::HashMap;
    
    println!("Starting fully custom server...");
    
    // Build configuration programmatically
    let config = Config {
        server: ServerConfig {
            name: "my-mcp-server".to_string(),
            version: "1.0.0".to_string(),
            description: "Custom MCP Server".to_string(),
            host: "0.0.0.0".to_string(),
            port: 9000,
            transport: "unified".to_string(),
            protocol_version: "2024-11-05".to_string(),
            sse: SseConfig {
                path: "/events".to_string(),
                message_path: "/msg".to_string(),
                keep_alive_interval: Some(30),
            },
            http: HttpConfig {
                health_path: "/status".to_string(),
                port_offset: 0, // Same port for unified mode
            },
        },
        database: DatabaseConfig {
            url: "sqlite://./custom.db".to_string(),
        },
        blockchain: BlockchainConfig {
            ethereum: ChainConfig {
                rpc_url: Some("https://eth.llamarpc.com".to_string()),
                chain_id: 1,
                name: "Ethereum".to_string(),
                enabled: Some(true),
                backup_rpcs: None,
            },
            polygon: None,
            arbitrum: None,
            optimism: None,
            base: None,
        },
        api_keys: ApiKeysConfig {
            etherscan_api_key: None,
            polygonscan_api_key: None,
            arbiscan_api_key: None,
            optimistic_etherscan_api_key: None,
            basescan_api_key: None,
            infura_api_key: None,
            alchemy_api_key: None,
        },
        features: FeaturesConfig {
            fetch_abi_from_explorers: true,
            simulate_transactions: true,
            gas_optimization: true,
            mev_protection: false,
            cross_chain: false,
            cache_abis: true,
            debug_mode: false,
        },
        intent: IntentConfig {
            confidence_threshold: 0.8,
            max_suggestions: 5,
            fuzzy_matching: true,
            protocols: HashMap::new(),
        },
        gas: GasConfig {
            default_gas_limit: 200000,
            price_strategy: "fast".to_string(),
            custom_gas_price: 50,
            gas_buffer_percent: 15,
            max_gas_price: 1000,
        },
        cache: CacheConfig {
            enabled: true,
            max_cached_abis: 200,
            abi_cache_ttl: 7200,
            max_cached_intents: 100,
            intent_cache_ttl: 600,
        },
        logging: LoggingConfig {
            level: "debug".to_string(),
            format: "pretty".to_string(),
            file: None,
            max_file_size: None,
            max_backups: None,
        },
        security: SecurityConfig {
            rate_limiting: true,
            max_requests_per_minute: 120,
            require_signatures: false,
            allowed_origins: vec!["*".to_string()],
            max_body_size: 2097152,
            request_timeout: 60,
        },
        monitoring: MonitoringConfig {
            enabled: false,
            format: None,
            endpoint: None,
            detailed_metrics: None,
        },
        development: DevelopmentConfig {
            hot_reload: false,
            log_requests: true,
            mock_mode: false,
            pretty_json: true,
            test_wallets: None,
        },
    };
    
    let server = Server::builder()
        .with_config(config)
        .build()
        .await?;
    
    server.run().await?;
    Ok(())
}