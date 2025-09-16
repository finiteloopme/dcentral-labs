
use ethers::prelude::*;
use std::sync::Arc;

abigen!(ICurveRegistry, "./abi/curve_registry.json");

#[derive(Clone)]
pub struct Curve {
    registry: ICurveRegistry<Provider<Http>>,
}

impl Curve {
    pub fn new(rpc_url: &str, registry_address: Address) -> Self {
        let provider = Provider::<Http>::try_from(rpc_url).unwrap();
        let registry = ICurveRegistry::new(registry_address, Arc::new(provider));
        Self { registry }
    }

    pub async fn get_quote(&self, from_token: Address, to_token: Address, _amount: U256) -> anyhow::Result<U256> {
        let _pool = self.registry.find_pool_for_coins(from_token, to_token).call().await?;
        // TODO: get quote from pool
        Ok(U256::zero())
    }

    pub async fn swap(&self, _from_token: Address, _to_token: Address, _amount: U256) -> anyhow::Result<()> {
        // TODO: Implement this function.
        Ok(())
    }
}
