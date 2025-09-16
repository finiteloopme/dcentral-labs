use serde::Deserialize;

#[derive(Deserialize, Clone)]
pub struct Config {
    pub bind_address: String,
    pub rpc_url: String,
    pub uniswap_v2_router: String,
    pub curve_registry: String,
    pub balancer_vault: String,
    pub sushiswap_router: String,
    // pub private_key: String,
}