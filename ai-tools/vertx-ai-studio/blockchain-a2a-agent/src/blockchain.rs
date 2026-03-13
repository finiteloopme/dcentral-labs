use anyhow::{Context, Result};
use serde::Serialize;
use serde_json::json;

/// Response from a single blockchain network query.
#[derive(Debug, Clone, Serialize)]
pub struct NetworkResponse {
    pub network: String,
    pub block_height: u64,
    pub raw_value: String,
    pub source: String,
}

impl std::fmt::Display for NetworkResponse {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}: {} (source: {})", self.network, self.block_height, self.source)
    }
}

/// Fetch the current Bitcoin block height from mempool.space.
pub async fn fetch_bitcoin(client: &reqwest::Client) -> Result<NetworkResponse> {
    let resp = client
        .get("https://mempool.space/api/blocks/tip/height")
        .send()
        .await
        .context("failed to reach mempool.space")?;

    let text = resp.text().await.context("failed to read BTC response body")?;
    let height: u64 = text.trim().parse().context("failed to parse BTC block height")?;

    Ok(NetworkResponse {
        network: "Bitcoin".into(),
        block_height: height,
        raw_value: text.trim().to_string(),
        source: "mempool.space".into(),
    })
}

/// Fetch the current Ethereum block number from mevblocker.io.
pub async fn fetch_ethereum(client: &reqwest::Client) -> Result<NetworkResponse> {
    let payload = json!({"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1});

    let resp = client
        .post("https://rpc.mevblocker.io")
        .json(&payload)
        .send()
        .await
        .context("failed to reach mevblocker.io")?;

    let body: serde_json::Value = resp.json().await.context("failed to parse ETH JSON-RPC response")?;

    let hex_str = body["result"]
        .as_str()
        .context("missing 'result' field in ETH response")?;

    // Strip the "0x" prefix and parse hex to u64.
    let height = u64::from_str_radix(hex_str.trim_start_matches("0x"), 16)
        .context("failed to parse ETH hex block number")?;

    Ok(NetworkResponse {
        network: "Ethereum".into(),
        block_height: height,
        raw_value: hex_str.to_string(),
        source: "rpc.mevblocker.io".into(),
    })
}

/// Fetch the current Solana slot number from mainnet-beta.
pub async fn fetch_solana(client: &reqwest::Client) -> Result<NetworkResponse> {
    let payload = json!({"jsonrpc": "2.0", "id": 1, "method": "getSlot"});

    let resp = client
        .post("https://api.mainnet-beta.solana.com")
        .json(&payload)
        .send()
        .await
        .context("failed to reach Solana mainnet-beta")?;

    let body: serde_json::Value = resp.json().await.context("failed to parse SOL JSON-RPC response")?;

    let slot = body["result"]
        .as_u64()
        .context("missing 'result' field in SOL response")?;

    Ok(NetworkResponse {
        network: "Solana".into(),
        block_height: slot,
        raw_value: slot.to_string(),
        source: "api.mainnet-beta.solana.com".into(),
    })
}

/// Fetch all three networks in parallel, returning whatever succeeds.
pub async fn fetch_all(client: &reqwest::Client) -> Vec<NetworkResponse> {
    let (btc, eth, sol) = tokio::join!(
        fetch_bitcoin(client),
        fetch_ethereum(client),
        fetch_solana(client),
    );

    let mut results = Vec::with_capacity(3);
    if let Ok(r) = btc { results.push(r); }
    if let Ok(r) = eth { results.push(r); }
    if let Ok(r) = sol { results.push(r); }
    results
}
