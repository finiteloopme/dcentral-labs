use super::{IntentCategory, IntentPattern};
use std::collections::HashMap;

#[derive(Clone)]
pub struct PatternMatcher {
    patterns: HashMap<IntentCategory, Vec<IntentPattern>>,
    synonyms: HashMap<String, Vec<String>>,
}

impl PatternMatcher {
    pub fn new() -> Self {
        let mut matcher = Self {
            patterns: HashMap::new(),
            synonyms: Self::default_synonyms(),
        };
        matcher.load_patterns();
        matcher
    }
    
    pub fn match_pattern(&self, text: &str, category: &IntentCategory) -> Option<f64> {
        let normalized = self.normalize_text(text);
        let tokens: Vec<&str> = normalized.split_whitespace().collect();
        
        if let Some(patterns) = self.patterns.get(category) {
            let mut best_score = 0.0;
            
            for pattern in patterns {
                let score = self.calculate_pattern_score(&tokens, pattern);
                if score > best_score {
                    best_score = score;
                }
            }
            
            if best_score > 0.0 {
                return Some(best_score);
            }
        }
        
        None
    }
    
    pub fn find_best_category(&self, text: &str) -> (IntentCategory, f64) {
        let mut best_category = IntentCategory::Unknown;
        let mut best_score = 0.0;
        
        for category in self.patterns.keys() {
            if let Some(score) = self.match_pattern(text, category) {
                if score > best_score {
                    best_score = score;
                    best_category = category.clone();
                }
            }
        }
        
        (best_category, best_score)
    }
    
    fn normalize_text(&self, text: &str) -> String {
        let mut normalized = text.to_lowercase();
        
        // Replace synonyms with canonical forms
        for (canonical, synonyms) in &self.synonyms {
            for synonym in synonyms {
                normalized = normalized.replace(synonym, canonical);
            }
        }
        
        normalized
    }
    
    fn calculate_pattern_score(&self, tokens: &[&str], pattern: &IntentPattern) -> f64 {
        let mut keyword_matches = 0;
        let mut position_bonus = 0.0;
        
        for (i, token) in tokens.iter().enumerate() {
            for keyword in &pattern.keywords {
                // Only match if token equals keyword or contains it (for longer keywords)
                if *token == keyword || (keyword.len() >= 3 && token.contains(keyword.as_str())) {
                    keyword_matches += 1;
                    // Give bonus for keywords appearing early in the text
                    position_bonus += 1.0 / (i + 1) as f64;
                    break; // Don't count the same token multiple times
                }
            }
        }
        
        if pattern.keywords.is_empty() {
            return 0.0;
        }
        
        let keyword_score = keyword_matches as f64 / pattern.keywords.len() as f64;
        let position_score = position_bonus / pattern.keywords.len() as f64;
        
        // Weighted average: 70% keyword match, 30% position
        keyword_score * 0.7 + position_score * 0.3
    }
    
    fn load_patterns(&mut self) {
        // Swap patterns
        self.patterns.insert(
            IntentCategory::Swap,
            vec![
                IntentPattern {
                    category: IntentCategory::Swap,
                    keywords: vec!["swap".to_string(), "for".to_string()],
                    required_parameters: vec!["amount".to_string(), "token_in".to_string(), "token_out".to_string()],
                    optional_parameters: vec!["slippage".to_string()],
                    common_protocols: vec!["Uniswap".to_string()],
                },
                IntentPattern {
                    category: IntentCategory::Swap,
                    keywords: vec!["exchange".to_string(), "to".to_string()],
                    required_parameters: vec!["amount".to_string(), "token_in".to_string(), "token_out".to_string()],
                    optional_parameters: vec!["slippage".to_string()],
                    common_protocols: vec!["Sushiswap".to_string()],
                },
                IntentPattern {
                    category: IntentCategory::Swap,
                    keywords: vec!["trade".to_string(), "for".to_string()],
                    required_parameters: vec!["amount".to_string(), "token_in".to_string(), "token_out".to_string()],
                    optional_parameters: vec!["slippage".to_string()],
                    common_protocols: vec!["1inch".to_string()],
                },
            ],
        );
        
        // Lending patterns
        self.patterns.insert(
            IntentCategory::Lend,
            vec![
                IntentPattern {
                    category: IntentCategory::Lend,
                    keywords: vec!["lend".to_string()],
                    required_parameters: vec!["amount".to_string(), "token".to_string()],
                    optional_parameters: vec!["apy".to_string()],
                    common_protocols: vec!["Aave".to_string()],
                },
                IntentPattern {
                    category: IntentCategory::Lend,
                    keywords: vec!["supply".to_string()],
                    required_parameters: vec!["amount".to_string(), "token".to_string()],
                    optional_parameters: vec!["protocol".to_string()],
                    common_protocols: vec!["Compound".to_string()],
                },
                IntentPattern {
                    category: IntentCategory::Lend,
                    keywords: vec!["deposit".to_string(), "earn".to_string()],
                    required_parameters: vec!["amount".to_string(), "token".to_string()],
                    optional_parameters: vec!["yield".to_string()],
                    common_protocols: vec!["Yearn".to_string()],
                },
            ],
        );
        
        // Staking patterns
        self.patterns.insert(
            IntentCategory::Stake,
            vec![
                IntentPattern {
                    category: IntentCategory::Stake,
                    keywords: vec!["stake".to_string()],
                    required_parameters: vec!["amount".to_string(), "token".to_string()],
                    optional_parameters: vec!["validator".to_string()],
                    common_protocols: vec!["Lido".to_string()],
                },
                IntentPattern {
                    category: IntentCategory::Stake,
                    keywords: vec!["delegate".to_string(), "to".to_string()],
                    required_parameters: vec!["amount".to_string(), "validator".to_string()],
                    optional_parameters: vec![],
                    common_protocols: vec!["RocketPool".to_string()],
                },
            ],
        );
        
        // Liquidity provision patterns
        self.patterns.insert(
            IntentCategory::ProvideLiquidity,
            vec![
                IntentPattern {
                    category: IntentCategory::ProvideLiquidity,
                    keywords: vec!["provide".to_string(), "liquidity".to_string()],
                    required_parameters: vec!["token0".to_string(), "token1".to_string(), "amount0".to_string(), "amount1".to_string()],
                    optional_parameters: vec!["pool".to_string()],
                    common_protocols: vec!["Uniswap V3".to_string()],
                },
                IntentPattern {
                    category: IntentCategory::ProvideLiquidity,
                    keywords: vec!["add".to_string(), "pool".to_string()],
                    required_parameters: vec!["token0".to_string(), "token1".to_string(), "amount0".to_string(), "amount1".to_string()],
                    optional_parameters: vec!["fee".to_string()],
                    common_protocols: vec!["Balancer".to_string()],
                },
            ],
        );
    }
    
    fn default_synonyms() -> HashMap<String, Vec<String>> {
        let mut synonyms = HashMap::new();
        
        synonyms.insert("swap".to_string(), vec![
            "exchange".to_string(),
            "trade".to_string(),
            "convert".to_string(),
            "switch".to_string(),
        ]);
        
        synonyms.insert("lend".to_string(), vec![
            "supply".to_string(),
            "deposit".to_string(),
            "provide".to_string(),
        ]);
        
        synonyms.insert("eth".to_string(), vec![
            "ether".to_string(),
            "ethereum".to_string(),
        ]);
        
        synonyms.insert("usdc".to_string(), vec![
            "usd coin".to_string(),
            "dollar".to_string(),
        ]);
        
        synonyms
    }
}

impl Default for PatternMatcher {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_match_swap_pattern() {
        let matcher = PatternMatcher::new();
        let score = matcher.match_pattern("I want to swap ETH for USDC", &IntentCategory::Swap);
        
        assert!(score.is_some());
        assert!(score.unwrap() > 0.5);
    }

    #[test]
    fn test_find_best_category() {
        let matcher = PatternMatcher::new();
        
        let (category, score) = matcher.find_best_category("I want to lend 1000 DAI");
        assert_eq!(category, IntentCategory::Lend);
        assert!(score > 0.0);
        
        let (category, score) = matcher.find_best_category("stake my ETH");
        assert_eq!(category, IntentCategory::Stake);
        assert!(score > 0.0);
    }

    #[test]
    fn test_normalize_text() {
        let matcher = PatternMatcher::new();
        let normalized = matcher.normalize_text("I want to EXCHANGE my Ether for USD Coin");
        
        assert!(normalized.contains("swap"));
        assert!(normalized.contains("eth"));
        assert!(normalized.contains("usdc"));
    }
}