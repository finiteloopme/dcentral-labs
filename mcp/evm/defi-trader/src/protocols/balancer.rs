use ethers::prelude::*;
use std::sync::Arc;
use ethers::signers::{LocalWallet, Signer};

abigen!(IBalancerVault, "./abi/balancer_vault.json");

#[derive(Clone)]
pub struct Balancer {
    vault: IBalancerVault<SignerMiddleware<Provider<Http>, LocalWallet>>,
    wallet_address: Address,
}

impl Balancer {
    pub async fn new(rpc_url: &str, vault_address: Address, private_key: &str) -> Self {
        let provider = Provider::<Http>::try_from(rpc_url).unwrap();
        let chain_id = provider.get_chainid().await.unwrap();
        let wallet = private_key.parse::<LocalWallet>().unwrap().with_chain_id(chain_id.as_u64());
        let wallet_address = wallet.address();
        let client = SignerMiddleware::new(provider, wallet);
        let vault = IBalancerVault::new(vault_address, Arc::new(client));
        Self { vault, wallet_address }
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