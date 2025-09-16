use ethers::prelude::*;
use std::sync::Arc;
use ethers::signers::{LocalWallet, Signer};
use std::time::{SystemTime, UNIX_EPOCH};

abigen!(ISushiSwapRouter, "./abi/sushiswap_router.json");

#[derive(Clone)]
pub struct SushiSwap {
    router: ISushiSwapRouter<SignerMiddleware<Provider<Http>, LocalWallet>>,
    wallet_address: Address,
}

impl SushiSwap {
    pub async fn new(rpc_url: &str, router_address: Address, private_key: &str) -> Self {
        let provider = Provider::<Http>::try_from(rpc_url).unwrap();
        let chain_id = provider.get_chainid().await.unwrap();
        let wallet = private_key.parse::<LocalWallet>().unwrap().with_chain_id(chain_id.as_u64());
        let wallet_address = wallet.address();
        let client = SignerMiddleware::new(provider, wallet);
        let router = ISushiSwapRouter::new(router_address, Arc::new(client));
        Self { router, wallet_address }
    }

    pub async fn get_quote(&self, from_token: Address, to_token: Address, amount: U256) -> anyhow::Result<U256> {
        let amounts_out = self.router.get_amounts_out(amount, vec![from_token, to_token]).call().await?;
        Ok(amounts_out[1])
    }

    pub async fn swap(&self, from_token: Address, to_token: Address, amount: U256) -> anyhow::Result<()> {
        let deadline = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs()
            + 60 * 20; // 20 minutes from now

        self.router
            .swap_exact_tokens_for_tokens(
                amount,
                U256::zero(),
                vec![from_token, to_token],
                self.wallet_address,
                U256::from(deadline),
            )
            .send()
            .await?
            .await?;

        Ok(())
    }
}