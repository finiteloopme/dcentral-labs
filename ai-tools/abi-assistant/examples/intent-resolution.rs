/// Example demonstrating the intent resolution system with Gemini integration
/// 
/// This example shows how to:
/// 1. Use the local intent resolver
/// 2. Use the Gemini resolver
/// 3. Use the hybrid resolver with different strategies
/// 4. Work with the cache system

use abi_assistant::intent::{
    resolver::IntentResolver,
    hybrid_resolver::HybridIntentResolver,
    gemini::{client::MockGeminiClient, resolver::{GeminiResolver, UserContext}},
    cache::IntentCache,
    prompt::{loader::PromptLoader, config::IntentStrategy},
    discovery::MockProtocolDiscovery,
};
use std::sync::Arc;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    println!("=== ABI Assistant Intent Resolution Examples ===\n");

    // Example 1: Local Intent Resolution
    example_local_resolution()?;
    
    // Example 2: Gemini Intent Resolution (with mock)
    example_gemini_resolution().await?;
    
    // Example 3: Hybrid Resolution with Different Strategies
    example_hybrid_resolution().await?;
    
    // Example 4: Cache System
    example_cache_system()?;

    Ok(())
}

fn example_local_resolution() -> anyhow::Result<()> {
    println!("1. Local Intent Resolution");
    println!("{}", "-".repeat(40));
    
    let resolver = IntentResolver::new();
    
    // Test various intents
    let intents = vec![
        "swap 100 USDC for ETH",
        "lend 1000 DAI on Aave",
        "stake 32 ETH",
        "provide liquidity with 100 USDC and 0.1 ETH",
    ];
    
    for intent_text in intents {
        let result = resolver.resolve(intent_text)?;
        println!("\nIntent: {}", intent_text);
        println!("Category: {:?}", result.category);
        println!("Confidence: {:.2}", result.confidence);
        println!("Suggested protocols: {}", result.contract_calls.len());
        
        if let Some(first_call) = result.contract_calls.first() {
            println!("  Top suggestion: {} - {}", 
                first_call.protocol_name, 
                first_call.function_name
            );
        }
    }
    
    println!();
    Ok(())
}

async fn example_gemini_resolution() -> anyhow::Result<()> {
    println!("2. Gemini Intent Resolution (Mock)");
    println!("{}", "-".repeat(40));
    
    // Create mock Gemini client with predefined responses
    let mock_response = r#"{
        "intent_type": "swap",
        "confidence": 0.95,
        "parameters": {
            "tokens_involved": ["USDC", "ETH"],
            "amounts": ["100"],
            "constraints": {"slippage": "0.5"}
        },
        "preferences": {
            "mentioned_protocols": ["Uniswap"],
            "optimization_goal": "best_price"
        },
        "multi_step": false
    }"#;
    
    let gemini_client = Arc::new(MockGeminiClient::new(vec![mock_response.to_string()]));
    let prompt_loader = Arc::new(PromptLoader::new("./prompts", false));
    let protocol_discovery = Arc::new(MockProtocolDiscovery::new());
    
    let resolver = GeminiResolver::new(gemini_client, prompt_loader, protocol_discovery);
    
    let user_context = UserContext {
        chain_id: 1,
        user_address: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0".to_string(),
        gas_price: 30_000_000_000,
    };
    
    let intent = resolver.resolve("swap 100 USDC for ETH with 0.5% slippage", &user_context).await?;
    
    println!("\nGemini-resolved intent:");
    println!("Category: {:?}", intent.category);
    println!("Confidence: {:.2}", intent.confidence);
    println!("Parameters: {:?}", intent.parameters);
    
    println!();
    Ok(())
}

async fn example_hybrid_resolution() -> anyhow::Result<()> {
    println!("3. Hybrid Resolution Strategies");
    println!("{}", "-".repeat(40));
    
    let cache = Arc::new(IntentCache::new(100, 3600));
    let prompt_loader = Arc::new(PromptLoader::new("./prompts", false));
    let protocol_discovery = Arc::new(MockProtocolDiscovery::new());
    
    // Test different strategies
    let strategies = vec![
        (IntentStrategy::LocalOnly, "Local Only"),
        (IntentStrategy::LocalFirst, "Local First (with Gemini fallback)"),
        (IntentStrategy::Smart, "Smart Routing"),
    ];
    
    for (strategy, name) in strategies {
        println!("\nStrategy: {}", name);
        
        let resolver: HybridIntentResolver<MockGeminiClient> = HybridIntentResolver::new(
            None, // No Gemini client for local-only
            prompt_loader.clone(),
            protocol_discovery.clone(),
            cache.clone(),
            strategy,
            0.7, // confidence threshold
        );
        
        let user_context = UserContext::default();
        let query = "I want to swap 100 USDC for ETH";
        
        match resolver.resolve(query, &user_context).await {
            Ok(intent) => {
                println!("  Resolved with confidence: {:.2}", intent.confidence);
                println!("  Category: {:?}", intent.category);
            }
            Err(e) => {
                println!("  Error: {}", e);
            }
        }
    }
    
    println!();
    Ok(())
}

fn example_cache_system() -> anyhow::Result<()> {
    println!("4. Cache System");
    println!("{}", "-".repeat(40));
    
    let cache = IntentCache::new(100, 60); // 100 entries, 60 second TTL
    let resolver = IntentResolver::new();
    
    // First resolution - cache miss
    let query = "swap 100 USDC for ETH";
    println!("\nFirst query: {}", query);
    
    let start = std::time::Instant::now();
    let intent1 = resolver.resolve(query)?;
    let duration1 = start.elapsed();
    println!("  Time: {:?} (cache miss)", duration1);
    
    // Store in cache
    cache.put(query, abi_assistant::intent::Intent {
        raw_text: query.to_string(),
        category: intent1.category,
        confidence: intent1.confidence,
        parameters: intent1.parameters,
        suggested_protocols: vec![],
    });
    
    // Second resolution - cache hit
    println!("\nSecond query (same): {}", query);
    let start = std::time::Instant::now();
    
    if let Some(cached_intent) = cache.get(query) {
        let duration2 = start.elapsed();
        println!("  Time: {:?} (cache hit)", duration2);
        println!("  Speed improvement: {:.1}x", duration1.as_nanos() as f64 / duration2.as_nanos() as f64);
    }
    
    // Test query normalization
    let normalized_queries = vec![
        "I want to swap 100 USDC for ETH",
        "SWAP 100 USDC FOR ETH!!!",
        "Please swap 100 usdc for eth",
    ];
    
    println!("\nQuery normalization test:");
    for q in normalized_queries {
        if cache.get(q).is_some() {
            println!("  ✓ Cache hit for: {}", q);
        } else {
            println!("  ✗ Cache miss for: {}", q);
        }
    }
    
    // Show cache statistics
    let stats = cache.stats();
    println!("\nCache Statistics:");
    println!("  Total entries: {}", stats.total_entries);
    println!("  Total hits: {}", stats.total_hits);
    println!("  Capacity: {}", stats.capacity);
    
    println!();
    Ok(())
}