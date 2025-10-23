pub mod client;
pub mod resolver;

use serde::{Deserialize, Serialize};
use anyhow::Result;

/// Response from Gemini API
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GeminiResponse {
    pub intent_type: String,
    pub confidence: f64,
    pub parameters: IntentParameters,
    pub preferences: IntentPreferences,
    pub multi_step: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reasoning: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct IntentParameters {
    pub tokens_involved: Vec<String>,
    pub amounts: Vec<String>,
    pub constraints: serde_json::Map<String, serde_json::Value>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct IntentPreferences {
    pub mentioned_protocols: Vec<String>,
    pub optimization_goal: String,
}

/// Trait for Gemini API integration
#[async_trait::async_trait]
pub trait GeminiApi {
    async fn generate(&self, prompt: &str, config: &GeminiApiConfig) -> Result<String>;
}

#[derive(Debug, Clone)]
pub struct GeminiApiConfig {
    pub model: String,
    pub temperature: f32,
    pub max_output_tokens: u32,
    pub response_format: ResponseFormat,
}

#[derive(Debug, Clone)]
pub enum ResponseFormat {
    Json,
    Text,
}

impl Default for GeminiApiConfig {
    fn default() -> Self {
        Self {
            model: "gemini-pro".to_string(),
            temperature: 0.1,
            max_output_tokens: 2048,
            response_format: ResponseFormat::Json,
        }
    }
}