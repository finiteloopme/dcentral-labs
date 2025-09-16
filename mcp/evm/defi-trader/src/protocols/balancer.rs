
use ethers::prelude::*;
use std::sync::Arc;

abigen!(IBalancerVault, "./abi/balancer_vault.json");

#[derive(Clone)]
pub struct Balancer {
    vault: IBalancerVault<Provider<Http>>,
}

impl Balancer {
    pub fn new(rpc_url: &str, vault_address: Address) -> Self {
        let provider = Provider::<Http>::try_from(rpc_url).unwrap();
        let vault = IBalancerVault::new(vault_address, Arc::new(provider));
        Self { vault }
    }

    pub async fn get_quote(&self, _from_token: Address, _to_token: Address, _amount: U256) -> anyhow::Result<U256> {
        // TODO: Implement this function.
        tracing::info!("Balancer vault address: {:?}", self.vault.address());
        Ok(U256::zero())
    }

    pub async fn swap(&self, _from_token: Address, _to_token: Address, _amount: U256) -> anyhow::Result<()> {
        // TODO: Implement this function.
        Ok(())
    }
}
