use super::{GeminiApi, GeminiApiConfig, ResponseFormat};
use anyhow::{Result, Context};
use serde::{Deserialize, Serialize};
use std::time::Duration;

/// Gemini API client implementation
pub struct GeminiClient {
    api_key: String,
    base_url: String,
    client: reqwest::Client,
}

impl GeminiClient {
    pub fn new(api_key: String) -> Result<Self> {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(30))
            .build()?;
            
        Ok(Self {
            api_key,
            base_url: "https://generativelanguage.googleapis.com/v1beta".to_string(),
            client,
        })
    }
    
    pub fn with_base_url(mut self, base_url: String) -> Self {
        self.base_url = base_url;
        self
    }
}

#[async_trait::async_trait]
impl GeminiApi for GeminiClient {
    async fn generate(&self, prompt: &str, config: &GeminiApiConfig) -> Result<String> {
        let url = format!(
            "{}/models/{}:generateContent?key={}",
            self.base_url, config.model, self.api_key
        );
        
        let request_body = GeminiRequest {
            contents: vec![
                Content {
                    parts: vec![
                        Part {
                            text: prompt.to_string(),
                        }
                    ],
                }
            ],
            generation_config: GenerationConfig {
                temperature: config.temperature,
                max_output_tokens: config.max_output_tokens,
                response_mime_type: match config.response_format {
                    ResponseFormat::Json => Some("application/json".to_string()),
                    ResponseFormat::Text => None,
                },
            },
        };
        
        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .context("Failed to send request to Gemini API")?;
            
        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();
            anyhow::bail!("Gemini API error ({}): {}", status, error_text);
        }
        
        let gemini_response: GeminiApiResponse = response
            .json()
            .await
            .context("Failed to parse Gemini API response")?;
            
        gemini_response
            .candidates
            .first()
            .and_then(|c| c.content.parts.first())
            .map(|p| p.text.clone())
            .ok_or_else(|| anyhow::anyhow!("No content in Gemini response"))
    }
}

#[derive(Debug, Serialize)]
struct GeminiRequest {
    contents: Vec<Content>,
    generation_config: GenerationConfig,
}

#[derive(Debug, Serialize)]
struct Content {
    parts: Vec<Part>,
}

#[derive(Debug, Serialize)]
struct Part {
    text: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct GenerationConfig {
    temperature: f32,
    max_output_tokens: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    response_mime_type: Option<String>,
}

#[derive(Debug, Deserialize)]
struct GeminiApiResponse {
    candidates: Vec<Candidate>,
}

#[derive(Debug, Deserialize)]
struct Candidate {
    content: ResponseContent,
}

#[derive(Debug, Deserialize)]
struct ResponseContent {
    parts: Vec<ResponsePart>,
}

#[derive(Debug, Deserialize)]
struct ResponsePart {
    text: String,
}

/// Mock client for testing
pub struct MockGeminiClient {
    responses: Vec<String>,
    call_count: std::sync::atomic::AtomicUsize,
}

impl MockGeminiClient {
    pub fn new(responses: Vec<String>) -> Self {
        Self {
            responses,
            call_count: std::sync::atomic::AtomicUsize::new(0),
        }
    }
}

#[async_trait::async_trait]
impl GeminiApi for MockGeminiClient {
    async fn generate(&self, _prompt: &str, _config: &GeminiApiConfig) -> Result<String> {
        let index = self.call_count.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
        self.responses
            .get(index)
            .cloned()
            .ok_or_else(|| anyhow::anyhow!("No more mock responses"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_mock_client() {
        let mock = MockGeminiClient::new(vec![
            r#"{"intent_type": "swap", "confidence": 0.9}"#.to_string(),
        ]);
        
        let config = GeminiApiConfig::default();
        let result = mock.generate("test prompt", &config).await.unwrap();
        
        assert!(result.contains("swap"));
        assert!(result.contains("0.9"));
    }
}