/// Example: Using abi-assistant as a library
/// 
/// This example demonstrates how to use the abi-assistant components
/// as a library in your own Rust application.
/// 
/// Note: This example assumes an MCP server is already running on localhost:3000

use abi_assistant::{
    abi::{encoder::AbiEncoder, decoder::AbiDecoder},
    intent::resolver::IntentResolver,
    transaction::builder::TransactionBuilder,
    config::Config,
};
use anyhow::Result;
use serde_json::json;

#[tokio::main]
async fn main() -> Result<()> {
    println!("=== ABI Assistant Library Usage Examples ===\n");
    println!("Note: This example demonstrates using the library components directly.");
    println!("      It assumes an MCP server is already running on localhost:3000.\n");
    
    // Example 1: Direct ABI encoding
    example_abi_encoding()?;
    
    // Example 2: Intent resolution
    example_intent_resolution()?;
    
    // Example 3: Transaction building
    example_transaction_building()?;
    
    // Example 4: Configuration loading
    example_config_loading()?;
    
    // Example 5: Making MCP calls to running server
    example_mcp_client().await?;
    
    Ok(())
}

/// Example 1: Direct ABI encoding without server
fn example_abi_encoding() -> Result<()> {
    println!("1. ABI ENCODING (Library Usage)");
    println!("--------------------------------");
    
    // Encode a transfer function call
    let encoded = AbiEncoder::encode_transfer(
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
        "1000000000000000000", // 1 ETH
    ).map_err(|e| anyhow::anyhow!("Encoding error: {}", e))?;
    
    println!("  Transfer encoded: {}", encoded);
    
    // Encode a generic function
    let params = json!(["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7", "1000"]);
    let generic = AbiEncoder::encode_function("transfer(address,uint256)", &params)
        .map_err(|e| anyhow::anyhow!("Encoding error: {}", e))?;
    
    println!("  Generic encoded: {}", generic);
    
    // Decode a transaction
    let decoded = AbiDecoder::decode_function_call(&encoded)
        .map_err(|e| anyhow::anyhow!("Decoding error: {}", e))?;
    println!("  Decoded: {} with {} params\n", decoded.function, decoded.params);
    
    Ok(())
}

/// Example 2: Intent resolution without server
fn example_intent_resolution() -> Result<()> {
    println!("2. INTENT RESOLUTION (Library Usage)");
    println!("------------------------------------");
    
    let resolver = IntentResolver::new();
    
    let intents = vec![
        "swap 100 USDC for ETH",
        "stake 32 ETH on Lido",
        "provide liquidity to Uniswap",
    ];
    
    for intent in intents {
        let result = resolver.resolve(intent)
            .map_err(|e| anyhow::anyhow!("Resolution error: {}", e))?;
        println!("  Intent: \"{}\"", intent);
        println!("    Category: {}", result.category.as_string());
        println!("    Confidence: {:.1}%", result.confidence * 100.0);
        if !result.contract_calls.is_empty() {
            println!("    Suggested: {} ({})", 
                result.contract_calls[0].protocol_name,
                result.contract_calls[0].function_name
            );
        }
        println!();
    }
    
    Ok(())
}

/// Example 3: Transaction building without server
fn example_transaction_building() -> Result<()> {
    println!("3. TRANSACTION BUILDING (Library Usage)");
    println!("---------------------------------------");
    
    let tx = TransactionBuilder::new()
        .to("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48") // USDC
        .from("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7")
        .value("0")
        .data("0xa9059cbb") // transfer selector
        .gas(65000)
        .build();
    
    println!("  Built transaction:");
    println!("    To: {}", tx.to);
    println!("    From: {:?}", tx.from);
    println!("    Gas: {:?}", tx.gas);
    println!("    Data: {}...\n", &tx.data[..10]);
    
    Ok(())
}

/// Example 4: Configuration loading
fn example_config_loading() -> Result<()> {
    println!("4. CONFIGURATION (Library Usage)");
    println!("--------------------------------");
    
    // Load configuration
    let config = Config::load()?;
    
    println!("  Server: {} v{}", config.server.name, config.server.version);
    println!("  Transport: {}", config.server.transport);
    println!("  Port: {}", config.server.port);
    println!("  Database: {}", config.database.url);
    println!("  Intent strategy: {}", config.intent.strategy);
    println!("  Gas strategy: {}\n", config.gas.price_strategy);
    
    Ok(())
}

/// Example 5: Making MCP calls to running server

/// Example 5: Making MCP calls to running server
async fn example_mcp_client() -> Result<()> {
    println!("5. MCP CLIENT (Connecting to localhost:3000)");
    println!("--------------------------------------------");
    
    // Simple HTTP client to test the running server
    let client = reqwest::Client::new();
    let base_url = "http://localhost:3000";
    
    // Test health endpoint
    let health_response = client
        .get(format!("{}/health", base_url))
        .send()
        .await;
    
    match health_response {
        Ok(resp) if resp.status().is_success() => {
            println!("  ✅ Server is running and healthy");
            
            // Test MCP endpoint
            let mcp_request = json!({
                "jsonrpc": "2.0",
                "method": "tools/list",
                "params": {},
                "id": 1
            });
            
            let mcp_response = client
                .post(format!("{}/message", base_url))
                .json(&mcp_request)
                .send()
                .await;
            
            match mcp_response {
                Ok(resp) if resp.status().is_success() => {
                    let body: serde_json::Value = resp.json().await?;
                    if let Some(result) = body.get("result") {
                        if let Some(tools) = result.get("tools").and_then(|t| t.as_array()) {
                            println!("  Available MCP tools: {} tools found", tools.len());
                            for tool in tools.iter().take(3) {
                                if let Some(name) = tool.get("name").and_then(|n| n.as_str()) {
                                    println!("    - {}", name);
                                }
                            }
                            if tools.len() > 3 {
                                println!("    ... and {} more", tools.len() - 3);
                            }
                        }
                    }
                }
                Ok(resp) => {
                    println!("  ⚠️  MCP endpoint returned: {}", resp.status());
                }
                Err(e) => {
                    println!("  ⚠️  Could not connect to MCP endpoint: {}", e);
                }
            }
        }
        Ok(resp) => {
            println!("  ⚠️  Server returned status: {}", resp.status());
            println!("  Make sure the MCP server is running on localhost:3000");
        }
        Err(_) => {
            println!("  ⚠️  Could not connect to server at {}", base_url);
            println!("  Please start the MCP server first:");
            println!("    cargo run");
        }
    }
    
    println!("\n✅ Library usage examples complete!");
    Ok(())
}