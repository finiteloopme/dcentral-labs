use super::{Intent, IntentCategory, IntentPattern, ProtocolSuggestion};
use anyhow::Result;
use std::collections::HashMap;

#[derive(Clone)]
pub struct IntentClassifier {
    patterns: Vec<IntentPattern>,
}

impl IntentClassifier {
    pub fn new() -> Self {
        Self {
            patterns: Self::default_patterns(),
        }
    }

    pub fn classify(&self, text: &str) -> Result<Intent> {
        let normalized_text = text.to_lowercase();
        let tokens: Vec<&str> = normalized_text.split_whitespace().collect();
        
        let mut best_match: Option<(IntentCategory, f64)> = None;
        
        // Score each pattern
        for pattern in &self.patterns {
            let score = self.score_pattern(&tokens, pattern);
            if score > 0.0 {
                if best_match.is_none() || score > best_match.as_ref().unwrap().1 {
                    best_match = Some((pattern.category.clone(), score));
                }
            }
        }
        
        // Extract parameters from text
        let parameters = self.extract_parameters(&normalized_text);
        
        let (category, confidence) = best_match.unwrap_or((IntentCategory::Unknown, 0.0));
        
        // Get protocol suggestions based on category
        let suggested_protocols = self.suggest_protocols(&category, &parameters);
        
        Ok(Intent {
            raw_text: text.to_string(),
            category,
            confidence,
            parameters,
            suggested_protocols,
        })
    }
    
    fn score_pattern(&self, tokens: &[&str], pattern: &IntentPattern) -> f64 {
        let mut matches = 0;
        let total_keywords = pattern.keywords.len();
        
        for keyword in &pattern.keywords {
            for token in tokens {
                // Exact match or keyword is a substring of token
                if token == keyword || (keyword.len() >= 3 && token.contains(keyword.as_str())) {
                    matches += 1;
                    break;
                }
            }
        }
        
        if total_keywords == 0 {
            return 0.0;
        }
        
        matches as f64 / total_keywords as f64
    }
    
    fn extract_parameters(&self, text: &str) -> HashMap<String, String> {
        let mut params = HashMap::new();
        
        // Extract amounts (numbers followed by token symbols)
        let amount_regex = regex::Regex::new(r"(\d+(?:\.\d+)?)\s*([a-zA-Z]{2,6})").unwrap();
        for cap in amount_regex.captures_iter(text) {
            if let (Some(amount), Some(token)) = (cap.get(1), cap.get(2)) {
                params.insert(format!("amount_{}", token.as_str().to_lowercase()), amount.as_str().to_string());
                params.insert(format!("token_{}", params.len()), token.as_str().to_string());
            }
        }
        
        // Extract addresses (0x...)
        let addr_regex = regex::Regex::new(r"0x[a-fA-F0-9]{40}").unwrap();
        let mut addr_count = 0;
        for cap in addr_regex.find_iter(text) {
            params.insert(format!("address_{}", addr_count), cap.as_str().to_string());
            addr_count += 1;
        }
        
        // Extract common DeFi terms
        if text.contains("slippage") {
            let slippage_regex = regex::Regex::new(r"(\d+(?:\.\d+)?)\s*%").unwrap();
            if let Some(cap) = slippage_regex.captures(text) {
                if let Some(slippage) = cap.get(1) {
                    params.insert("slippage".to_string(), slippage.as_str().to_string());
                }
            }
        }
        
        params
    }
    
    fn suggest_protocols(&self, category: &IntentCategory, _params: &HashMap<String, String>) -> Vec<ProtocolSuggestion> {
        let mut suggestions = Vec::new();
        
        match category {
            IntentCategory::Swap => {
                suggestions.push(ProtocolSuggestion {
                    protocol_name: "Uniswap V3".to_string(),
                    protocol_address: Some("0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45".to_string()),
                    function_name: "exactInputSingle".to_string(),
                    confidence: 0.9,
                    gas_estimate: Some(150000),
                });
                suggestions.push(ProtocolSuggestion {
                    protocol_name: "Uniswap V2".to_string(),
                    protocol_address: Some("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D".to_string()),
                    function_name: "swapExactTokensForTokens".to_string(),
                    confidence: 0.8,
                    gas_estimate: Some(120000),
                });
            },
            IntentCategory::Lend => {
                suggestions.push(ProtocolSuggestion {
                    protocol_name: "Aave V3".to_string(),
                    protocol_address: Some("0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2".to_string()),
                    function_name: "supply".to_string(),
                    confidence: 0.9,
                    gas_estimate: Some(200000),
                });
                suggestions.push(ProtocolSuggestion {
                    protocol_name: "Compound V3".to_string(),
                    protocol_address: Some("0xc3d688B66703497DAA19211EEdff47f25384cdc3".to_string()),
                    function_name: "supply".to_string(),
                    confidence: 0.85,
                    gas_estimate: Some(180000),
                });
            },
            IntentCategory::Stake => {
                suggestions.push(ProtocolSuggestion {
                    protocol_name: "Lido".to_string(),
                    protocol_address: Some("0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84".to_string()),
                    function_name: "submit".to_string(),
                    confidence: 0.9,
                    gas_estimate: Some(100000),
                });
            },
            _ => {}
        }
        
        suggestions
    }
    
    fn default_patterns() -> Vec<IntentPattern> {
        vec![
            IntentPattern {
                category: IntentCategory::Swap,
                keywords: vec!["swap".to_string(), "exchange".to_string(), "trade".to_string(), "convert".to_string(), "for".to_string()],
                required_parameters: vec!["token_in".to_string(), "token_out".to_string(), "amount".to_string()],
                optional_parameters: vec!["slippage".to_string(), "deadline".to_string()],
                common_protocols: vec!["Uniswap".to_string(), "Sushiswap".to_string(), "Curve".to_string()],
            },
            IntentPattern {
                category: IntentCategory::Lend,
                keywords: vec!["lend".to_string(), "supply".to_string(), "deposit".to_string(), "earn".to_string(), "yield".to_string()],
                required_parameters: vec!["token".to_string(), "amount".to_string()],
                optional_parameters: vec!["apy".to_string(), "duration".to_string()],
                common_protocols: vec!["Aave".to_string(), "Compound".to_string(), "Morpho".to_string()],
            },
            IntentPattern {
                category: IntentCategory::Borrow,
                keywords: vec!["borrow".to_string(), "loan".to_string(), "leverage".to_string(), "debt".to_string()],
                required_parameters: vec!["token".to_string(), "amount".to_string()],
                optional_parameters: vec!["collateral".to_string(), "ltv".to_string()],
                common_protocols: vec!["Aave".to_string(), "Compound".to_string(), "MakerDAO".to_string()],
            },
            IntentPattern {
                category: IntentCategory::Stake,
                keywords: vec!["stake".to_string(), "delegate".to_string(), "lock".to_string(), "validator".to_string()],
                required_parameters: vec!["token".to_string(), "amount".to_string()],
                optional_parameters: vec!["duration".to_string(), "validator".to_string()],
                common_protocols: vec!["Lido".to_string(), "RocketPool".to_string()],
            },
            IntentPattern {
                category: IntentCategory::ProvideLiquidity,
                keywords: vec!["provide".to_string(), "liquidity".to_string(), "add".to_string(), "pool".to_string(), "lp".to_string()],
                required_parameters: vec!["token0".to_string(), "token1".to_string(), "amount0".to_string(), "amount1".to_string()],
                optional_parameters: vec!["range".to_string(), "fee_tier".to_string()],
                common_protocols: vec!["Uniswap".to_string(), "Balancer".to_string(), "Curve".to_string()],
            },
            IntentPattern {
                category: IntentCategory::Transfer,
                keywords: vec!["send".to_string(), "transfer".to_string(), "move".to_string(), "pay".to_string()],
                required_parameters: vec!["token".to_string(), "amount".to_string(), "recipient".to_string()],
                optional_parameters: vec!["memo".to_string()],
                common_protocols: vec!["ERC20".to_string()],
            },
            IntentPattern {
                category: IntentCategory::Approve,
                keywords: vec!["approve".to_string(), "allow".to_string(), "permit".to_string(), "authorize".to_string()],
                required_parameters: vec!["token".to_string(), "spender".to_string()],
                optional_parameters: vec!["amount".to_string()],
                common_protocols: vec!["ERC20".to_string()],
            },
            IntentPattern {
                category: IntentCategory::Query,
                keywords: vec!["check".to_string(), "balance".to_string(), "view".to_string(), "show".to_string(), "query".to_string()],
                required_parameters: vec![],
                optional_parameters: vec!["address".to_string(), "token".to_string()],
                common_protocols: vec![],
            },
        ]
    }
}

impl Default for IntentClassifier {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_classify_swap_intent() {
        let classifier = IntentClassifier::new();
        let intent = classifier.classify("I want to swap 100 USDC for ETH").unwrap();
        
        assert_eq!(intent.category, IntentCategory::Swap);
        assert!(intent.confidence > 0.0, "Confidence: {}", intent.confidence);
        assert!(!intent.suggested_protocols.is_empty());
    }

    #[test]
    fn test_classify_lend_intent() {
        let classifier = IntentClassifier::new();
        let intent = classifier.classify("deposit 1000 DAI to earn yield").unwrap();
        
        assert_eq!(intent.category, IntentCategory::Lend);
        assert!(intent.confidence > 0.5);
    }

    #[test]
    fn test_extract_parameters() {
        let classifier = IntentClassifier::new();
        let params = classifier.extract_parameters("swap 100 usdc for eth with 0.5% slippage");
        
        assert!(params.contains_key("amount_usdc"));
        assert_eq!(params.get("amount_usdc"), Some(&"100".to_string()));
        assert!(params.contains_key("slippage"));
        assert_eq!(params.get("slippage"), Some(&"0.5".to_string()));
    }

    #[test]
    fn test_extract_address() {
        let classifier = IntentClassifier::new();
        let params = classifier.extract_parameters("send to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0");
        
        assert!(params.contains_key("address_0"));
        assert_eq!(params.get("address_0"), Some(&"0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0".to_string()));
    }
}