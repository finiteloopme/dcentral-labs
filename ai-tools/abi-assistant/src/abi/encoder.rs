use std::error::Error;
use std::fmt;

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

/// ABI Encoder for encoding function calls
pub struct AbiEncoder;

impl AbiEncoder {
    /// Encode a simple transfer function call
    pub fn encode_transfer(to: &str, amount: &str) -> Result<String, Box<dyn Error>> {
        // transfer(address,uint256) selector
        let selector = "a9059cbb";
        
        // Simple encoding - just concatenate for now
        // In production, would use proper ABI encoding
        let address = if to.starts_with("0x") {
            format!("{:0>64}", &to[2..])
        } else {
            format!("{:0>64}", to)
        };
        
        // Convert amount to hex (simplified)
        let amount_hex = format!("{:064x}", amount.parse::<u128>().unwrap_or(0));
        
        Ok(format!("0x{}{}{}", selector, address, amount_hex))
    }
    
    /// Encode approve function call
    pub fn encode_approve(spender: &str, amount: &str) -> Result<String, Box<dyn Error>> {
        // approve(address,uint256) selector
        let selector = "095ea7b3";
        
        let address = if spender.starts_with("0x") {
            format!("{:0>64}", &spender[2..])
        } else {
            format!("{:0>64}", spender)
        };
        
        let amount_hex = format!("{:064x}", amount.parse::<u128>().unwrap_or(0));
        
        Ok(format!("0x{}{}{}", selector, address, amount_hex))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_encode_transfer() {
        let encoded = AbiEncoder::encode_transfer(
            "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
            "1000000000000000000"
        ).unwrap();
        
        assert!(encoded.starts_with("0xa9059cbb"));
        assert_eq!(encoded.len(), 138); // 0x + 8 (selector) + 64 (address) + 64 (amount)
    }
}