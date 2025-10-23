pub mod classifier;
pub mod patterns;
pub mod registry;
pub mod resolver;
pub mod prompt;
pub mod gemini;
pub mod cache;
pub mod discovery;
pub mod hybrid_resolver;
pub mod protocol_normalizer;

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Intent {
    pub raw_text: String,
    pub category: IntentCategory,
    pub confidence: f64,
    pub parameters: HashMap<String, String>,
    pub suggested_protocols: Vec<ProtocolSuggestion>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum IntentCategory {
    Swap,
    Lend,
    Borrow,
    Stake,
    ProvideLiquidity,
    RemoveLiquidity,
    Bridge,
    Approve,
    Transfer,
    Query,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolSuggestion {
    pub protocol_name: String,
    pub protocol_address: Option<String>,
    pub function_name: String,
    pub confidence: f64,
    pub gas_estimate: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IntentPattern {
    pub category: IntentCategory,
    pub keywords: Vec<String>,
    pub required_parameters: Vec<String>,
    pub optional_parameters: Vec<String>,
    pub common_protocols: Vec<String>,
}

impl IntentCategory {
    pub fn from_string(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "swap" | "exchange" | "trade" => Self::Swap,
            "lend" | "supply" | "deposit" => Self::Lend,
            "borrow" | "loan" => Self::Borrow,
            "stake" | "delegate" => Self::Stake,
            "provide liquidity" | "add liquidity" => Self::ProvideLiquidity,
            "remove liquidity" | "withdraw liquidity" => Self::RemoveLiquidity,
            "bridge" | "cross-chain" => Self::Bridge,
            "approve" | "allow" => Self::Approve,
            "transfer" | "send" => Self::Transfer,
            "query" | "check" | "view" => Self::Query,
            _ => Self::Unknown,
        }
    }
    
    pub fn as_string(&self) -> String {
        match self {
            Self::Swap => "swap",
            Self::Lend => "lend",
            Self::Borrow => "borrow",
            Self::Stake => "stake",
            Self::ProvideLiquidity => "provide_liquidity",
            Self::RemoveLiquidity => "remove_liquidity",
            Self::Bridge => "bridge",
            Self::Approve => "approve",
            Self::Transfer => "transfer",
            Self::Query => "query",
            Self::Unknown => "unknown",
        }.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_intent_category_from_string() {
        assert_eq!(IntentCategory::from_string("swap"), IntentCategory::Swap);
        assert_eq!(IntentCategory::from_string("EXCHANGE"), IntentCategory::Swap);
        assert_eq!(IntentCategory::from_string("lend"), IntentCategory::Lend);
        assert_eq!(IntentCategory::from_string("unknown_action"), IntentCategory::Unknown);
    }

    #[test]
    fn test_intent_category_as_string() {
        assert_eq!(IntentCategory::Swap.as_string(), "swap");
        assert_eq!(IntentCategory::ProvideLiquidity.as_string(), "provide_liquidity");
    }
}