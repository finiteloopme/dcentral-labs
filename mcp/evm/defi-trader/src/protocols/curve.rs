use ethers::prelude::*;
use std::sync::Arc;
use ethers::signers::{LocalWallet, Signer};

abigen!(
    ICurveRegistry, "./abi/curve_registry.json";
    ICurvePool, "./abi/curve_pool.json"
);

#[derive(Clone)]
pub struct Curve {
    registry: ICurveRegistry<Provider<Http>>,
    client: Arc<SignerMiddleware<Provider<Http>, LocalWallet>>,
}

impl Curve {
    pub async fn new(rpc_url: &str, registry_address: Address, private_key: &str) -> Self {
        let provider = Provider::<Http>::try_from(rpc_url).unwrap();
        let chain_id = provider.get_chainid().await.unwrap();
        let wallet = private_key.parse::<LocalWallet>().unwrap().with_chain_id(chain_id.as_u64());
        let client = Arc::new(SignerMiddleware::new(provider.clone(), wallet));
        let registry = ICurveRegistry::new(registry_address, Arc::new(provider));
        Self { registry, client }
    }

    pub async fn get_quote(&self, from_token: Address, to_token: Address, amount: U256) -> anyhow::Result<U256> {
        let pool_address = self.registry.find_pool_for_coins(from_token, to_token).call().await?;
        let (i, j, _) = self.registry.get_coin_indices(pool_address, from_token, to_token).call().await?;
        let pool = ICurvePool::new(pool_address, self.client.clone());
        let dy = pool.get_dy(i.into(), j.into(), amount).call().await?;
        Ok(dy)
    }

    pub async fn swap(&self, from_token: Address, to_token: Address, amount: U256) -> anyhow::Result<()> {
        let pool_address = self.registry.find_pool_for_coins(from_token, to_token).call().await?;
        let (i, j, _) = self.registry.get_coin_indices(pool_address, from_token, to_token).call().await?;
        let pool = ICurvePool::new(pool_address, self.client.clone());

        pool.exchange(i.into(), j.into(), amount, U256::zero())
            .send()
            .await?
            .await?;

        Ok(())
    }
}