
use ethers::prelude::*;
use std::sync::Arc;

abigen!(IUniswapV2Router, "./abi/uniswap_v2_router.json");

#[derive(Clone)]
pub struct UniswapV2 {
    router: IUniswapV2Router<Provider<Http>>,
}

impl UniswapV2 {
    pub fn new(rpc_url: &str, router_address: Address) -> Self {
        let provider = Provider::<Http>::try_from(rpc_url).unwrap();
        let router = IUniswapV2Router::new(router_address, Arc::new(provider));
        Self { router }
    }

    pub async fn get_quote(&self, from_token: Address, to_token: Address, amount: U256) -> anyhow::Result<U256> {
        let amounts_out = self.router.get_amounts_out(amount, vec![from_token, to_token]).call().await?;
        Ok(amounts_out[1])
    }

    pub async fn swap(&self, _from_token: Address, _to_token: Address, _amount: U256) -> anyhow::Result<()> {
        // TODO: Implement this function.
        Ok(())
    }
}
