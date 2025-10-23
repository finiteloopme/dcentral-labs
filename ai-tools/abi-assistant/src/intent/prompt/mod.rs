pub mod loader;
pub mod template;
pub mod config;

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Represents a prompt configuration loaded from YAML
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct PromptConfig {
    pub version: String,
    pub model: String,
    pub temperature: f32,
    pub system_prompt: String,
    pub task_description: String,
    pub categories: Vec<CategoryDefinition>,
    #[serde(default)]
    pub context_injection: HashMap<String, String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CategoryDefinition {
    pub name: String,
    pub description: String,
    pub required_params: Vec<String>,
    pub optional_params: Vec<String>,
}

/// Represents the format expected in responses
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ResponseFormat {
    pub intent_type: String,
    pub confidence: f64,
    pub parameters: ParameterSet,
    pub preferences: Preferences,
    pub multi_step: bool,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ParameterSet {
    pub tokens_involved: Vec<String>,
    pub amounts: Vec<String>,
    pub constraints: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Preferences {
    pub mentioned_protocols: Vec<String>,
    pub optimization_goal: OptimizationGoal,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OptimizationGoal {
    BestPrice,
    LowestGas,
    Fastest,
    MostSecure,
    HighestYield,
}