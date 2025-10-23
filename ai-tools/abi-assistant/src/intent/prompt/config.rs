use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Configuration for prompt management system
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct PromptSystemConfig {
    pub prompts_dir: PathBuf,
    pub examples_dir: PathBuf,
    pub templates_dir: PathBuf,
    pub hot_reload: bool,
    pub include_examples: bool,
    pub max_examples_per_category: usize,
    pub cache_prompts: bool,
}

impl Default for PromptSystemConfig {
    fn default() -> Self {
        Self {
            prompts_dir: PathBuf::from("./prompts"),
            examples_dir: PathBuf::from("./prompts/examples"),
            templates_dir: PathBuf::from("./prompts/templates"),
            hot_reload: false,
            include_examples: true,
            max_examples_per_category: 2,
            cache_prompts: true,
        }
    }
}

/// Configuration for intent resolution strategy
#[derive(Debug, Clone, Copy, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum IntentStrategy {
    GeminiOnly,
    LocalOnly,
    GeminiFirst,
    LocalFirst,
    Smart,
}

impl Default for IntentStrategy {
    fn default() -> Self {
        Self::GeminiFirst
    }
}

/// Configuration for the Gemini integration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GeminiConfig {
    pub enabled: bool,
    pub api_key: String,
    pub model: String,
    pub timeout: u64,
    pub max_retries: u32,
    pub prompt_file: String,
}

impl Default for GeminiConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            api_key: String::new(),
            model: "gemini-pro".to_string(),
            timeout: 5000,
            max_retries: 2,
            prompt_file: "prompts/gemini/intent_classifier.yaml".to_string(),
        }
    }
}