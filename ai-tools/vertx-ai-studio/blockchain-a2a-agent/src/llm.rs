use anyhow::{Context, Result};
use gcp_auth::TokenProvider;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::sync::Arc;

// ---------------------------------------------------------------------------
// Network enum
// ---------------------------------------------------------------------------

/// Blockchain networks the agent can query.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Network {
    Bitcoin,
    Ethereum,
    Solana,
}

// ---------------------------------------------------------------------------
// Gemini client
// ---------------------------------------------------------------------------

/// Thin wrapper around the Vertex AI Gemini generateContent endpoint.
pub struct GeminiClient {
    http: reqwest::Client,
    auth: Arc<dyn TokenProvider>,
    project: String,
    location: String,
    model: String,
}

impl GeminiClient {
    /// Create a new client.
    ///
    /// Returns `None` if `GOOGLE_CLOUD_PROJECT` is not set (graceful
    /// degradation — the agent will fall back to keyword routing).
    pub async fn try_new(http: reqwest::Client) -> Option<Self> {
        let project = std::env::var("GOOGLE_CLOUD_PROJECT").ok()?;
        let location =
            std::env::var("VERTEX_LOCATION").unwrap_or_else(|_| "us-central1".into());
        let model =
            std::env::var("GEMINI_MODEL").unwrap_or_else(|_| "gemini-3.0-flash".into());

        let auth = gcp_auth::provider()
            .await
            .map_err(|e| eprintln!("gcp_auth init failed: {e}"))
            .ok()?;

        Some(Self { http, auth, project, location, model })
    }

    /// Call Gemini `generateContent` and return the text of the first
    /// candidate part.
    async fn generate(&self, system: &str, user_msg: &str) -> Result<String> {
        let scopes = &["https://www.googleapis.com/auth/cloud-platform"];
        let token = self.auth.token(scopes).await.context("failed to get ADC token")?;

        let url = format!(
            "https://{loc}-aiplatform.googleapis.com/v1/projects/{proj}/locations/{loc}/publishers/google/models/{model}:generateContent",
            loc = self.location,
            proj = self.project,
            model = self.model,
        );

        let body = json!({
            "systemInstruction": {
                "parts": [{ "text": system }]
            },
            "contents": [{
                "role": "user",
                "parts": [{ "text": user_msg }]
            }],
            "generationConfig": {
                "temperature": 0.0,
                "responseMimeType": "application/json"
            }
        });

        let resp = self
            .http
            .post(&url)
            .bearer_auth(token.as_str())
            .json(&body)
            .send()
            .await
            .context("Vertex AI request failed")?;

        let status = resp.status();
        let resp_body: serde_json::Value =
            resp.json().await.context("failed to parse Vertex AI response")?;

        if !status.is_success() {
            anyhow::bail!("Vertex AI returned {status}: {resp_body}");
        }

        let text = resp_body["candidates"][0]["content"]["parts"][0]["text"]
            .as_str()
            .context("unexpected Vertex AI response shape")?
            .to_string();

        Ok(text)
    }
}

// ---------------------------------------------------------------------------
// LLM-powered routing
// ---------------------------------------------------------------------------

const SYSTEM_PROMPT: &str = r#"You are a blockchain network classifier. Given a user message, determine which blockchain network(s) the user is asking about.

Return a JSON object with a single key "networks" whose value is an array of one or more of: "bitcoin", "ethereum", "solana".

Rules:
- If the user mentions Bitcoin, BTC, or bitcoin-related terms, include "bitcoin".
- If the user mentions Ethereum, ETH, or ethereum-related terms, include "ethereum".
- If the user mentions Solana, SOL, or solana-related terms, include "solana".
- If the user asks about multiple networks, include all relevant ones.
- If the user asks a general question about blockchains or block heights without specifying a network, return all three: ["bitcoin", "ethereum", "solana"].
- Always return valid JSON. Never include explanation text.

Examples:
  "What is the current Bitcoin block height?" -> {"networks": ["bitcoin"]}
  "Show me ETH and SOL data" -> {"networks": ["ethereum", "solana"]}
  "What are the latest block heights?" -> {"networks": ["bitcoin", "ethereum", "solana"]}
"#;

/// Parsed response from the LLM classifier.
#[derive(Deserialize)]
struct ClassifyResponse {
    networks: Vec<Network>,
}

/// Use Gemini to classify which network(s) the user is asking about.
///
/// Falls back to [`keyword_route`] on any error.
pub async fn route_message(gemini: &GeminiClient, message: &str) -> Vec<Network> {
    match gemini.generate(SYSTEM_PROMPT, message).await {
        Ok(text) => match serde_json::from_str::<ClassifyResponse>(&text) {
            Ok(parsed) if !parsed.networks.is_empty() => parsed.networks,
            Ok(_) => {
                eprintln!("LLM returned empty networks array, falling back to keywords");
                keyword_route(message)
            }
            Err(e) => {
                eprintln!("failed to parse LLM response ({e}), falling back to keywords");
                keyword_route(message)
            }
        },
        Err(e) => {
            eprintln!("LLM call failed ({e}), falling back to keywords");
            keyword_route(message)
        }
    }
}

// ---------------------------------------------------------------------------
// Keyword-based fallback
// ---------------------------------------------------------------------------

/// Simple keyword-based routing. Returns all three networks if no keywords
/// match.
pub fn keyword_route(message: &str) -> Vec<Network> {
    let lower = message.to_lowercase();
    let mut nets = Vec::new();

    if lower.contains("btc") || lower.contains("bitcoin") {
        nets.push(Network::Bitcoin);
    }
    if lower.contains("eth") || lower.contains("ethereum") {
        nets.push(Network::Ethereum);
    }
    if lower.contains("sol") || lower.contains("solana") {
        nets.push(Network::Solana);
    }

    if nets.is_empty() {
        vec![Network::Bitcoin, Network::Ethereum, Network::Solana]
    } else {
        nets
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keyword_bitcoin() {
        assert_eq!(keyword_route("What is the BTC block height?"), vec![Network::Bitcoin]);
        assert_eq!(keyword_route("bitcoin price"), vec![Network::Bitcoin]);
    }

    #[test]
    fn keyword_ethereum() {
        assert_eq!(keyword_route("latest ETH block"), vec![Network::Ethereum]);
        assert_eq!(keyword_route("ethereum gas"), vec![Network::Ethereum]);
    }

    #[test]
    fn keyword_solana() {
        assert_eq!(keyword_route("SOL slot number"), vec![Network::Solana]);
        assert_eq!(keyword_route("solana tps"), vec![Network::Solana]);
    }

    #[test]
    fn keyword_multi() {
        let nets = keyword_route("compare btc and eth");
        assert!(nets.contains(&Network::Bitcoin));
        assert!(nets.contains(&Network::Ethereum));
        assert!(!nets.contains(&Network::Solana));
    }

    #[test]
    fn keyword_fallback_all() {
        let nets = keyword_route("what are the latest block heights?");
        assert_eq!(nets.len(), 3);
    }
}
