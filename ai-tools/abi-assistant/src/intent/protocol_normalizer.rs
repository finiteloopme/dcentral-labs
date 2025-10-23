use std::collections::HashMap;

/// Normalizes protocol names using configuration mappings
/// This will evolve to support dynamic protocol discovery in Phase 4
pub struct ProtocolNormalizer {
    /// Maps variations to canonical names
    /// e.g., "uni" -> "Uniswap", "aave v3" -> "Aave V3"
    mappings: HashMap<String, String>,
}

impl ProtocolNormalizer {
    pub fn from_config(config: &HashMap<String, Vec<String>>) -> Self {
        let mut mappings = HashMap::new();
        
        // Build reverse mappings: variation -> canonical
        for (canonical, variations) in config {
            // The first item in the list is the canonical name
            if let Some(canonical_name) = variations.first() {
                // Map all variations to the canonical name
                for variation in variations {
                    mappings.insert(
                        variation.to_lowercase(),
                        canonical_name.clone()
                    );
                }
                // Also map the key itself
                mappings.insert(
                    canonical.to_lowercase(),
                    canonical_name.clone()
                );
            }
        }
        
        Self { mappings }
    }
    
    /// Normalize a protocol name to its canonical form
    pub fn normalize(&self, input: &str) -> String {
        let lower = input.to_lowercase();
        
        // Check for exact match
        if let Some(canonical) = self.mappings.get(&lower) {
            return canonical.clone();
        }
        
        // Check for partial matches (e.g., "uni v3" -> "Uniswap V3")
        for (variation, canonical) in &self.mappings {
            if lower.contains(variation) || variation.contains(&lower) {
                return canonical.clone();
            }
        }
        
        // No match found, return original
        input.to_string()
    }
    
    /// Check if a protocol name is recognized
    pub fn is_recognized(&self, input: &str) -> bool {
        let lower = input.to_lowercase();
        self.mappings.contains_key(&lower) || 
        self.mappings.values().any(|v| v.to_lowercase() == lower)
    }
}

/// Future: This trait will be implemented by dynamic discovery
pub trait ProtocolDiscoveryHint {
    /// Get hints for where to look for a protocol
    fn get_discovery_hints(&self, name: &str) -> Vec<DiscoveryHint>;
}

#[derive(Debug, Clone)]
pub enum DiscoveryHint {
    /// Check a specific chain
    CheckChain(u32),
    /// Look for contracts with this name pattern
    NamePattern(String),
    /// Check a specific address
    KnownAddress(String),
    /// Query a specific data source
    DataSource(String),
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_protocol_normalization() {
        let mut config = HashMap::new();
        config.insert(
            "uniswap".to_string(),
            vec![
                "Uniswap V3".to_string(),
                "UniswapV3".to_string(),
                "uni".to_string(),
                "uni v3".to_string(),
            ]
        );
        
        let normalizer = ProtocolNormalizer::from_config(&config);
        
        assert_eq!(normalizer.normalize("uni"), "Uniswap V3");
        assert_eq!(normalizer.normalize("UNI"), "Uniswap V3");
        assert_eq!(normalizer.normalize("uniswap"), "Uniswap V3");
        assert_eq!(normalizer.normalize("UniswapV3"), "Uniswap V3");
        assert_eq!(normalizer.normalize("unknown"), "unknown");
    }
    
    #[test]
    fn test_protocol_recognition() {
        let mut config = HashMap::new();
        config.insert(
            "aave".to_string(),
            vec!["Aave V3".to_string(), "aave".to_string()]
        );
        
        let normalizer = ProtocolNormalizer::from_config(&config);
        
        assert!(normalizer.is_recognized("aave"));
        assert!(normalizer.is_recognized("Aave V3"));
        assert!(normalizer.is_recognized("AAVE"));
        assert!(!normalizer.is_recognized("compound"));
    }
}