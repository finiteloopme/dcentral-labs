use super::{Intent, IntentCategory};
use super::classifier::IntentClassifier;
use super::patterns::PatternMatcher;
use super::registry::{Protocol, ProtocolRegistry};
use anyhow::Result;
use std::collections::HashMap;

#[derive(Clone)]
pub struct IntentResolver {
    classifier: IntentClassifier,
    pattern_matcher: PatternMatcher,
    registry: ProtocolRegistry,
}

impl IntentResolver {
    pub fn new() -> Self {
        Self {
            classifier: IntentClassifier::new(),
            pattern_matcher: PatternMatcher::new(),
            registry: ProtocolRegistry::new(),
        }
    }
    
    pub fn resolve(&self, text: &str) -> Result<ResolvedIntent> {
        // Step 1: Classify the intent
        let mut intent = self.classifier.classify(text)?;
        
        // Step 2: Refine with pattern matching
        let (refined_category, pattern_confidence) = self.pattern_matcher.find_best_category(text);
        if pattern_confidence > intent.confidence {
            intent.category = refined_category;
            intent.confidence = pattern_confidence;
        }
        
        // Step 3: Find matching protocols
        let protocols = self.registry.find_protocols_for_category(&intent.category);
        
        // Step 4: Generate contract calls
        let mut contract_calls = Vec::new();
        for protocol in protocols {
            if let Some(call) = self.generate_contract_call(protocol, &intent) {
                contract_calls.push(call);
            }
        }
        
        // Step 5: Rank and filter suggestions
        contract_calls.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap());
        contract_calls.truncate(5); // Keep top 5 suggestions
        
        Ok(ResolvedIntent {
            original_text: text.to_string(),
            category: intent.category,
            confidence: intent.confidence,
            parameters: intent.parameters,
            contract_calls,
        })
    }
    
    fn generate_contract_call(&self, protocol: &Protocol, intent: &Intent) -> Option<ContractCall> {
        // Find the best matching function for this intent
        let matching_functions: Vec<_> = protocol.functions
            .iter()
            .filter(|f| f.category == intent.category)
            .collect();
        
        if matching_functions.is_empty() {
            return None;
        }
        
        // For now, just use the first matching function
        let function = matching_functions[0];
        
        // Map intent parameters to function parameters
        let mut call_parameters = HashMap::new();
        
        // Basic parameter mapping (this would be more sophisticated in production)
        match intent.category {
            IntentCategory::Swap => {
                // Map swap parameters
                if let Some(amount) = intent.parameters.get("amount_usdc")
                    .or_else(|| intent.parameters.get("amount_eth"))
                    .or_else(|| intent.parameters.get("amount_dai")) {
                    call_parameters.insert("amountIn".to_string(), amount.clone());
                }
                call_parameters.insert("tokenIn".to_string(), 
                    intent.parameters.get("token_0").cloned().unwrap_or_else(|| "USDC".to_string()));
                call_parameters.insert("tokenOut".to_string(), 
                    intent.parameters.get("token_1").cloned().unwrap_or_else(|| "ETH".to_string()));
                call_parameters.insert("slippage".to_string(), 
                    intent.parameters.get("slippage").cloned().unwrap_or_else(|| "0.5".to_string()));
            },
            IntentCategory::Lend => {
                // Map lending parameters
                if let Some(amount) = intent.parameters.values().find(|v| v.parse::<f64>().is_ok()) {
                    call_parameters.insert("amount".to_string(), amount.clone());
                }
                call_parameters.insert("asset".to_string(), 
                    intent.parameters.get("token_0").cloned().unwrap_or_else(|| "USDC".to_string()));
            },
            IntentCategory::Stake => {
                // Map staking parameters
                if let Some(amount) = intent.parameters.values().find(|v| v.parse::<f64>().is_ok()) {
                    call_parameters.insert("amount".to_string(), amount.clone());
                }
            },
            _ => {}
        }
        
        Some(ContractCall {
            protocol_name: protocol.name.clone(),
            contract_address: protocol.address.clone(),
            function_name: function.name.clone(),
            function_signature: function.signature.clone(),
            parameters: call_parameters,
            estimated_gas: function.gas_estimate,
            confidence: self.calculate_call_confidence(intent, protocol),
        })
    }
    
    fn calculate_call_confidence(&self, intent: &Intent, protocol: &Protocol) -> f64 {
        let mut confidence = intent.confidence;
        
        // Boost confidence for verified protocols
        if protocol.verified {
            confidence *= 1.1;
        }
        
        // Boost confidence if protocol name is mentioned in the text
        if intent.raw_text.to_lowercase().contains(&protocol.name.to_lowercase()) {
            confidence *= 1.2;
        }
        
        // Cap at 1.0
        confidence.min(1.0_f64)
    }
}

#[derive(Debug, Clone)]
pub struct ResolvedIntent {
    pub original_text: String,
    pub category: IntentCategory,
    pub confidence: f64,
    pub parameters: HashMap<String, String>,
    pub contract_calls: Vec<ContractCall>,
}

#[derive(Debug, Clone)]
pub struct ContractCall {
    pub protocol_name: String,
    pub contract_address: String,
    pub function_name: String,
    pub function_signature: String,
    pub parameters: HashMap<String, String>,
    pub estimated_gas: Option<u64>,
    pub confidence: f64,
}

impl Default for IntentResolver {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resolve_swap_intent() {
        let resolver = IntentResolver::new();
        let result = resolver.resolve("I want to swap 100 USDC for ETH").unwrap();
        
        assert_eq!(result.category, IntentCategory::Swap);
        assert!(!result.contract_calls.is_empty());
        
        let call = &result.contract_calls[0];
        assert!(call.protocol_name.contains("Uniswap"));
        assert!(call.parameters.contains_key("amountIn"));
    }

    #[test]
    fn test_resolve_lend_intent() {
        let resolver = IntentResolver::new();
        let result = resolver.resolve("I want to lend 1000 DAI on Aave").unwrap();
        
        assert_eq!(result.category, IntentCategory::Lend);
        assert!(!result.contract_calls.is_empty());
        
        // Should prioritize Aave since it's mentioned
        let aave_call = result.contract_calls.iter()
            .find(|c| c.protocol_name.contains("Aave"));
        assert!(aave_call.is_some());
    }

    #[test]
    fn test_resolve_stake_intent() {
        let resolver = IntentResolver::new();
        let result = resolver.resolve("stake 5 ETH").unwrap();
        
        assert_eq!(result.category, IntentCategory::Stake);
        assert!(!result.contract_calls.is_empty());
        
        let call = &result.contract_calls[0];
        assert_eq!(call.protocol_name, "Lido");
        assert_eq!(call.function_name, "submit");
    }

    #[test]
    fn test_confidence_calculation() {
        let resolver = IntentResolver::new();
        
        // Test with specific protocol mention
        let result1 = resolver.resolve("swap on Uniswap").unwrap();
        let result2 = resolver.resolve("swap tokens").unwrap();
        
        // Should have higher confidence when protocol is mentioned
        let uniswap_confidence1 = result1.contract_calls.iter()
            .find(|c| c.protocol_name.contains("Uniswap"))
            .map(|c| c.confidence)
            .unwrap_or(0.0);
            
        let uniswap_confidence2 = result2.contract_calls.iter()
            .find(|c| c.protocol_name.contains("Uniswap"))
            .map(|c| c.confidence)
            .unwrap_or(0.0);
            
        assert!(uniswap_confidence1 > uniswap_confidence2);
    }
}