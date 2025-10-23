use crate::intent::IntentCategory;
use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

/// Protocol discovery interface for finding capable protocols dynamically
#[async_trait]
pub trait ProtocolDiscovery: Send + Sync {
    /// List all available protocols
    async fn list_available_protocols(&self) -> Result<Vec<ProtocolInfo>>;
    
    /// Find protocols capable of handling a specific intent type
    async fn find_capable_protocols(&self, intent_type: &IntentCategory) -> Result<Vec<ProtocolCapability>>;
    
    /// Get detailed information about a specific protocol
    async fn get_protocol_details(&self, protocol_id: &str) -> Result<Option<ProtocolDetails>>;
    
    /// Check if a protocol supports specific parameters
    fn supports_parameters(&self, protocol: &ProtocolInfo, params: &serde_json::Map<String, serde_json::Value>) -> bool;
    
    /// Discover new protocols from various sources
    async fn discover_from_source(&self, source: DiscoverySource) -> Result<Vec<ProtocolInfo>>;
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolInfo {
    pub id: String,
    pub name: String,
    pub version: String,
    pub chain_id: u32,
    pub supported_operations: Vec<IntentCategory>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolCapability {
    pub name: String,
    pub address: Option<String>,
    pub suggested_function: String,
    pub gas_estimate: Option<u64>,
    pub required_parameters: Vec<String>,
    pub optional_parameters: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolDetails {
    pub info: ProtocolInfo,
    pub contract_addresses: Vec<ContractInfo>,
    pub abi_source: String,
    pub audit_status: AuditStatus,
    pub tvl: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractInfo {
    pub address: String,
    pub contract_type: String,
    pub verified: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AuditStatus {
    Audited { by: Vec<String>, date: String },
    NotAudited,
    InProgress,
}

#[derive(Debug, Clone)]
pub enum DiscoverySource {
    LocalRegistry,
    OnChain { rpc_url: String },
    GraphProtocol { endpoint: String },
    DefiLlama,
    Etherscan { api_key: String },
    Community { registry_url: String },
}

/// Mock implementation for testing
pub struct MockProtocolDiscovery {
    protocols: Vec<ProtocolInfo>,
}

impl Default for MockProtocolDiscovery {
    fn default() -> Self {
        Self {
            protocols: vec![
                ProtocolInfo {
                    id: "uniswap-v3".to_string(),
                    name: "Uniswap V3".to_string(),
                    version: "3.0".to_string(),
                    chain_id: 1,
                    supported_operations: vec![IntentCategory::Swap, IntentCategory::ProvideLiquidity],
                },
                ProtocolInfo {
                    id: "aave-v3".to_string(),
                    name: "Aave V3".to_string(),
                    version: "3.0".to_string(),
                    chain_id: 1,
                    supported_operations: vec![IntentCategory::Lend, IntentCategory::Borrow],
                },
            ],
        }
    }
}

impl MockProtocolDiscovery {
    pub fn new() -> Self {
        Self::default()
    }
}

#[async_trait]
impl ProtocolDiscovery for MockProtocolDiscovery {
    async fn list_available_protocols(&self) -> Result<Vec<ProtocolInfo>> {
        Ok(self.protocols.clone())
    }
    
    async fn find_capable_protocols(&self, intent_type: &IntentCategory) -> Result<Vec<ProtocolCapability>> {
        let mut capabilities = Vec::new();
        
        for protocol in &self.protocols {
            if protocol.supported_operations.contains(intent_type) {
                capabilities.push(ProtocolCapability {
                    name: protocol.name.clone(),
                    address: Some("0x1234567890123456789012345678901234567890".to_string()),
                    suggested_function: match intent_type {
                        IntentCategory::Swap => "swap".to_string(),
                        IntentCategory::Lend => "supply".to_string(),
                        IntentCategory::Borrow => "borrow".to_string(),
                        _ => "execute".to_string(),
                    },
                    gas_estimate: Some(150000),
                    required_parameters: vec![],
                    optional_parameters: vec![],
                });
            }
        }
        
        Ok(capabilities)
    }
    
    async fn get_protocol_details(&self, _protocol_id: &str) -> Result<Option<ProtocolDetails>> {
        Ok(None) // Mock implementation
    }
    
    fn supports_parameters(&self, _protocol: &ProtocolInfo, _params: &serde_json::Map<String, serde_json::Value>) -> bool {
        true // Mock implementation
    }
    
    async fn discover_from_source(&self, _source: DiscoverySource) -> Result<Vec<ProtocolInfo>> {
        Ok(vec![]) // Mock implementation
    }
}