use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::error::Error;

/// Ethereum transaction structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub from: Option<String>,
    pub to: String,
    pub value: String,
    pub data: String,
    pub gas: Option<String>,
    pub gas_price: Option<String>,
    pub nonce: Option<u64>,
    pub chain_id: Option<u64>,
}

/// Transaction builder for constructing transactions
pub struct TransactionBuilder {
    transaction: Transaction,
}

impl TransactionBuilder {
    /// Create a new transaction builder
    pub fn new() -> Self {
        Self {
            transaction: Transaction {
                from: None,
                to: String::new(),
                value: "0x0".to_string(),
                data: "0x".to_string(),
                gas: None,
                gas_price: None,
                nonce: None,
                chain_id: None,
            },
        }
    }
    
    /// Set the from address
    pub fn from(mut self, address: &str) -> Self {
        self.transaction.from = Some(address.to_string());
        self
    }
    
    /// Set the to address
    pub fn to(mut self, address: &str) -> Self {
        self.transaction.to = address.to_string();
        self
    }
    
    /// Set the value (in wei)
    pub fn value(mut self, value: &str) -> Self {
        self.transaction.value = if value.starts_with("0x") {
            value.to_string()
        } else {
            let val = value.parse::<u128>().unwrap_or(0);
            if val == 0 {
                "0x0".to_string()
            } else {
                format!("0x{:016x}", val)
            }
        };
        self
    }
    
    /// Set the data field
    pub fn data(mut self, data: &str) -> Self {
        self.transaction.data = if !data.starts_with("0x") {
            format!("0x{}", data)
        } else {
            data.to_string()
        };
        self
    }
    
    /// Set the gas limit
    pub fn gas(mut self, gas: u64) -> Self {
        self.transaction.gas = Some(format!("0x{:x}", gas));
        self
    }
    
    /// Set the gas price (in wei)
    pub fn gas_price(mut self, gas_price: u64) -> Self {
        self.transaction.gas_price = Some(format!("0x{:x}", gas_price));
        self
    }
    
    /// Set the nonce
    pub fn nonce(mut self, nonce: u64) -> Self {
        self.transaction.nonce = Some(nonce);
        self
    }
    
    /// Set the chain ID
    pub fn chain_id(mut self, chain_id: u64) -> Self {
        self.transaction.chain_id = Some(chain_id);
        self
    }
    
    /// Build the transaction
    pub fn build(self) -> Transaction {
        self.transaction
    }
    
    /// Build as JSON value
    pub fn build_json(self) -> Value {
        json!(self.transaction)
    }
}

impl Default for TransactionBuilder {
    fn default() -> Self {
        Self::new()
    }
}

/// Build a token transfer transaction
pub fn build_token_transfer(
    token_address: &str,
    to: &str,
    amount: &str,
    from: Option<&str>,
) -> Result<Transaction, Box<dyn Error>> {
    // Encode the transfer function call
    let data = crate::abi::encoder::AbiEncoder::encode_transfer(to, amount)?;
    
    let mut builder = TransactionBuilder::new()
        .to(token_address)
        .data(&data)
        .value("0x0") // Token transfers don't send ETH
        .gas(65000); // Standard gas for ERC20 transfer
    
    if let Some(from_addr) = from {
        builder = builder.from(from_addr);
    }
    
    Ok(builder.build())
}

/// Build a token approval transaction
pub fn build_token_approval(
    token_address: &str,
    spender: &str,
    amount: &str,
    from: Option<&str>,
) -> Result<Transaction, Box<dyn Error>> {
    // Encode the approve function call
    let data = crate::abi::encoder::AbiEncoder::encode_approve(spender, amount)?;
    
    let mut builder = TransactionBuilder::new()
        .to(token_address)
        .data(&data)
        .value("0x0")
        .gas(50000); // Standard gas for approval
    
    if let Some(from_addr) = from {
        builder = builder.from(from_addr);
    }
    
    Ok(builder.build())
}

/// Build a Uniswap V2 swap transaction
pub fn build_uniswap_swap(
    router_address: &str,
    amount_in: &str,
    amount_out_min: &str,
    path: Vec<String>,
    to: &str,
    deadline: &str,
    from: Option<&str>,
) -> Result<Transaction, Box<dyn Error>> {
    // Encode the swap function call
    let data = crate::abi::encoder::AbiEncoder::encode_swap_exact_tokens(
        amount_in,
        amount_out_min,
        path,
        to,
        deadline,
    )?;
    
    let mut builder = TransactionBuilder::new()
        .to(router_address)
        .data(&data)
        .value("0x0")
        .gas(250000); // Higher gas for swaps
    
    if let Some(from_addr) = from {
        builder = builder.from(from_addr);
    }
    
    Ok(builder.build())
}

/// Build an Aave supply transaction
pub fn build_aave_supply(
    pool_address: &str,
    asset: &str,
    amount: &str,
    on_behalf_of: &str,
    referral_code: u16,
    from: Option<&str>,
) -> Result<Transaction, Box<dyn Error>> {
    // Encode the supply function call
    let data = crate::abi::encoder::AbiEncoder::encode_supply(
        asset,
        amount,
        on_behalf_of,
        referral_code,
    )?;
    
    let mut builder = TransactionBuilder::new()
        .to(pool_address)
        .data(&data)
        .value("0x0")
        .gas(200000); // Gas for supply operation
    
    if let Some(from_addr) = from {
        builder = builder.from(from_addr);
    }
    
    Ok(builder.build())
}

/// Build ETH transfer transaction
pub fn build_eth_transfer(
    to: &str,
    amount: &str,
    from: Option<&str>,
) -> Result<Transaction, Box<dyn Error>> {
    let mut builder = TransactionBuilder::new()
        .to(to)
        .value(amount)
        .data("0x")
        .gas(21000); // Standard ETH transfer gas
    
    if let Some(from_addr) = from {
        builder = builder.from(from_addr);
    }
    
    Ok(builder.build())
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_transaction_builder() {
        let tx = TransactionBuilder::new()
            .from("0x1234567890123456789012345678901234567890")
            .to("0xabcdefabcdefabcdefabcdefabcdefabcdefabcd")
            .value("1000000000000000000")
            .data("0xa9059cbb")
            .gas(65000)
            .gas_price(30000000000)
            .chain_id(1)
            .build();
        
        assert_eq!(tx.from, Some("0x1234567890123456789012345678901234567890".to_string()));
        assert_eq!(tx.to, "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd");
        assert_eq!(tx.gas, Some("0xfde8".to_string()));
    }
    
    #[test]
    fn test_build_token_transfer() {
        let tx = build_token_transfer(
            "0x6B175474E89094C44Da98b954EedeAC495271d0F", // DAI
            "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
            "1000000000000000000",
            Some("0x1234567890123456789012345678901234567890"),
        ).unwrap();
        
        assert_eq!(tx.to, "0x6B175474E89094C44Da98b954EedeAC495271d0F");
        assert!(tx.data.starts_with("0xa9059cbb"));
        assert_eq!(tx.value, "0x0");
    }
}