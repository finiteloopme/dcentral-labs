use super::IntentCategory;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Protocol {
    pub name: String,
    pub address: String,
    pub chain_id: u32,
    pub categories: Vec<IntentCategory>,
    pub functions: Vec<ProtocolFunction>,
    pub abi_hash: Option<String>,
    pub verified: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolFunction {
    pub name: String,
    pub signature: String,
    pub category: IntentCategory,
    pub gas_estimate: Option<u64>,
    pub description: String,
}

#[derive(Clone)]
pub struct ProtocolRegistry {
    protocols: HashMap<String, Protocol>,
    by_category: HashMap<IntentCategory, Vec<String>>,
    by_address: HashMap<String, String>,
}

impl ProtocolRegistry {
    pub fn new() -> Self {
        let mut registry = Self {
            protocols: HashMap::new(),
            by_category: HashMap::new(),
            by_address: HashMap::new(),
        };
        registry.load_default_protocols();
        registry
    }
    
    pub fn register_protocol(&mut self, protocol: Protocol) -> Result<()> {
        let name = protocol.name.clone();
        let address = protocol.address.clone().to_lowercase();
        
        // Index by category
        for category in &protocol.categories {
            self.by_category
                .entry(category.clone())
                .or_insert_with(Vec::new)
                .push(name.clone());
        }
        
        // Index by address
        self.by_address.insert(address, name.clone());
        
        // Store protocol
        self.protocols.insert(name, protocol);
        
        Ok(())
    }
    
    pub fn get_protocol(&self, name: &str) -> Option<&Protocol> {
        self.protocols.get(name)
    }
    
    pub fn get_protocol_by_address(&self, address: &str) -> Option<&Protocol> {
        let addr = address.to_lowercase();
        if let Some(name) = self.by_address.get(&addr) {
            return self.protocols.get(name);
        }
        None
    }
    
    pub fn find_protocols_for_category(&self, category: &IntentCategory) -> Vec<&Protocol> {
        if let Some(names) = self.by_category.get(category) {
            names
                .iter()
                .filter_map(|name| self.protocols.get(name))
                .collect()
        } else {
            Vec::new()
        }
    }
    
    pub fn search_protocols(&self, query: &str) -> Vec<&Protocol> {
        let query_lower = query.to_lowercase();
        self.protocols
            .values()
            .filter(|p| {
                p.name.to_lowercase().contains(&query_lower) ||
                p.functions.iter().any(|f| 
                    f.name.to_lowercase().contains(&query_lower) ||
                    f.description.to_lowercase().contains(&query_lower)
                )
            })
            .collect()
    }
    
    fn load_default_protocols(&mut self) {
        // Uniswap V3
        self.register_protocol(Protocol {
            name: "Uniswap V3".to_string(),
            address: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45".to_string(),
            chain_id: 1,
            categories: vec![IntentCategory::Swap, IntentCategory::ProvideLiquidity],
            functions: vec![
                ProtocolFunction {
                    name: "exactInputSingle".to_string(),
                    signature: "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))".to_string(),
                    category: IntentCategory::Swap,
                    gas_estimate: Some(150000),
                    description: "Swap exact amount of input token for output token".to_string(),
                },
                ProtocolFunction {
                    name: "exactOutputSingle".to_string(),
                    signature: "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))".to_string(),
                    category: IntentCategory::Swap,
                    gas_estimate: Some(160000),
                    description: "Swap input token for exact amount of output token".to_string(),
                },
                ProtocolFunction {
                    name: "mint".to_string(),
                    signature: "mint((address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256))".to_string(),
                    category: IntentCategory::ProvideLiquidity,
                    gas_estimate: Some(300000),
                    description: "Provide liquidity to a pool".to_string(),
                },
            ],
            abi_hash: Some("0x1234567890abcdef".to_string()),
            verified: true,
        }).unwrap();
        
        // Aave V3
        self.register_protocol(Protocol {
            name: "Aave V3".to_string(),
            address: "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2".to_string(),
            chain_id: 1,
            categories: vec![IntentCategory::Lend, IntentCategory::Borrow],
            functions: vec![
                ProtocolFunction {
                    name: "supply".to_string(),
                    signature: "supply(address,uint256,address,uint16)".to_string(),
                    category: IntentCategory::Lend,
                    gas_estimate: Some(200000),
                    description: "Supply assets to the lending pool".to_string(),
                },
                ProtocolFunction {
                    name: "borrow".to_string(),
                    signature: "borrow(address,uint256,uint256,uint16,address)".to_string(),
                    category: IntentCategory::Borrow,
                    gas_estimate: Some(250000),
                    description: "Borrow assets from the lending pool".to_string(),
                },
                ProtocolFunction {
                    name: "withdraw".to_string(),
                    signature: "withdraw(address,uint256,address)".to_string(),
                    category: IntentCategory::Lend,
                    gas_estimate: Some(180000),
                    description: "Withdraw supplied assets".to_string(),
                },
            ],
            abi_hash: Some("0xabcdef1234567890".to_string()),
            verified: true,
        }).unwrap();
        
        // Lido
        self.register_protocol(Protocol {
            name: "Lido".to_string(),
            address: "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84".to_string(),
            chain_id: 1,
            categories: vec![IntentCategory::Stake],
            functions: vec![
                ProtocolFunction {
                    name: "submit".to_string(),
                    signature: "submit(address)".to_string(),
                    category: IntentCategory::Stake,
                    gas_estimate: Some(100000),
                    description: "Stake ETH and receive stETH".to_string(),
                },
            ],
            abi_hash: Some("0xfedcba0987654321".to_string()),
            verified: true,
        }).unwrap();
        
        // Compound V3
        self.register_protocol(Protocol {
            name: "Compound V3".to_string(),
            address: "0xc3d688B66703497DAA19211EEdff47f25384cdc3".to_string(),
            chain_id: 1,
            categories: vec![IntentCategory::Lend, IntentCategory::Borrow],
            functions: vec![
                ProtocolFunction {
                    name: "supply".to_string(),
                    signature: "supply(address,uint256)".to_string(),
                    category: IntentCategory::Lend,
                    gas_estimate: Some(180000),
                    description: "Supply collateral to Compound".to_string(),
                },
                ProtocolFunction {
                    name: "withdraw".to_string(),
                    signature: "withdraw(address,uint256)".to_string(),
                    category: IntentCategory::Lend,
                    gas_estimate: Some(150000),
                    description: "Withdraw collateral from Compound".to_string(),
                },
            ],
            abi_hash: Some("0x1111222233334444".to_string()),
            verified: true,
        }).unwrap();
    }
}

impl Default for ProtocolRegistry {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_register_and_get_protocol() {
        let mut registry = ProtocolRegistry::new();
        
        let protocol = Protocol {
            name: "Test Protocol".to_string(),
            address: "0x1234567890123456789012345678901234567890".to_string(),
            chain_id: 1,
            categories: vec![IntentCategory::Swap],
            functions: vec![],
            abi_hash: None,
            verified: false,
        };
        
        registry.register_protocol(protocol.clone()).unwrap();
        
        let retrieved = registry.get_protocol("Test Protocol");
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().name, "Test Protocol");
    }

    #[test]
    fn test_find_protocols_for_category() {
        let registry = ProtocolRegistry::new();
        
        let swap_protocols = registry.find_protocols_for_category(&IntentCategory::Swap);
        assert!(!swap_protocols.is_empty());
        assert!(swap_protocols.iter().any(|p| p.name == "Uniswap V3"));
        
        let lend_protocols = registry.find_protocols_for_category(&IntentCategory::Lend);
        assert!(!lend_protocols.is_empty());
        assert!(lend_protocols.iter().any(|p| p.name == "Aave V3"));
    }

    #[test]
    fn test_get_protocol_by_address() {
        let registry = ProtocolRegistry::new();
        
        let protocol = registry.get_protocol_by_address("0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2");
        assert!(protocol.is_some());
        assert_eq!(protocol.unwrap().name, "Aave V3");
        
        // Test case insensitive
        let protocol = registry.get_protocol_by_address("0x87870bca3f3fd6335c3f4ce8392d69350b4fa4e2");
        assert!(protocol.is_some());
    }

    #[test]
    fn test_search_protocols() {
        let registry = ProtocolRegistry::new();
        
        let results = registry.search_protocols("swap");
        assert!(!results.is_empty());
        
        let results = registry.search_protocols("supply");
        assert!(results.iter().any(|p| p.name == "Aave V3" || p.name == "Compound V3"));
    }
}