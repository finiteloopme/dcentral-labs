use serde::{Deserialize, Serialize};
use std::fs;
use std::env;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub server: ServerConfig,
    pub blockchain: BlockchainConfig,
    pub contracts: ContractsConfig,
    pub proof_server: ProofServerConfig,
    pub tee: TeeConfig,
    pub compliance: ComplianceConfig,
    pub logging: LoggingConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub port: u16,
    pub host: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockchainConfig {
    pub arc_rpc_url: String,
    pub midnight_rpc_url: String,
    pub chain_id: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractsConfig {
    pub mock_usdc: String,
    pub defi_vault: String,
    pub compliance_registry: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofServerConfig {
    pub url: String,
    pub timeout_ms: u64,
    pub mode: ProofMode,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ProofMode {
    Mock,
    Production,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TeeConfig {
    pub private_key_env: String,
    pub attestation_enabled: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComplianceConfig {
    pub concentration_limit_percent: u64,
    pub max_deposit_amount: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
}

impl Config {
    pub fn load() -> Result<Self, Box<dyn std::error::Error>> {
        let config_path = env::var("CONFIG_PATH")
            .unwrap_or_else(|_| "config.toml".to_string());
        
        let config_content = fs::read_to_string(&config_path)?;
        let config: Config = toml::from_str(&config_content)?;
        
        Ok(config)
    }
    
    pub fn load_from_env() -> Self {
        Config {
            server: ServerConfig {
                port: env::var("PORT")
                    .unwrap_or_else(|_| "8080".to_string())
                    .parse()
                    .unwrap_or(8080),
                host: env::var("HOST")
                    .unwrap_or_else(|_| "0.0.0.0".to_string()),
            },
            blockchain: BlockchainConfig {
                arc_rpc_url: env::var("ARC_RPC_URL")
                    .unwrap_or_else(|_| "http://anvil:8545".to_string()),
                midnight_rpc_url: env::var("MIDNIGHT_RPC_URL")
                    .unwrap_or_else(|_| "http://midnight-node:9944".to_string()),
                chain_id: env::var("CHAIN_ID")
                    .unwrap_or_else(|_| "31337".to_string())
                    .parse()
                    .unwrap_or(31337),
            },
            contracts: ContractsConfig {
                mock_usdc: env::var("MOCK_USDC_ADDRESS")
                    .unwrap_or_else(|_| "0x5FbDB2315678afecb367f032d93F642f64180aa3".to_string()),
                defi_vault: env::var("DEFI_VAULT_ADDRESS")
                    .unwrap_or_else(|_| "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512".to_string()),
                compliance_registry: env::var("COMPLIANCE_REGISTRY_ADDRESS")
                    .unwrap_or_else(|_| "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0".to_string()),
            },
            proof_server: ProofServerConfig {
                url: env::var("PROOF_SERVER_URL")
                    .unwrap_or_else(|_| "http://proof-server:6300".to_string()),
                timeout_ms: env::var("PROOF_SERVER_TIMEOUT_MS")
                    .unwrap_or_else(|_| "30000".to_string())
                    .parse()
                    .unwrap_or(30000),
                mode: match env::var("PROOF_MODE").unwrap_or_else(|_| "mock".to_string()).as_str() {
                    "production" => ProofMode::Production,
                    _ => ProofMode::Mock,
                },
            },
            tee: TeeConfig {
                private_key_env: env::var("TEE_PRIVATE_KEY_ENV")
                    .unwrap_or_else(|_| "TEE_PRIVATE_KEY".to_string()),
                attestation_enabled: env::var("TEE_ATTESTATION_ENABLED")
                    .unwrap_or_else(|_| "true".to_string())
                    .parse()
                    .unwrap_or(true),
            },
            compliance: ComplianceConfig {
                concentration_limit_percent: env::var("CONCENTRATION_LIMIT_PERCENT")
                    .unwrap_or_else(|_| "10".to_string())
                    .parse()
                    .unwrap_or(10),
                max_deposit_amount: env::var("MAX_DEPOSIT_AMOUNT")
                    .unwrap_or_else(|_| "1000000".to_string())
                    .parse()
                    .unwrap_or(1000000),
            },
            logging: LoggingConfig {
                level: env::var("LOG_LEVEL")
                    .unwrap_or_else(|_| "info".to_string()),
                format: env::var("LOG_FORMAT")
                    .unwrap_or_else(|_| "json".to_string()),
            },
        }
    }
}