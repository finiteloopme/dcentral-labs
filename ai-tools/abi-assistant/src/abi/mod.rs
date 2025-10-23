/// ABI parsing and encoding/decoding functionality
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::error::Error;

pub mod parser;
pub mod encoder;
pub mod decoder;

/// Represents a parsed ABI with metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParsedAbi {
    pub raw_abi: String,
    pub functions: HashMap<String, FunctionInfo>,
    pub events: HashMap<String, String>,
    pub contract_name: Option<String>,
    pub detected_patterns: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionInfo {
    pub name: String,
    pub signature: String,
    pub inputs: Vec<String>,
    pub outputs: Vec<String>,
}

impl ParsedAbi {
    /// Create a new ParsedAbi from JSON string
    pub fn from_json(json_str: &str) -> Result<Self, Box<dyn Error>> {
        // For now, just validate it's valid JSON
        let _: serde_json::Value = serde_json::from_str(json_str)?;
        
        let mut detected_patterns = Vec::new();
        
        // Simple pattern detection based on common function names
        if json_str.contains("swap") || json_str.contains("exchange") {
            detected_patterns.push("swap".to_string());
        }
        if json_str.contains("supply") || json_str.contains("deposit") {
            detected_patterns.push("lending".to_string());
        }
        if json_str.contains("borrow") {
            detected_patterns.push("borrowing".to_string());
        }
        if json_str.contains("stake") {
            detected_patterns.push("staking".to_string());
        }
        
        Ok(Self {
            raw_abi: json_str.to_string(),
            functions: HashMap::new(),
            events: HashMap::new(),
            contract_name: None,
            detected_patterns,
        })
    }
    
    /// Get a function by name
    pub fn get_function(&self, name: &str) -> Option<&FunctionInfo> {
        self.functions.get(name)
    }
    
    /// Check if ABI contains a specific function
    pub fn has_function(&self, name: &str) -> bool {
        self.functions.contains_key(name)
    }
    
    /// Detect protocol type based on patterns
    pub fn detect_protocol_type(&self) -> String {
        if self.detected_patterns.contains(&"swap".to_string()) {
            return "amm".to_string();
        }
        if self.detected_patterns.contains(&"lending".to_string()) {
            return "lending".to_string();
        }
        if self.detected_patterns.contains(&"staking".to_string()) {
            return "staking".to_string();
        }
        "unknown".to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_simple_abi() {
        let abi_json = r#"[{"name": "transfer", "type": "function"}]"#;
        let parsed = ParsedAbi::from_json(abi_json).unwrap();
        assert_eq!(parsed.detect_protocol_type(), "unknown");
    }
}