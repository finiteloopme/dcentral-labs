use super::Intent;
use super::resolver::IntentResolver as LocalResolver;
use super::gemini::{GeminiApi, resolver::{GeminiResolver, UserContext}};
use super::cache::IntentCache;
use super::prompt::{loader::PromptLoader, config::IntentStrategy};
use super::discovery::ProtocolDiscovery;
use anyhow::{Result, Context as AnyhowContext};
use std::sync::Arc;
use tracing::{info, warn, debug};

/// Hybrid intent resolver that combines Gemini AI and local pattern matching
pub struct HybridIntentResolver<G: GeminiApi> {
    gemini_resolver: Option<Arc<GeminiResolver<G>>>,
    local_resolver: Arc<LocalResolver>,
    cache: Arc<IntentCache>,
    strategy: IntentStrategy,
    confidence_threshold: f64,
}

impl<G: GeminiApi> HybridIntentResolver<G> {
    pub fn new(
        gemini_client: Option<Arc<G>>,
        prompt_loader: Arc<PromptLoader>,
        protocol_discovery: Arc<dyn ProtocolDiscovery>,
        cache: Arc<IntentCache>,
        strategy: IntentStrategy,
        confidence_threshold: f64,
    ) -> Self {
        let gemini_resolver = gemini_client.map(|client| {
            Arc::new(GeminiResolver::new(client, prompt_loader, protocol_discovery))
        });
        
        let local_resolver = Arc::new(LocalResolver::new());
        
        Self {
            gemini_resolver,
            local_resolver,
            cache,
            strategy,
            confidence_threshold,
        }
    }
    
    pub async fn resolve(&self, query: &str, user_context: &UserContext) -> Result<Intent> {
        // Check cache first
        if let Some(cached_intent) = self.cache.get(query) {
            debug!("Cache hit for query: {}", query);
            return Ok(cached_intent);
        }
        
        debug!("Cache miss for query: {}, using strategy: {:?}", query, self.strategy);
        
        // Execute based on strategy
        let intent = match self.strategy {
            IntentStrategy::GeminiOnly => {
                self.resolve_with_gemini_only(query, user_context).await?
            }
            IntentStrategy::LocalOnly => {
                self.resolve_with_local_only(query)?
            }
            IntentStrategy::GeminiFirst => {
                self.resolve_with_gemini_first(query, user_context).await?
            }
            IntentStrategy::LocalFirst => {
                self.resolve_with_local_first(query, user_context).await?
            }
            IntentStrategy::Smart => {
                self.resolve_with_smart_routing(query, user_context).await?
            }
        };
        
        // Cache the result
        self.cache.put(query, intent.clone());
        
        Ok(intent)
    }
    
    async fn resolve_with_gemini_only(&self, query: &str, user_context: &UserContext) -> Result<Intent> {
        let gemini = self.gemini_resolver
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("Gemini resolver not available"))?;
        
        gemini.resolve(query, user_context).await
            .context("Failed to resolve intent with Gemini")
    }
    
    fn resolve_with_local_only(&self, query: &str) -> Result<Intent> {
        let resolved = self.local_resolver.resolve(query)
            .context("Failed to resolve intent locally")?;
        
        // Convert ResolvedIntent to Intent
        Ok(Intent {
            raw_text: resolved.original_text,
            category: resolved.category,
            confidence: resolved.confidence,
            parameters: resolved.parameters,
            suggested_protocols: resolved.contract_calls.into_iter().map(|call| {
                super::ProtocolSuggestion {
                    protocol_name: call.protocol_name,
                    protocol_address: Some(call.contract_address),
                    function_name: call.function_name,
                    confidence: call.confidence,
                    gas_estimate: call.estimated_gas,
                }
            }).collect(),
        })
    }
    
    async fn resolve_with_gemini_first(&self, query: &str, user_context: &UserContext) -> Result<Intent> {
        if let Some(gemini) = &self.gemini_resolver {
            match gemini.resolve(query, user_context).await {
                Ok(intent) => {
                    info!("Successfully resolved intent with Gemini");
                    return Ok(intent);
                }
                Err(e) => {
                    warn!("Gemini resolution failed: {}, falling back to local", e);
                }
            }
        }
        
        self.resolve_with_local_only(query)
    }
    
    async fn resolve_with_local_first(&self, query: &str, user_context: &UserContext) -> Result<Intent> {
        let local_resolved = self.local_resolver.resolve(query)?;
        let local_intent = Intent {
            raw_text: local_resolved.original_text,
            category: local_resolved.category,
            confidence: local_resolved.confidence,
            parameters: local_resolved.parameters,
            suggested_protocols: local_resolved.contract_calls.into_iter().map(|call| {
                super::ProtocolSuggestion {
                    protocol_name: call.protocol_name,
                    protocol_address: Some(call.contract_address),
                    function_name: call.function_name,
                    confidence: call.confidence,
                    gas_estimate: call.estimated_gas,
                }
            }).collect(),
        };
        
        if local_intent.confidence >= self.confidence_threshold {
            info!("Local resolution has high confidence: {}", local_intent.confidence);
            return Ok(local_intent);
        }
        
        info!("Local confidence {} below threshold {}, trying Gemini", 
              local_intent.confidence, self.confidence_threshold);
        
        if let Some(gemini) = &self.gemini_resolver {
            match gemini.resolve(query, user_context).await {
                Ok(gemini_intent) => {
                    if gemini_intent.confidence > local_intent.confidence {
                        return Ok(gemini_intent);
                    }
                }
                Err(e) => {
                    warn!("Gemini resolution failed: {}", e);
                }
            }
        }
        
        Ok(local_intent)
    }
    
    async fn resolve_with_smart_routing(&self, query: &str, user_context: &UserContext) -> Result<Intent> {
        let complexity = self.assess_query_complexity(query);
        
        if complexity > 3 {
            info!("Query complexity {} > 3, using Gemini", complexity);
            if let Some(gemini) = &self.gemini_resolver {
                if let Ok(intent) = gemini.resolve(query, user_context).await {
                    return Ok(intent);
                }
            }
        }
        
        // For simple queries or if Gemini fails, use local
        self.resolve_with_local_only(query)
    }
    
    fn assess_query_complexity(&self, query: &str) -> usize {
        let mut complexity = 0;
        
        // Count tokens
        let tokens: Vec<&str> = query.split_whitespace().collect();
        if tokens.len() > 10 {
            complexity += 1;
        }
        
        // Check for multiple operations
        let operation_keywords = ["and", "then", "after", "before", "also"];
        for keyword in operation_keywords {
            if query.contains(keyword) {
                complexity += 1;
            }
        }
        
        // Check for conditional logic
        if query.contains("if") || query.contains("when") || query.contains("unless") {
            complexity += 2;
        }
        
        // Check for specific constraints
        if query.contains("slippage") || query.contains("deadline") || query.contains("minimum") {
            complexity += 1;
        }
        
        complexity
    }
    
    /// Update the resolution strategy at runtime
    pub fn set_strategy(&mut self, strategy: IntentStrategy) {
        self.strategy = strategy;
        info!("Updated intent resolution strategy to: {:?}", strategy);
    }
    
    /// Clear the cache
    pub fn clear_cache(&self) {
        self.cache.clear();
        info!("Intent cache cleared");
    }
    
    /// Get cache statistics
    pub fn cache_stats(&self) -> super::cache::CacheStats {
        self.cache.stats()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::intent::IntentCategory;
    use crate::intent::gemini::client::MockGeminiClient;
    use crate::intent::discovery::MockProtocolDiscovery;
    use tempfile::TempDir;
    
    #[tokio::test]
    async fn test_hybrid_resolver_local_only() {
        let cache = Arc::new(IntentCache::new(100, 60));
        let temp_dir = TempDir::new().unwrap();
        let prompt_loader = Arc::new(PromptLoader::new(temp_dir.path(), false));
        let protocol_discovery = Arc::new(MockProtocolDiscovery::new());
        
        let resolver: HybridIntentResolver<MockGeminiClient> = HybridIntentResolver::new(
            None,
            prompt_loader,
            protocol_discovery,
            cache,
            IntentStrategy::LocalOnly,
            0.7,
        );
        
        let user_context = UserContext::default();
        let intent = resolver.resolve("swap 100 USDC for ETH", &user_context).await.unwrap();
        
        assert_eq!(intent.category, IntentCategory::Swap);
    }
    
    #[test]
    fn test_complexity_assessment() {
        let cache = Arc::new(IntentCache::new(100, 60));
        let temp_dir = TempDir::new().unwrap();
        let prompt_loader = Arc::new(PromptLoader::new(temp_dir.path(), false));
        let protocol_discovery = Arc::new(MockProtocolDiscovery::new());
        
        let resolver: HybridIntentResolver<MockGeminiClient> = HybridIntentResolver::new(
            None,
            prompt_loader,
            protocol_discovery,
            cache,
            IntentStrategy::Smart,
            0.7,
        );
        
        assert_eq!(resolver.assess_query_complexity("swap USDC for ETH"), 0);
        assert_eq!(resolver.assess_query_complexity("swap USDC for ETH with 0.5% slippage"), 1);
        assert!(resolver.assess_query_complexity(
            "if gas price is below 30 gwei, swap 100 USDC for ETH and then stake the ETH"
        ) > 3);
    }
}