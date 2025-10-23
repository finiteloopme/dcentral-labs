/// Example demonstrating Phase 3 transaction building and signing tools
/// 
/// This example shows how to:
/// 1. Encode function calls with ABI
/// 2. Decode existing transactions
/// 3. Build complete transactions
/// 4. Export transactions for signing in various formats

use abi_assistant::{
    abi::{encoder::AbiEncoder, decoder::AbiDecoder},
    transaction::{
        builder::{TransactionBuilder, build_token_transfer, build_token_approval, build_uniswap_swap},
        formatter::{TransactionFormatter, ExportFormat},
    },
};
use serde_json::json;

fn main() {
    println!("=== ABI Assistant - Phase 3 Transaction Building Demo ===\n");
    
    // 1. Encode Function Calls
    println!("1. ENCODING FUNCTION CALLS");
    println!("{}", "-".repeat(50));
    
    // Encode a simple transfer
    let transfer_encoded = AbiEncoder::encode_transfer(
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
        "1000000000000000000", // 1 token with 18 decimals
    ).unwrap();
    
    println!("Transfer encoded: {}", transfer_encoded);
    println!("  Selector: {}", &transfer_encoded[..10]);
    println!("  Data length: {} bytes\n", (transfer_encoded.len() - 2) / 2);
    
    // Encode a generic function with JSON parameters
    let params = json!(["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", "1000000000000000000"]);
    let generic_encoded = AbiEncoder::encode_function(
        "transfer(address,uint256)",
        &params,
    ).unwrap();
    
    println!("Generic transfer encoded: {}", generic_encoded);
    
    // Encode an approval (using a smaller value that fits in u128)
    let approval_encoded = AbiEncoder::encode_approve(
        "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Uniswap router
        "1000000000000000000000", // 1000 tokens
    ).unwrap();
    
    println!("Approval encoded: {}", approval_encoded);
    println!();
    
    // 2. Decode Transactions
    println!("2. DECODING TRANSACTIONS");
    println!("{}", "-".repeat(50));
    
    let tx_data = "0xa9059cbb000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb70000000000000000000000000000000000000000000000000de0b6b3a7640000";
    
    match AbiDecoder::decode_function_call(tx_data) {
        Ok(decoded) => {
            println!("Decoded transaction:");
            println!("  Function: {}", decoded.function);
            println!("  Parameters: {}", serde_json::to_string_pretty(&decoded.params).unwrap());
        },
        Err(e) => println!("Failed to decode: {}", e),
    }
    
    println!();
    
    // 3. Build Complete Transactions
    println!("3. BUILDING TRANSACTIONS");
    println!("{}", "-".repeat(50));
    
    // Build an ERC20 transfer transaction
    let token_transfer = build_token_transfer(
        "0x6B175474E89094C44Da98b954EedeAC495271d0F", // DAI token
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", // recipient
        "1000000000000000000", // 1 DAI
        Some("0x1234567890123456789012345678901234567890"), // sender
    ).unwrap();
    
    println!("Token Transfer Transaction:");
    println!("  To: {}", token_transfer.to);
    println!("  Data: {}...", &token_transfer.data[..42]);
    println!("  Gas: {:?}", token_transfer.gas);
    println!();
    
    // Build a token approval transaction
    let approval_tx = build_token_approval(
        "0x6B175474E89094C44Da98b954EedeAC495271d0F", // DAI token
        "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Uniswap router
        "1000000000000000000000", // 1000 DAI
        Some("0x1234567890123456789012345678901234567890"),
    ).unwrap();
    
    println!("Approval Transaction:");
    println!("  To: {}", approval_tx.to);
    println!("  Data: {}...", &approval_tx.data[..42]);
    println!();
    
    // Build a Uniswap swap transaction
    let swap_tx = build_uniswap_swap(
        "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Uniswap V2 router
        "1000000000000000000", // 1 token in
        "900000000000000000", // minimum 0.9 tokens out
        vec![
            "0x6B175474E89094C44Da98b954EedeAC495271d0F".to_string(), // DAI
            "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2".to_string(), // WETH
        ],
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", // recipient
        "9999999999", // deadline
        Some("0x1234567890123456789012345678901234567890"),
    ).unwrap();
    
    println!("Swap Transaction:");
    println!("  To: {}", swap_tx.to);
    println!("  Data length: {} bytes", (swap_tx.data.len() - 2) / 2);
    println!();
    
    // 4. Export Transactions for Signing
    println!("4. EXPORTING FOR SIGNING");
    println!("{}", "-".repeat(50));
    
    // Build a custom transaction
    let custom_tx = TransactionBuilder::new()
        .from("0x1234567890123456789012345678901234567890")
        .to("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7")
        .value("1000000000000000000") // 1 ETH
        .gas(21000)
        .gas_price(30000000000) // 30 gwei
        .chain_id(1)
        .build();
    
    // Export as raw JSON (for web3.js/ethers.js)
    let raw_json = TransactionFormatter::export(&custom_tx, ExportFormat::RawJson).unwrap();
    println!("Raw JSON format:");
    println!("{}", serde_json::to_string_pretty(&raw_json).unwrap());
    println!();
    
    // Export as EIP-712 typed data (for smart wallets)
    let eip712 = TransactionFormatter::export(&custom_tx, ExportFormat::Eip712).unwrap();
    println!("EIP-712 Typed Data format:");
    println!("  Primary Type: {}", eip712["primaryType"]);
    println!("  Domain Chain ID: {}", eip712["domain"]["chainId"]);
    println!();
    
    // Export as QR code data (for mobile wallets)
    let qr_code = TransactionFormatter::export(&custom_tx, ExportFormat::QrCode).unwrap();
    println!("QR Code format:");
    println!("  URI: {}", qr_code["uri"]);
    println!();
    
    // Export for WalletConnect
    let wallet_connect = TransactionFormatter::export(&custom_tx, ExportFormat::WalletConnect).unwrap();
    println!("WalletConnect format:");
    println!("  Method: {}", wallet_connect["method"]);
    println!();
    
    // Export for Ethers.js
    let ethers_js = TransactionFormatter::export(&custom_tx, ExportFormat::EthersJs).unwrap();
    println!("Ethers.js format:");
    println!("{}", serde_json::to_string_pretty(&ethers_js).unwrap());
    println!();
    
    // 5. Complete Workflow Example
    println!("5. COMPLETE WORKFLOW");
    println!("{}", "-".repeat(50));
    println!("Example: User wants to swap DAI for ETH\n");
    
    // Step 1: Approve DAI spending
    println!("Step 1: Build approval transaction");
    let approve_tx = build_token_approval(
        "0x6B175474E89094C44Da98b954EedeAC495271d0F", // DAI
        "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Router
        "1000000000000000000000", // 1000 DAI
        Some("0xUser0000000000000000000000000000000000"),
    ).unwrap();
    
    let approve_export = TransactionFormatter::export(&approve_tx, ExportFormat::RawJson).unwrap();
    println!("  Approval ready for signing: {}", approve_export["to"]);
    
    // Step 2: Build swap transaction
    println!("\nStep 2: Build swap transaction");
    let swap_tx = build_uniswap_swap(
        "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        "1000000000000000000000", // 1000 DAI
        "300000000000000000", // Min 0.3 ETH out
        vec![
            "0x6B175474E89094C44Da98b954EedeAC495271d0F".to_string(), // DAI
            "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2".to_string(), // WETH
        ],
        "0xUser0000000000000000000000000000000000",
        "9999999999",
        Some("0xUser0000000000000000000000000000000000"),
    ).unwrap();
    
    let swap_export = TransactionFormatter::export(&swap_tx, ExportFormat::RawJson).unwrap();
    println!("  Swap ready for signing: {}", swap_export["to"]);
    
    // Step 3: Export both for batch signing
    println!("\nStep 3: Export for MetaMask batch signing");
    let batch = json!({
        "transactions": [approve_export, swap_export],
        "description": "Swap 1000 DAI for ETH (2 transactions: approve + swap)"
    });
    
    println!("  Batch ready: {} transactions", batch["transactions"].as_array().unwrap().len());
    println!("\n✅ Complete workflow ready for user signing!");
}