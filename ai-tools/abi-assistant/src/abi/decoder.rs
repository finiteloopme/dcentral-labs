use std::error::Error;
use std::fmt;
use serde_json::{json, Value};

/// ABI decoding error
#[derive(Debug)]
pub struct AbiError {
    message: String,
}

impl fmt::Display for AbiError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl Error for AbiError {}

/// ABI Decoder for decoding transaction data
pub struct AbiDecoder;

impl AbiDecoder {
    /// Decode a transfer function call
    pub fn decode_transfer(data: &str) -> Result<Value, Box<dyn Error>> {
        // Remove 0x prefix
        let data = if data.starts_with("0x") {
            &data[2..]
        } else {
            data
        };
        
        // Check selector
        if !data.starts_with("a9059cbb") {
            return Err(Box::new(AbiError {
                message: "Not a transfer function".to_string(),
            }));
        }
        
        // Simple decoding
        let to = format!("0x{}", &data[32..72]);
        let amount_hex = &data[72..136];
        
        Ok(json!({
            "function": "transfer",
            "to": to,
            "amount": amount_hex,
        }))
    }
    
    /// Decode an approve function call
    pub fn decode_approve(data: &str) -> Result<Value, Box<dyn Error>> {
        // Remove 0x prefix
        let data = if data.starts_with("0x") {
            &data[2..]
        } else {
            data
        };
        
        // Check selector
        if !data.starts_with("095ea7b3") {
            return Err(Box::new(AbiError {
                message: "Not an approve function".to_string(),
            }));
        }
        
        // Simple decoding
        let spender = format!("0x{}", &data[32..72]);
        let amount_hex = &data[72..136];
        
        Ok(json!({
            "function": "approve",
            "spender": spender,
            "amount": amount_hex,
        }))
    }
    
    /// Generic function call decoder
    pub fn decode_function_call(data: &str) -> Result<DecodedCall, Box<dyn Error>> {
        // Remove 0x prefix
        let data = if data.starts_with("0x") {
            &data[2..]
        } else {
            data
        };
        
        if data.len() < 8 {
            return Err(Box::new(AbiError {
                message: "Invalid function call data".to_string(),
            }));
        }
        
        let selector = &data[0..8];
        
        // Try to decode known function selectors
        match selector {
            "a9059cbb" => {
                let decoded = Self::decode_transfer(&format!("0x{}", data))?;
                Ok(DecodedCall {
                    function: "transfer".to_string(),
                    params: decoded,
                })
            },
            "095ea7b3" => {
                let decoded = Self::decode_approve(&format!("0x{}", data))?;
                Ok(DecodedCall {
                    function: "approve".to_string(),
                    params: decoded,
                })
            },
            _ => {
                Ok(DecodedCall {
                    function: format!("unknown_0x{}", selector),
                    params: json!({
                        "selector": format!("0x{}", selector),
                        "data": format!("0x{}", data)
                    }),
                })
            }
        }
    }
}

/// Decoded function call
pub struct DecodedCall {
    pub function: String,
    pub params: Value,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_decode_transfer() {
        let data = "0xa9059cbb000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb70000000000000000000000000000000000000000000000000de0b6b3a7640000";
        let decoded = AbiDecoder::decode_transfer(data).unwrap();
        
        assert_eq!(decoded["function"], "transfer");
        assert_eq!(decoded["to"], "0x742d35cc6634c0532925a3b844bc9e7595f0beb7");
    }
}