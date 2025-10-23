use std::error::Error;
use std::fmt;
use serde_json::{json, Value};
use std::collections::HashMap;

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
    /// Get known function selectors
    fn get_known_selectors() -> HashMap<String, (&'static str, Vec<&'static str>)> {
        let mut selectors = HashMap::new();
        
        // ERC20 functions
        selectors.insert("a9059cbb".to_string(), ("transfer", vec!["to", "amount"]));
        selectors.insert("095ea7b3".to_string(), ("approve", vec!["spender", "amount"]));
        selectors.insert("23b872dd".to_string(), ("transferFrom", vec!["from", "to", "amount"]));
        selectors.insert("70a08231".to_string(), ("balanceOf", vec!["account"]));
        selectors.insert("dd62ed3e".to_string(), ("allowance", vec!["owner", "spender"]));
        
        // Uniswap V2 functions
        selectors.insert("38ed1739".to_string(), ("swapExactTokensForTokens", vec!["amountIn", "amountOutMin", "path", "to", "deadline"]));
        selectors.insert("7ff36ab5".to_string(), ("swapExactETHForTokens", vec!["amountOutMin", "path", "to", "deadline"]));
        selectors.insert("e8e33700".to_string(), ("addLiquidity", vec!["tokenA", "tokenB", "amountADesired", "amountBDesired", "amountAMin", "amountBMin", "to", "deadline"]));
        
        // Aave V3 functions  
        selectors.insert("617ba037".to_string(), ("supply", vec!["asset", "amount", "onBehalfOf", "referralCode"]));
        selectors.insert("69328dec".to_string(), ("withdraw", vec!["asset", "amount", "to"]));
        selectors.insert("a415bcad".to_string(), ("borrow", vec!["asset", "amount", "interestRateMode", "referralCode", "onBehalfOf"]));
        
        // Compound functions
        selectors.insert("a0712d68".to_string(), ("mint", vec!["mintAmount"]));
        selectors.insert("db006a75".to_string(), ("redeem", vec!["redeemTokens"]));
        
        selectors
    }
    
    /// Decode an address from hex data
    fn decode_address(data: &str) -> String {
        let address = if data.len() >= 64 {
            &data[24..64]  // Remove leading zeros
        } else {
            data
        };
        format!("0x{}", address)
    }
    
    /// Decode a uint256 from hex data
    fn decode_uint256(data: &str) -> String {
        // Convert hex to decimal for readability
        if let Ok(value) = u128::from_str_radix(data, 16) {
            // Check if it's likely a token amount (has many zeros)
            if value > 1_000_000_000_000_000 {
                // Format as token amount with 18 decimals
                let whole = value / 1_000_000_000_000_000_000;
                let decimal = (value % 1_000_000_000_000_000_000) / 1_000_000_000_000_000;
                if decimal > 0 {
                    format!("{}.{:03}", whole, decimal)
                } else {
                    format!("{}", whole)
                }
            } else {
                value.to_string()
            }
        } else {
            format!("0x{}", data)
        }
    }
    
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
        
        // Decode parameters
        let to = Self::decode_address(&data[8..72]);
        let amount = Self::decode_uint256(&data[72..136]);
        
        Ok(json!({
            "function": "transfer",
            "to": to,
            "amount": amount,
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
        
        // Decode parameters
        let spender = Self::decode_address(&data[8..72]);
        let amount = Self::decode_uint256(&data[72..136]);
        
        Ok(json!({
            "function": "approve",
            "spender": spender,
            "amount": amount,
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
        let params_data = &data[8..];
        
        let selectors = Self::get_known_selectors();
        
        // Try to decode known function selectors
        if let Some((function_name, param_names)) = selectors.get(selector) {
            let mut decoded_params = json!({});
            let mut offset = 0;
            
            for param_name in param_names {
                if offset >= params_data.len() {
                    break;
                }
                
                // Simple decoding - assume all params are 32 bytes for now
                let param_data = &params_data[offset..std::cmp::min(offset + 64, params_data.len())];
                
                // Try to determine if it's an address or uint
                let value = if param_name.contains("address") || param_name == &"to" || param_name == &"from" || 
                              param_name == &"spender" || param_name == &"owner" || param_name == &"account" ||
                              param_name.contains("token") || param_name == &"asset" {
                    Self::decode_address(param_data)
                } else if param_name.contains("amount") || param_name.contains("value") || param_name.contains("deadline") {
                    Self::decode_uint256(param_data)
                } else if param_name == &"path" {
                    // Skip dynamic arrays for now
                    offset = params_data.len();
                    "[array]".to_string()
                } else {
                    format!("0x{}", param_data)
                };
                
                decoded_params[param_name] = json!(value);
                offset += 64;
            }
            
            Ok(DecodedCall {
                function: function_name.to_string(),
                params: json!({
                    "function": function_name,
                    "selector": format!("0x{}", selector),
                    "parameters": decoded_params
                }),
            })
        } else {
            // Special case for already decoded functions
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