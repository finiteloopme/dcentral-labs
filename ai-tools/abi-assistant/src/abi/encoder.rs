use std::error::Error;
use std::fmt;
use serde_json::Value;
use sha3::{Digest, Keccak256};

/// ABI encoding error
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

impl AbiError {
    pub fn new(msg: &str) -> Self {
        AbiError {
            message: msg.to_string(),
        }
    }
}

/// ABI Encoder for encoding function calls
pub struct AbiEncoder;

impl AbiEncoder {
    /// Calculate function selector from signature
    pub fn calculate_selector(signature: &str) -> String {
        let mut hasher = Keccak256::new();
        hasher.update(signature.as_bytes());
        let result = hasher.finalize();
        hex::encode(&result[..4])
    }
    
    /// Encode an address parameter
    pub fn encode_address(address: &str) -> Result<String, Box<dyn Error>> {
        let address = if address.starts_with("0x") || address.starts_with("0X") {
            &address[2..]
        } else {
            address
        };
        
        if address.len() != 40 {
            return Err(Box::new(AbiError::new("Invalid address length")));
        }
        
        // Convert to lowercase for consistency
        Ok(format!("{:0>64}", address.to_lowercase()))
    }
    
    /// Encode a uint256 parameter
    pub fn encode_uint256(value: &str) -> Result<String, Box<dyn Error>> {
        // Handle both decimal and hex input
        let num = if value.starts_with("0x") {
            u128::from_str_radix(&value[2..], 16)?
        } else {
            value.parse::<u128>()?
        };
        
        Ok(format!("{:064x}", num))
    }
    
    /// Encode a bytes32 parameter
    pub fn encode_bytes32(value: &str) -> Result<String, Box<dyn Error>> {
        let value = if value.starts_with("0x") {
            &value[2..]
        } else {
            value
        };
        
        if value.len() > 64 {
            return Err(Box::new(AbiError::new("Value too long for bytes32")));
        }
        
        Ok(format!("{:0<64}", value))
    }
    
    /// Encode a boolean parameter
    pub fn encode_bool(value: bool) -> String {
        if value {
            format!("{:064x}", 1)
        } else {
            format!("{:064x}", 0)
        }
    }
    
    /// Encode a dynamic string parameter
    pub fn encode_string(value: &str) -> Result<String, Box<dyn Error>> {
        let bytes = value.as_bytes();
        let len = bytes.len();
        
        // Offset (always 0x20 for single string param)
        let mut encoded = format!("{:064x}", 0x20);
        
        // Length
        encoded.push_str(&format!("{:064x}", len));
        
        // Data (padded to 32 bytes)
        let mut data = hex::encode(bytes);
        let padding = ((len + 31) / 32) * 32 * 2 - data.len();
        data.push_str(&"0".repeat(padding));
        encoded.push_str(&data);
        
        Ok(encoded)
    }
    
    /// Generic function encoding with JSON parameters
    pub fn encode_function(signature: &str, params: &Value) -> Result<String, Box<dyn Error>> {
        let selector = Self::calculate_selector(signature);
        let mut encoded = format!("0x{}", selector);
        
        if let Value::Array(arr) = params {
            for param in arr {
                let param_str = match param {
                    Value::String(s) => {
                        // Try to determine type by content
                        if s.starts_with("0x") && s.len() == 42 {
                            // Likely an address
                            Self::encode_address(s)?
                        } else if s.parse::<u128>().is_ok() || (s.starts_with("0x") && s.len() <= 66) {
                            // Likely a number
                            Self::encode_uint256(s)?
                        } else {
                            // Treat as string
                            Self::encode_string(s)?
                        }
                    },
                    Value::Number(n) => {
                        Self::encode_uint256(&n.to_string())?
                    },
                    Value::Bool(b) => {
                        Self::encode_bool(*b)
                    },
                    _ => return Err(Box::new(AbiError::new("Unsupported parameter type"))),
                };
                encoded.push_str(&param_str);
            }
        }
        
        Ok(encoded)
    }
    
    /// Encode a simple transfer function call
    pub fn encode_transfer(to: &str, amount: &str) -> Result<String, Box<dyn Error>> {
        let selector = Self::calculate_selector("transfer(address,uint256)");
        let address = Self::encode_address(to)?;
        let amount = Self::encode_uint256(amount)?;
        
        Ok(format!("0x{}{}{}", selector, address, amount))
    }
    
    /// Encode approve function call
    pub fn encode_approve(spender: &str, amount: &str) -> Result<String, Box<dyn Error>> {
        let selector = Self::calculate_selector("approve(address,uint256)");
        let address = Self::encode_address(spender)?;
        let amount = Self::encode_uint256(amount)?;
        
        Ok(format!("0x{}{}{}", selector, address, amount))
    }
    
    /// Encode transferFrom function call
    pub fn encode_transfer_from(from: &str, to: &str, amount: &str) -> Result<String, Box<dyn Error>> {
        let selector = Self::calculate_selector("transferFrom(address,address,uint256)");
        let from_addr = Self::encode_address(from)?;
        let to_addr = Self::encode_address(to)?;
        let amount = Self::encode_uint256(amount)?;
        
        Ok(format!("0x{}{}{}{}", selector, from_addr, to_addr, amount))
    }
    
    /// Encode Uniswap V2 swap function
    pub fn encode_swap_exact_tokens(
        amount_in: &str,
        amount_out_min: &str,
        path: Vec<String>,
        to: &str,
        deadline: &str,
    ) -> Result<String, Box<dyn Error>> {
        let selector = Self::calculate_selector("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)");
        
        let mut encoded = format!("0x{}", selector);
        encoded.push_str(&Self::encode_uint256(amount_in)?);
        encoded.push_str(&Self::encode_uint256(amount_out_min)?);
        
        // Dynamic array offset
        encoded.push_str(&format!("{:064x}", 0xa0)); // 5 * 32 bytes
        
        encoded.push_str(&Self::encode_address(to)?);
        encoded.push_str(&Self::encode_uint256(deadline)?);
        
        // Dynamic array data
        encoded.push_str(&format!("{:064x}", path.len()));
        for address in path {
            encoded.push_str(&Self::encode_address(&address)?);
        }
        
        Ok(encoded)
    }
    
    /// Encode Aave supply/deposit function
    pub fn encode_supply(asset: &str, amount: &str, on_behalf_of: &str, referral_code: u16) -> Result<String, Box<dyn Error>> {
        let selector = Self::calculate_selector("supply(address,uint256,address,uint16)");
        
        let mut encoded = format!("0x{}", selector);
        encoded.push_str(&Self::encode_address(asset)?);
        encoded.push_str(&Self::encode_uint256(amount)?);
        encoded.push_str(&Self::encode_address(on_behalf_of)?);
        encoded.push_str(&format!("{:064x}", referral_code));
        
        Ok(encoded)
    }
    
    /// Encode Compound supply function
    pub fn encode_mint(mint_amount: &str) -> Result<String, Box<dyn Error>> {
        let selector = Self::calculate_selector("mint(uint256)");
        let amount = Self::encode_uint256(mint_amount)?;
        
        Ok(format!("0x{}{}", selector, amount))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    
    #[test]
    fn test_calculate_selector() {
        let selector = AbiEncoder::calculate_selector("transfer(address,uint256)");
        assert_eq!(selector, "a9059cbb");
        
        let selector = AbiEncoder::calculate_selector("approve(address,uint256)");
        assert_eq!(selector, "095ea7b3");
    }
    
    #[test]
    fn test_encode_address() {
        let encoded = AbiEncoder::encode_address("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7").unwrap();
        assert_eq!(encoded, "000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb7");
    }
    
    #[test]
    fn test_encode_uint256() {
        let encoded = AbiEncoder::encode_uint256("1000000000000000000").unwrap();
        assert_eq!(encoded.len(), 64);
        
        let encoded_hex = AbiEncoder::encode_uint256("0x0de0b6b3a7640000").unwrap();
        assert_eq!(encoded_hex.len(), 64);
    }
    
    #[test]
    fn test_encode_transfer() {
        let encoded = AbiEncoder::encode_transfer(
            "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
            "1000000000000000000"
        ).unwrap();
        
        assert!(encoded.starts_with("0xa9059cbb"));
        assert_eq!(encoded.len(), 138); // 0x + 8 (selector) + 64 (address) + 64 (amount)
    }
    
    #[test]
    fn test_encode_function_generic() {
        let params = json!(["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", "1000"]);
        let encoded = AbiEncoder::encode_function("transfer(address,uint256)", &params).unwrap();
        
        assert!(encoded.starts_with("0xa9059cbb"));
        assert_eq!(encoded.len(), 138);
    }
}