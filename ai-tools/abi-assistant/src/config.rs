use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::Path;
use std::fs;
use std::env;

/// Main configuration structure
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Config {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub blockchain: BlockchainConfig,
    pub api_keys: ApiKeysConfig,
    pub features: FeaturesConfig,
    pub intent: IntentConfig,
    pub gas: GasConfig,
    pub cache: CacheConfig,
    pub logging: LoggingConfig,
    pub security: SecurityConfig,
    pub monitoring: MonitoringConfig,
    pub development: DevelopmentConfig,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ServerConfig {
    pub name: String,
    pub version: String,
    pub description: String,
    pub host: String,
    pub port: u16,
    pub transport: String,
    pub protocol_version: String,
    pub sse: SseConfig,
    pub http: HttpConfig,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SseConfig {
    pub path: String,
    pub message_path: String,
    pub keep_alive_interval: Option<u64>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct HttpConfig {
    pub health_path: String,
    pub port_offset: u16,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct DatabaseConfig {
    pub url: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct BlockchainConfig {
    pub ethereum: ChainConfig,
    pub polygon: Option<ChainConfig>,
    pub arbitrum: Option<ChainConfig>,
    pub optimism: Option<ChainConfig>,
    pub base: Option<ChainConfig>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ChainConfig {
    pub rpc_url: Option<String>,
    pub chain_id: u64,
    pub name: String,
    pub enabled: Option<bool>,
    pub backup_rpcs: Option<Vec<String>>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ApiKeysConfig {
    pub etherscan_api_key: Option<String>,
    pub polygonscan_api_key: Option<String>,
    pub arbiscan_api_key: Option<String>,
    pub optimistic_etherscan_api_key: Option<String>,
    pub basescan_api_key: Option<String>,
    pub infura_api_key: Option<String>,
    pub alchemy_api_key: Option<String>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct FeaturesConfig {
    pub fetch_abi_from_explorers: bool,
    pub simulate_transactions: bool,
    pub gas_optimization: bool,
    pub mev_protection: bool,
    pub cross_chain: bool,
    pub cache_abis: bool,
    pub debug_mode: bool,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct IntentConfig {
    #[serde(default = "default_intent_strategy")]
    pub strategy: String,
    pub confidence_threshold: f64,
    pub max_suggestions: usize,
    pub fuzzy_matching: bool,
    pub protocols: HashMap<String, Vec<String>>,
    #[serde(default)]
    pub gemini: Option<GeminiConfig>,
}

fn default_intent_strategy() -> String {
    "gemini_first".to_string()
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct GeminiConfig {
    pub enabled: bool,
    pub api_key: String,
    pub model: String,
    pub timeout: u64,
    pub max_retries: u32,
    pub prompt_file: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct GasConfig {
    pub default_gas_limit: u64,
    pub price_strategy: String,
    pub custom_gas_price: u64,
    pub gas_buffer_percent: u8,
    pub max_gas_price: u64,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct CacheConfig {
    pub enabled: bool,
    pub ttl: u64,
    pub max_size: usize,
    pub max_cached_abis: usize,
    pub abi_cache_ttl: u64,
    pub max_cached_intents: usize,
    pub intent_cache_ttl: u64,
    #[serde(default = "default_normalize_queries")]
    pub normalize_queries: bool,
}

fn default_normalize_queries() -> bool {
    true
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
    pub file: Option<String>,
    pub max_file_size: Option<u64>,
    pub max_backups: Option<usize>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SecurityConfig {
    pub rate_limiting: bool,
    pub max_requests_per_minute: u32,
    pub require_signatures: bool,
    pub allowed_origins: Vec<String>,
    pub max_body_size: usize,
    pub request_timeout: u64,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct MonitoringConfig {
    pub enabled: bool,
    pub format: Option<String>,
    pub endpoint: Option<String>,
    pub detailed_metrics: Option<bool>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct DevelopmentConfig {
    pub hot_reload: bool,
    pub log_requests: bool,
    pub mock_mode: bool,
    pub pretty_json: bool,
    pub test_wallets: Option<TestWallets>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct TestWallets {
    pub alice: String,
    pub bob: String,
    pub charlie: String,
}

impl Config {
    /// Load configuration from file with environment variable overrides
    pub fn load() -> anyhow::Result<Self> {
        // Try to load from custom config file first
        let config_path = env::var("MCP_CONFIG_PATH")
            .unwrap_or_else(|_| "mcp-config.toml".to_string());
        
        let config = if Path::new(&config_path).exists() {
            let contents = fs::read_to_string(&config_path)?;
            toml::from_str(&contents)?
        } else if Path::new("mcp-default-config.toml").exists() {
            // Fall back to default config
            let contents = fs::read_to_string("mcp-default-config.toml")?;
            toml::from_str(&contents)?
        } else {
            // Use built-in defaults
            Self::default()
        };
        
        // Apply environment variable overrides
        Ok(config.with_env_overrides())
    }
    
    /// Load config from a specific file path (for testing)
    pub fn from_file(path: &Path) -> anyhow::Result<Self> {
        let contents = fs::read_to_string(path)?;
        let config: Config = toml::from_str(&contents)?;
        
        // Merge with defaults for missing fields
        // let default_config = Self::default();
        
        // If the loaded config is missing some fields, use defaults
        // This is a simple implementation - in production you might want
        // a more sophisticated merge strategy
        Ok(config)
    }
    
    /// Apply environment variable overrides
    fn with_env_overrides(mut self) -> Self {
        // Server overrides
        if let Ok(port) = env::var("MCP_PORT") {
            if let Ok(port) = port.parse() {
                self.server.port = port;
            }
        }
        
        if let Ok(transport) = env::var("MCP_TRANSPORT") {
            self.server.transport = transport;
        }
        
        // Database override
        if let Ok(db_url) = env::var("DATABASE_URL") {
            self.database.url = db_url;
        }
        
        // Blockchain RPC overrides
        if let Ok(eth_rpc) = env::var("ETH_RPC_URL") {
            self.blockchain.ethereum.rpc_url = Some(eth_rpc);
        }
        
        if let Ok(polygon_rpc) = env::var("POLYGON_RPC_URL") {
            if let Some(ref mut polygon) = self.blockchain.polygon {
                polygon.rpc_url = Some(polygon_rpc);
                polygon.enabled = Some(true);
            }
        }
        
        if let Ok(arb_rpc) = env::var("ARBITRUM_RPC_URL") {
            if let Some(ref mut arbitrum) = self.blockchain.arbitrum {
                arbitrum.rpc_url = Some(arb_rpc);
                arbitrum.enabled = Some(true);
            }
        }
        
        if let Ok(opt_rpc) = env::var("OPTIMISM_RPC_URL") {
            if let Some(ref mut optimism) = self.blockchain.optimism {
                optimism.rpc_url = Some(opt_rpc);
                optimism.enabled = Some(true);
            }
        }
        
        // API key overrides
        if let Ok(key) = env::var("ETHERSCAN_API_KEY") {
            self.api_keys.etherscan_api_key = Some(key);
        }
        
        if let Ok(key) = env::var("INFURA_API_KEY") {
            self.api_keys.infura_api_key = Some(key);
        }
        
        // Logging level override
        if let Ok(level) = env::var("RUST_LOG") {
            self.logging.level = level;
        }
        
        self
    }
    
    /// Apply environment variable overrides (public for testing)
    pub fn apply_env_overrides(&mut self) {
        // Server overrides
        if let Ok(host) = env::var("MCP_HOST") {
            self.server.host = host;
        }
        
        if let Ok(port) = env::var("MCP_PORT") {
            if let Ok(port) = port.parse() {
                self.server.port = port;
            }
        }
        
        if let Ok(transport) = env::var("MCP_TRANSPORT") {
            self.server.transport = transport;
        }
        
        // Database override
        if let Ok(url) = env::var("DATABASE_URL") {
            self.database.url = url;
        }
        
        // Chain RPC overrides
        if let Ok(url) = env::var("ETHEREUM_RPC_URL") {
            self.blockchain.ethereum.rpc_url = Some(url);
        }
        
        if let Ok(url) = env::var("POLYGON_RPC_URL") {
            if let Some(ref mut polygon) = self.blockchain.polygon {
                polygon.rpc_url = Some(url);
            }
        }
        
        // Logging level override
        if let Ok(level) = env::var("RUST_LOG") {
            self.logging.level = level;
        }
    }
    
    /// Get the bind address for a specific transport
    pub fn get_bind_address(&self, transport: &str) -> String {
        match transport {
            "sse" => format!("{}:{}", self.server.host, self.server.port),
            "http" => {
                let http_port = self.server.port + self.server.http.port_offset;
                format!("{}:{}", self.server.host, http_port)
            },
            _ => format!("{}:{}", self.server.host, self.server.port),
        }
    }
}

#[cfg(test)]
mod tests;

impl Default for Config {
    fn default() -> Self {
        Self {
            server: ServerConfig {
                name: "abi-assistant".to_string(),
                version: "0.1.0".to_string(),
                description: "An MCP server for interacting with EVM smart contracts through natural language".to_string(),
                host: "127.0.0.1".to_string(),
                port: 3000,
                transport: "both".to_string(),
                protocol_version: "2024-11-05".to_string(),
                sse: SseConfig {
                    path: "/sse".to_string(),
                    message_path: "/message".to_string(),
                    keep_alive_interval: None,
                },
                http: HttpConfig {
                    health_path: "/health".to_string(),
                    port_offset: 1,
                },
            },
            database: DatabaseConfig {
                url: "sqlite://./data/abi_assistant.db".to_string(),
            },
            blockchain: BlockchainConfig {
                ethereum: ChainConfig {
                    rpc_url: Some("http://localhost:8545".to_string()),
                    chain_id: 1,
                    name: "Ethereum Mainnet".to_string(),
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
                strategy: default_intent_strategy(),
                confidence_threshold: 0.7,
                max_suggestions: 3,
                fuzzy_matching: true,
                protocols: HashMap::new(),
                gemini: None,
            },
            gas: GasConfig {
                default_gas_limit: 150000,
                price_strategy: "standard".to_string(),
                custom_gas_price: 30,
                gas_buffer_percent: 20,
                max_gas_price: 500,
            },
            cache: CacheConfig {
                enabled: true,
                ttl: 3600,
                max_size: 1000,
                max_cached_abis: 100,
                abi_cache_ttl: 3600,
                max_cached_intents: 50,
                intent_cache_ttl: 300,
                normalize_queries: default_normalize_queries(),
            },
            logging: LoggingConfig {
                level: "info".to_string(),
                format: "pretty".to_string(),
                file: None,
                max_file_size: None,
                max_backups: None,
            },
            security: SecurityConfig {
                rate_limiting: true,
                max_requests_per_minute: 60,
                require_signatures: false,
                allowed_origins: vec!["*".to_string()],
                max_body_size: 1048576,
                request_timeout: 30,
            },
            monitoring: MonitoringConfig {
                enabled: false,
                format: None,
                endpoint: None,
                detailed_metrics: None,
            },
            development: DevelopmentConfig {
                hot_reload: false,
                log_requests: false,
                mock_mode: false,
                pretty_json: true,
                test_wallets: None,
            },
        }
    }
}