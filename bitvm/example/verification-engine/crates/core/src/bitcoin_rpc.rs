// Bitcoin RPC client for interacting with regtest node

use bitcoin::{Transaction, Txid, Address, Network, Amount};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use crate::{BitVM3Error, Result};

/// Bitcoin RPC client for regtest operations
pub struct BitcoinRpcClient {
    url: String,
    auth: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BlockInfo {
    pub hash: String,
    pub height: u64,
    pub time: u64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TxInfo {
    pub txid: String,
    pub confirmations: u32,
    pub blockhash: Option<String>,
}

impl BitcoinRpcClient {
    /// Create new RPC client
    pub fn new(url: String, user: String, password: String) -> Self {
        let auth = base64::encode(format!("{}:{}", user, password));
        Self { url, auth }
    }
    
    /// Create default regtest client
    pub fn new_regtest() -> Self {
        Self::new(
            "http://localhost:18443".to_string(),
            "bitvm3".to_string(),
            "password".to_string(),
        )
    }
    
    /// Make RPC call
    async fn call(&self, method: &str, params: Vec<Value>) -> Result<Value> {
        let client = reqwest::Client::new();
        
        let request = json!({
            "jsonrpc": "2.0",
            "id": "bitvm3",
            "method": method,
            "params": params
        });
        
        let response = client
            .post(&self.url)
            .header("Authorization", format!("Basic {}", self.auth))
            .json(&request)
            .send()
            .await
            .map_err(|e| BitVM3Error::NetworkError(format!("RPC request failed: {}", e)))?;
        
        let result: Value = response.json().await
            .map_err(|e| BitVM3Error::NetworkError(format!("Failed to parse response: {}", e)))?;
        
        if let Some(error) = result.get("error") {
            return Err(BitVM3Error::NetworkError(format!("RPC error: {:?}", error)));
        }
        
        result.get("result")
            .cloned()
            .ok_or_else(|| BitVM3Error::NetworkError("No result in RPC response".to_string()))
    }
    
    /// Get current block height
    pub async fn get_block_count(&self) -> Result<u64> {
        let result = self.call("getblockcount", vec![]).await?;
        result.as_u64()
            .ok_or_else(|| BitVM3Error::NetworkError("Invalid block count".to_string()))
    }
    
    /// Generate blocks (regtest only)
    pub async fn generate_blocks(&self, count: u64, address: &Address) -> Result<Vec<String>> {
        let params = vec![
            json!(count),
            json!(address.to_string()),
        ];
        
        let result = self.call("generatetoaddress", params).await?;
        
        let blocks: Vec<String> = result.as_array()
            .ok_or_else(|| BitVM3Error::NetworkError("Invalid block array".to_string()))?
            .iter()
            .filter_map(|v| v.as_str().map(String::from))
            .collect();
        
        Ok(blocks)
    }
    
    /// Send raw transaction
    pub async fn send_raw_transaction(&self, tx: &Transaction) -> Result<Txid> {
        use bitcoin::consensus::encode::serialize_hex;
        
        let hex = serialize_hex(tx);
        let params = vec![json!(hex)];
        
        let result = self.call("sendrawtransaction", params).await?;
        
        let txid_str = result.as_str()
            .ok_or_else(|| BitVM3Error::NetworkError("Invalid txid".to_string()))?;
        
        txid_str.parse()
            .map_err(|e| BitVM3Error::NetworkError(format!("Failed to parse txid: {}", e)))
    }
    
    /// Get transaction info
    pub async fn get_transaction(&self, txid: &Txid) -> Result<TxInfo> {
        let params = vec![json!(txid.to_string())];
        let result = self.call("gettransaction", params).await?;
        
        Ok(TxInfo {
            txid: txid.to_string(),
            confirmations: result["confirmations"].as_u64().unwrap_or(0) as u32,
            blockhash: result["blockhash"].as_str().map(String::from),
        })
    }
    
    /// Fund an address with some BTC (regtest only)
    pub async fn fund_address(&self, address: &Address, amount: Amount) -> Result<Txid> {
        // First generate some blocks to get coins
        let coinbase_addr = Address::from_str("bcrt1q9vy6kkm2k5hfrw2r2qrt0xw7lhz2qfqqqqqqqq")
            .unwrap()
            .require_network(Network::Regtest)
            .unwrap();
        
        // Generate 101 blocks to make coins spendable
        self.generate_blocks(101, &coinbase_addr).await?;
        
        // Send coins to the target address
        let params = vec![
            json!(address.to_string()),
            json!(amount.to_btc()),
        ];
        
        let result = self.call("sendtoaddress", params).await?;
        
        let txid_str = result.as_str()
            .ok_or_else(|| BitVM3Error::NetworkError("Invalid txid".to_string()))?;
        
        txid_str.parse()
            .map_err(|e| BitVM3Error::NetworkError(format!("Failed to parse txid: {}", e)))
    }
    
    /// Create a new address
    pub async fn get_new_address(&self) -> Result<Address> {
        let result = self.call("getnewaddress", vec![]).await?;
        
        let addr_str = result.as_str()
            .ok_or_else(|| BitVM3Error::NetworkError("Invalid address".to_string()))?;
        
        Address::from_str(addr_str)
            .map_err(|e| BitVM3Error::NetworkError(format!("Failed to parse address: {}", e)))?
            .require_network(Network::Regtest)
            .map_err(|_| BitVM3Error::NetworkError("Address not for regtest".to_string()))
    }
    
    /// Test connection
    pub async fn test_connection(&self) -> Result<bool> {
        match self.call("getblockchaininfo", vec![]).await {
            Ok(_) => Ok(true),
            Err(_) => Ok(false),
        }
    }
}

// Helper to setup regtest environment
pub async fn setup_regtest_environment() -> Result<BitcoinRpcClient> {
    let client = BitcoinRpcClient::new_regtest();
    
    // Test connection
    if !client.test_connection().await? {
        return Err(BitVM3Error::NetworkError(
            "Cannot connect to Bitcoin regtest node. Make sure it's running with: make setup-bitcoin".to_string()
        ));
    }
    
    tracing::info!("Connected to Bitcoin regtest node");
    
    // Get current block height
    let height = client.get_block_count().await?;
    tracing::info!("Current block height: {}", height);
    
    // Generate initial blocks if needed
    if height < 100 {
        let addr = client.get_new_address().await?;
        client.generate_blocks(101, &addr).await?;
        tracing::info!("Generated initial blocks for regtest");
    }
    
    Ok(client)
}

use std::str::FromStr;

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    #[ignore] // Run only when regtest is available
    async fn test_bitcoin_rpc() {
        let client = BitcoinRpcClient::new_regtest();
        
        // Test connection
        assert!(client.test_connection().await.unwrap());
        
        // Get block count
        let count = client.get_block_count().await.unwrap();
        assert!(count >= 0);
    }
}