use serde_json::Value;
use std::error::Error;
use std::fmt;

#[derive(Debug)]
pub struct ParseError(String);

impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl Error for ParseError {}

/// ABI Parser for handling various ABI formats
pub struct AbiParser;

impl AbiParser {
    /// Parse ABI from JSON string
    pub fn parse_json(json_str: &str) -> Result<Value, Box<dyn Error>> {
        let abi = serde_json::from_str::<Value>(json_str)?;
        
        // Validate it's an array
        if !abi.is_array() {
            return Err(Box::new(ParseError("ABI must be an array".to_string())));
        }
        
        Ok(abi)
    }
    
    /// Get function selector (4-byte signature)
    pub fn get_selector(signature: &str) -> String {
        use sha3::{Digest, Keccak256};
        
        let mut hasher = Keccak256::new();
        hasher.update(signature.as_bytes());
        let result = hasher.finalize();
        
        format!("0x{}", hex::encode(&result[..4]))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_simple_abi() {
        let abi_json = r#"[{"name": "transfer", "type": "function"}]"#;
        let abi = AbiParser::parse_json(abi_json).unwrap();
        assert!(abi.is_array());
    }
    
    #[test]
    fn test_get_selector() {
        let selector = AbiParser::get_selector("transfer(address,uint256)");
        assert_eq!(selector, "0xa9059cbb");
    }
}