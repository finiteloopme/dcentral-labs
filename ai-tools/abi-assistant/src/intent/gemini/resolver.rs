use super::{GeminiApi, GeminiApiConfig, GeminiResponse};
use crate::intent::{Intent, IntentCategory, ProtocolSuggestion};
use crate::intent::prompt::{loader::PromptLoader, template::ContextBuilder};
use crate::intent::discovery::ProtocolDiscovery;
use anyhow::{Result, Context};
use std::collections::HashMap;
use std::sync::Arc;

/// Resolves intents using Gemini AI
pub struct GeminiResolver<G: GeminiApi> {
    client: Arc<G>,
    prompt_loader: Arc<PromptLoader>,
    protocol_discovery: Arc<dyn ProtocolDiscovery>,
}

impl<G: GeminiApi> GeminiResolver<G> {
    pub fn new(
        client: Arc<G>,
        prompt_loader: Arc<PromptLoader>,
        protocol_discovery: Arc<dyn ProtocolDiscovery>,
    ) -> Self {
        Self {
            client,
            prompt_loader,
            protocol_discovery,
        }
    }
    
    pub async fn resolve(&self, query: &str, user_context: &UserContext) -> Result<Intent> {
        // Load the intent classification prompt
        let prompt_config = self.prompt_loader
            .load_prompt("gemini/intent_classifier")
            .context("Failed to load intent classifier prompt")?;
        
        // Build context for template variables
        let context = self.build_context(user_context).await?;
        
        // Build the full prompt with context
        let system_prompt = self.prompt_loader
            .build_prompt_with_context(&prompt_config, &context);
        
        // Add the user query
        let full_prompt = format!(
            "{}\n\nUser Request: {}\n\nProvide your response in JSON format.",
            system_prompt, query
        );
        
        // Configure Gemini API call
        let api_config = GeminiApiConfig {
            model: prompt_config.model,
            temperature: prompt_config.temperature,
            response_format: super::ResponseFormat::Json,
            ..Default::default()
        };
        
        // Call Gemini
        let response_text = self.client
            .generate(&full_prompt, &api_config)
            .await
            .context("Failed to get response from Gemini")?;
        
        // Parse the response
        let gemini_response: GeminiResponse = serde_json::from_str(&response_text)
            .context("Failed to parse Gemini response as JSON")?;
        
        // Convert to our Intent structure
        self.convert_to_intent(gemini_response, query).await
    }
    
    async fn build_context(&self, user_context: &UserContext) -> Result<HashMap<String, String>> {
        // Discover available protocols dynamically
        let protocols = self.protocol_discovery
            .list_available_protocols()
            .await?;
        
        let protocol_names: Vec<String> = protocols
            .iter()
            .map(|p| p.name.clone())
            .collect();
        
        let context = ContextBuilder::new()
            .with_chain_id(user_context.chain_id)
            .with_user_address(&user_context.user_address)
            .with_gas_price(user_context.gas_price)
            .with_protocols(&protocol_names)
            .build();
        
        Ok(context)
    }
    
    async fn convert_to_intent(&self, response: GeminiResponse, original_query: &str) -> Result<Intent> {
        // Convert string intent type to enum
        let category = match response.intent_type.as_str() {
            "swap" => IntentCategory::Swap,
            "lend" => IntentCategory::Lend,
            "borrow" => IntentCategory::Borrow,
            "stake" => IntentCategory::Stake,
            "provide_liquidity" => IntentCategory::ProvideLiquidity,
            "remove_liquidity" => IntentCategory::RemoveLiquidity,
            "bridge" => IntentCategory::Bridge,
            "approve" => IntentCategory::Approve,
            "transfer" => IntentCategory::Transfer,
            "query" => IntentCategory::Query,
            _ => IntentCategory::Unknown,
        };
        
        // Convert parameters to HashMap
        let mut parameters = HashMap::new();
        for (i, token) in response.parameters.tokens_involved.iter().enumerate() {
            parameters.insert(format!("token_{}", i), token.clone());
        }
        for (i, amount) in response.parameters.amounts.iter().enumerate() {
            parameters.insert(format!("amount_{}", i), amount.clone());
        }
        for (key, value) in response.parameters.constraints {
            parameters.insert(key, value.to_string());
        }
        
        // Get protocol suggestions based on the intent
        let suggested_protocols = self.get_protocol_suggestions(
            &category,
            &response.preferences.mentioned_protocols
        ).await?;
        
        Ok(Intent {
            raw_text: original_query.to_string(),
            category,
            confidence: response.confidence,
            parameters,
            suggested_protocols,
        })
    }
    
    async fn get_protocol_suggestions(
        &self,
        category: &IntentCategory,
        mentioned_protocols: &[String]
    ) -> Result<Vec<ProtocolSuggestion>> {
        // Get capable protocols from discovery
        let capable_protocols = self.protocol_discovery
            .find_capable_protocols(category)
            .await?;
        
        let mut suggestions = Vec::new();
        
        for protocol in capable_protocols {
            // Boost confidence if protocol was mentioned by user
            let base_confidence = 0.7_f64;
            let confidence = if mentioned_protocols.contains(&protocol.name) {
                (base_confidence * 1.2).min(1.0_f64)
            } else {
                base_confidence
            };
            
            suggestions.push(ProtocolSuggestion {
                protocol_name: protocol.name,
                protocol_address: protocol.address,
                function_name: protocol.suggested_function,
                confidence,
                gas_estimate: protocol.gas_estimate,
            });
        }
        
        // Sort by confidence
        suggestions.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap());
        
        Ok(suggestions)
    }
}

/// Context about the user's request
#[derive(Debug, Clone)]
pub struct UserContext {
    pub chain_id: u32,
    pub user_address: String,
    pub gas_price: u64,
}

impl Default for UserContext {
    fn default() -> Self {
        Self {
            chain_id: 1,
            user_address: "0x0000000000000000000000000000000000000000".to_string(),
            gas_price: 30_000_000_000,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::intent::gemini::client::MockGeminiClient;
    use crate::intent::discovery::MockProtocolDiscovery;
    use tempfile::TempDir;
    use std::fs;
    
    #[tokio::test]
    async fn test_gemini_resolver() {
        // Setup test prompt directory
        let temp_dir = TempDir::new().unwrap();
        let prompts_dir = temp_dir.path().join("prompts/gemini");
        fs::create_dir_all(&prompts_dir).unwrap();
        
        let test_prompt = r#"
version: "1.0"
model: "test-model"
temperature: 0.1
system_prompt: "Test system prompt"
task_description: "Test task"
categories:
  - name: swap
    description: "Swap tokens"
    required_params: ["token_in", "token_out"]
    optional_params: ["slippage"]
"#;
        
        fs::write(prompts_dir.join("intent_classifier.yaml"), test_prompt).unwrap();
        
        // Create mock Gemini client
        let mock_response = r#"{
            "intent_type": "swap",
            "confidence": 0.95,
            "parameters": {
                "tokens_involved": ["USDC", "ETH"],
                "amounts": ["100"],
                "constraints": {}
            },
            "preferences": {
                "mentioned_protocols": [],
                "optimization_goal": "best_price"
            },
            "multi_step": false
        }"#;
        
        let gemini_client = Arc::new(MockGeminiClient::new(vec![mock_response.to_string()]));
        let prompt_loader = Arc::new(PromptLoader::new(temp_dir.path().join("prompts"), false));
        let protocol_discovery = Arc::new(MockProtocolDiscovery::new());
        
        let resolver = GeminiResolver::new(gemini_client, prompt_loader, protocol_discovery);
        
        let user_context = UserContext::default();
        let intent = resolver.resolve("swap 100 USDC for ETH", &user_context).await.unwrap();
        
        assert_eq!(intent.category, IntentCategory::Swap);
        assert_eq!(intent.confidence, 0.95);
        assert_eq!(intent.parameters.get("token_0"), Some(&"USDC".to_string()));
        assert_eq!(intent.parameters.get("token_1"), Some(&"ETH".to_string()));
    }
}