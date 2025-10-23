use super::builder::Transaction;
use serde_json::{json, Value};
use std::error::Error;

/// Format options for transaction export
#[derive(Debug, Clone)]
pub enum ExportFormat {
    /// Raw JSON format for web3 libraries
    RawJson,
    /// EIP-712 typed data for smart wallets
    Eip712,
    /// QR code data format
    QrCode,
    /// WalletConnect deep link
    WalletConnect,
    /// Ethers.js format
    EthersJs,
    /// Hex-encoded raw transaction
    RawHex,
}

/// Transaction formatter for various export formats
pub struct TransactionFormatter;

impl TransactionFormatter {
    /// Export transaction in specified format
    pub fn export(tx: &Transaction, format: ExportFormat) -> Result<Value, Box<dyn Error>> {
        match format {
            ExportFormat::RawJson => Self::to_raw_json(tx),
            ExportFormat::Eip712 => Self::to_eip712(tx),
            ExportFormat::QrCode => Self::to_qr_code(tx),
            ExportFormat::WalletConnect => Self::to_wallet_connect(tx),
            ExportFormat::EthersJs => Self::to_ethers_js(tx),
            ExportFormat::RawHex => Self::to_raw_hex(tx),
        }
    }
    
    /// Export as raw JSON for web3 libraries
    pub fn to_raw_json(tx: &Transaction) -> Result<Value, Box<dyn Error>> {
        let mut json_tx = json!({
            "to": tx.to,
            "data": tx.data,
            "value": tx.value,
        });
        
        if let Some(from) = &tx.from {
            json_tx["from"] = json!(from);
        }
        
        if let Some(gas) = &tx.gas {
            json_tx["gas"] = json!(gas);
        }
        
        if let Some(gas_price) = &tx.gas_price {
            json_tx["gasPrice"] = json!(gas_price);
        }
        
        if let Some(nonce) = tx.nonce {
            json_tx["nonce"] = json!(format!("0x{:x}", nonce));
        }
        
        if let Some(chain_id) = tx.chain_id {
            json_tx["chainId"] = json!(chain_id);
        }
        
        Ok(json_tx)
    }
    
    /// Export as EIP-712 typed data
    pub fn to_eip712(tx: &Transaction) -> Result<Value, Box<dyn Error>> {
        let chain_id = tx.chain_id.unwrap_or(1);
        
        let typed_data = json!({
            "types": {
                "EIP712Domain": [
                    {"name": "name", "type": "string"},
                    {"name": "version", "type": "string"},
                    {"name": "chainId", "type": "uint256"},
                ],
                "Transaction": [
                    {"name": "to", "type": "address"},
                    {"name": "value", "type": "uint256"},
                    {"name": "data", "type": "bytes"},
                    {"name": "nonce", "type": "uint256"},
                    {"name": "gasLimit", "type": "uint256"},
                    {"name": "gasPrice", "type": "uint256"},
                ]
            },
            "primaryType": "Transaction",
            "domain": {
                "name": "ABI Assistant",
                "version": "1",
                "chainId": chain_id,
            },
            "message": {
                "to": tx.to,
                "value": tx.value,
                "data": tx.data,
                "nonce": tx.nonce.unwrap_or(0),
                "gasLimit": tx.gas.clone().unwrap_or_else(|| "0x5208".to_string()),
                "gasPrice": tx.gas_price.clone().unwrap_or_else(|| "0x0".to_string()),
            }
        });
        
        Ok(typed_data)
    }
    
    /// Export as QR code data
    pub fn to_qr_code(tx: &Transaction) -> Result<Value, Box<dyn Error>> {
        // EIP-681 format for payment requests
        let mut uri = format!("ethereum:{}@{}", tx.to, tx.chain_id.unwrap_or(1));
        
        // Add value if not zero
        if tx.value != "0x0" && tx.value != "0" {
            uri.push_str(&format!("?value={}", tx.value));
        }
        
        // Add data if present
        if tx.data != "0x" && !tx.data.is_empty() {
            let separator = if uri.contains('?') { "&" } else { "?" };
            uri.push_str(&format!("{}data={}", separator, tx.data));
        }
        
        Ok(json!({
            "format": "EIP-681",
            "uri": uri,
            "qr_data": uri,
            "encoding": "alphanumeric"
        }))
    }
    
    /// Export as WalletConnect deep link
    pub fn to_wallet_connect(tx: &Transaction) -> Result<Value, Box<dyn Error>> {
        let method = "eth_sendTransaction";
        let params = vec![Self::to_raw_json(tx)?];
        
        Ok(json!({
            "method": method,
            "params": params,
            "deeplink": format!("wc:?uri=...&request={}", 
                serde_json::to_string(&json!({
                    "method": method,
                    "params": params
                }))?
            )
        }))
    }
    
    /// Export for ethers.js
    pub fn to_ethers_js(tx: &Transaction) -> Result<Value, Box<dyn Error>> {
        let mut ethers_tx = json!({
            "to": tx.to,
            "data": tx.data,
            "value": tx.value,
        });
        
        if let Some(from) = &tx.from {
            ethers_tx["from"] = json!(from);
        }
        
        if let Some(gas) = &tx.gas {
            // Convert hex to decimal for ethers.js
            let gas_decimal = u64::from_str_radix(&gas[2..], 16).unwrap_or(0);
            ethers_tx["gasLimit"] = json!(gas_decimal.to_string());
        }
        
        if let Some(gas_price) = &tx.gas_price {
            ethers_tx["gasPrice"] = json!(gas_price);
        }
        
        if let Some(nonce) = tx.nonce {
            ethers_tx["nonce"] = json!(nonce);
        }
        
        if let Some(chain_id) = tx.chain_id {
            ethers_tx["chainId"] = json!(chain_id);
        }
        
        Ok(ethers_tx)
    }
    
    /// Export as raw hex encoded transaction (unsigned)
    pub fn to_raw_hex(tx: &Transaction) -> Result<Value, Box<dyn Error>> {
        // This would normally use RLP encoding
        // For now, return a simplified hex representation
        let hex_data = format!(
            "{}{}{}",
            &tx.to[2..], // Remove 0x prefix
            &tx.value[2..],
            &tx.data[2..]
        );
        
        Ok(json!({
            "format": "raw_hex",
            "unsigned": true,
            "hex": format!("0x{}", hex_data),
            "note": "This is an unsigned transaction. Sign with your wallet before broadcasting."
        }))
    }
    
    /// Export transaction in all formats
    pub fn export_all_formats(tx: &Transaction) -> Result<Value, Box<dyn Error>> {
        Ok(json!({
            "raw_json": Self::to_raw_json(tx)?,
            "eip712": Self::to_eip712(tx)?,
            "qr_code": Self::to_qr_code(tx)?,
            "wallet_connect": Self::to_wallet_connect(tx)?,
            "ethers_js": Self::to_ethers_js(tx)?,
            "raw_hex": Self::to_raw_hex(tx)?,
        }))
    }
}

/// Helper function to format transaction for display
pub fn format_transaction_summary(tx: &Transaction) -> String {
    let mut summary = String::new();
    
    summary.push_str(&format!("To: {}\n", tx.to));
    
    if tx.value != "0x0" && tx.value != "0" {
        summary.push_str(&format!("Value: {} wei\n", tx.value));
    }
    
    if tx.data != "0x" && !tx.data.is_empty() {
        summary.push_str(&format!("Data: {} ({})\n", 
            &tx.data[..std::cmp::min(10, tx.data.len())],
            if tx.data.len() > 10 { "..." } else { "" }
        ));
    }
    
    if let Some(gas) = &tx.gas {
        summary.push_str(&format!("Gas Limit: {}\n", gas));
    }
    
    if let Some(gas_price) = &tx.gas_price {
        summary.push_str(&format!("Gas Price: {} wei\n", gas_price));
    }
    
    summary
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::transaction::builder::TransactionBuilder;
    
    #[test]
    fn test_to_raw_json() {
        let tx = TransactionBuilder::new()
            .to("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7")
            .value("1000000000000000000")
            .data("0xa9059cbb")
            .gas(65000)
            .build();
        
        let json = TransactionFormatter::to_raw_json(&tx).unwrap();
        
        assert_eq!(json["to"], "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7");
        assert_eq!(json["value"], "0x0de0b6b3a7640000");
        assert_eq!(json["data"], "0xa9059cbb");
    }
    
    #[test]
    fn test_to_eip712() {
        let tx = TransactionBuilder::new()
            .to("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7")
            .value("1000000000000000000")
            .chain_id(1)
            .build();
        
        let eip712 = TransactionFormatter::to_eip712(&tx).unwrap();
        
        assert_eq!(eip712["primaryType"], "Transaction");
        assert_eq!(eip712["domain"]["chainId"], 1);
        assert_eq!(eip712["message"]["to"], "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7");
    }
    
    #[test]
    fn test_to_qr_code() {
        let tx = TransactionBuilder::new()
            .to("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7")
            .value("1000000000000000000")
            .chain_id(1)
            .build();
        
        let qr = TransactionFormatter::to_qr_code(&tx).unwrap();
        
        assert!(qr["uri"].as_str().unwrap().starts_with("ethereum:"));
        assert_eq!(qr["format"], "EIP-681");
    }
}