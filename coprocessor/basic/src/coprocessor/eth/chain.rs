use ethers::{
    prelude::*,
    providers::{Provider, Ws},
};
use std::sync::Arc;

abigen!(ImageProcessor, "../image-processor/out/ImageProcessor.sol/ImageProcessor.json");

async fn listen_ethereum_events(
    provider: Provider<Ws>,
    contract_address: Address
) -> Result<(), Box<dyn std::error::Error>> {

    // Load the contract instance
    let contract = get_contract_instance(provider, contract_address);
    // Listen for events emitted by the contract
    let events = contract.events();
    let mut events = events.subscribe().await.unwrap();
    println!("In the event loop...");   
    // Event loop
    while let Some(event) = events.next().await {
        match event {
            Ok(log) => {
                println!("New Event {:?}", log);
                // Trigger your image analysis and smart contract callback
                // For example:
                // let image_path = get_image_path_from_event(&log);
                // let detected_objects = analyze_image(&image_path)?;
                // call_smart_contract(contract_address, detected_objects).await?;
            }
            Err(e) => return Err(Box::new(e)),
        }
    }

    Ok(())
}

async fn call_smart_contract(
    provider: Provider<Ws>,
    contract_address: Address,
    uploader: Address,
    result: String,
    wallet: LocalWallet,
) -> Result<(), Box<dyn std::error::Error>> {
    
    // Create a contract instance
    let chain_id = provider.get_chainid().await?.as_u64();
    let signer = Arc::new(
        SignerMiddleware::new(
            provider, 
            wallet.with_chain_id(
                chain_id
            )
        )
    );
    let contract = get_signed_contract_instance(signer, contract_address);
    // Call the submitResult function
    let submit_result_method = contract.submit_icon(uploader, result);
    // Call the submitResult function
    let tx = submit_result_method
        .send()
        .await?;

    // Wait for the transaction to be mined
    let _receipt = tx.await?;

    Ok(())
}

fn get_contract_instance(client: Provider<Ws>, contract_address: Address) -> ImageProcessor<Provider<Ws>> {
    ImageProcessor::new(contract_address, Arc::new(client))
}

fn get_signed_contract_instance(client: Arc<SignerMiddleware<Provider<Ws>, LocalWallet>>, contract_address: Address) -> ImageProcessor<SignerMiddleware<Provider<Ws>, LocalWallet>> {
    ImageProcessor::new(contract_address, client)
}

pub async fn run(url: String, contract_address: Address) -> Result<(), Box<dyn std::error::Error>> {
    // Connect to the Ethereum node
    let provider = Provider::<Ws>::connect(url).await?;

    // Listen for events
    listen_ethereum_events(provider, contract_address).await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use ethers::{
        core::utils::{Anvil, AnvilInstance},
        middleware::SignerMiddleware,
        providers::{Provider, Ws},
        signers::{LocalWallet, Signer},
    };
    use std::sync::Arc;

    async fn setup_anvil() -> (AnvilInstance, Provider<Ws>, LocalWallet, Address) {
        // Start Anvil
        let anvil = Anvil::new().spawn();

        // Connect to the local provider
        let provider = Provider::<Ws>::connect(anvil.ws_endpoint()).await.unwrap();

        // Create a wallet
        let wallet: LocalWallet = anvil.keys()[0].clone().into();

        // Create a signer
        let signer = Arc::new(
            SignerMiddleware::new(provider.clone(), wallet.clone().with_chain_id(anvil.chain_id()))
        );

        // Deploy contract
        let contract = ImageProcessor::deploy(signer, ()).unwrap().send().await.unwrap();
        let contract_address = contract.address();

        (anvil, provider, wallet, contract_address)
    }

    #[tokio::test]
    async fn test_get_contract_instance() {
        let (anvil, provider, _, contract_address) = setup_anvil().await;
    
        let contract = get_contract_instance(provider, contract_address);
    
        assert_eq!(contract.address(), contract_address);
        drop(anvil); // Stop the Anvil instance
    }
    
    #[tokio::test]
    async fn test_get_signed_contract_instance() {
        let (anvil, provider, wallet, contract_address) = setup_anvil().await;
    
        let chain_id = provider.get_chainid().await.unwrap().as_u64();
        let signer = Arc::new(SignerMiddleware::new(
            provider,
            wallet.with_chain_id(chain_id),
        ));
    
        let contract = get_signed_contract_instance(signer, contract_address);
    
        assert_eq!(contract.address(), contract_address);
        drop(anvil); // Stop the Anvil instance
    }
    
    #[tokio::test]
    async fn test_call_smart_contract() {
        let (anvil, provider, wallet, contract_address) = setup_anvil().await;
        let uploader = Address::random();
        let result = "test_result".to_string();
    
        // Now this test should work because we have a real contract deployed
        let result = call_smart_contract(provider, contract_address, uploader, result, wallet).await;
        assert!(result.is_ok());
    
        drop(anvil); // Stop the Anvil instance
    }    
}