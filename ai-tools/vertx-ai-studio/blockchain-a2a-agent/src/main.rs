mod blockchain;
mod llm;

use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::{net::SocketAddr, sync::Arc};

use blockchain::NetworkResponse;
use llm::Network;

// ---------------------------------------------------------------------------
// Shared application state
// ---------------------------------------------------------------------------

struct AppState {
    http_client: reqwest::Client,
    gemini: Option<llm::GeminiClient>,
}

// ---------------------------------------------------------------------------
// A2A types
// ---------------------------------------------------------------------------

#[derive(Serialize)]
struct AgentCard {
    name: String,
    description: String,
    url: String,
    skills: Vec<Skill>,
}

#[derive(Serialize)]
struct Skill {
    id: String,
    description: String,
}

#[derive(Deserialize)]
struct A2ARequest {
    id: String,
    params: MessageParams,
}

#[derive(Deserialize)]
struct MessageParams {
    message: serde_json::Value,
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build a standard A2A JSON-RPC success response.
fn a2a_response(id: &str, text: &str) -> serde_json::Value {
    json!({
        "jsonrpc": "2.0",
        "id": id,
        "result": {
            "message": {
                "role": "assistant",
                "parts": [{ "text": text }]
            }
        }
    })
}

/// Format a list of [`NetworkResponse`] into a human-readable string.
fn format_results(results: &[NetworkResponse]) -> String {
    if results.is_empty() {
        return "No blockchain data available at this time.".into();
    }
    results
        .iter()
        .map(|r| r.to_string())
        .collect::<Vec<_>>()
        .join("\n")
}

/// Extract the user's text from an A2A message value.
///
/// Walks `message.parts` looking for the first object with a `"text"` key.
fn extract_text(message: &serde_json::Value) -> String {
    if let Some(parts) = message.get("parts").and_then(|p| p.as_array()) {
        for part in parts {
            if let Some(t) = part.get("text").and_then(|t| t.as_str()) {
                return t.to_string();
            }
        }
    }
    String::new()
}

/// Fetch data for the given set of networks in parallel.
async fn fetch_networks(
    client: &reqwest::Client,
    networks: &[Network],
) -> Vec<NetworkResponse> {
    let mut results = Vec::with_capacity(networks.len());

    // Build futures for each requested network.
    let mut btc_fut = None;
    let mut eth_fut = None;
    let mut sol_fut = None;

    for net in networks {
        match net {
            Network::Bitcoin => btc_fut = Some(blockchain::fetch_bitcoin(client)),
            Network::Ethereum => eth_fut = Some(blockchain::fetch_ethereum(client)),
            Network::Solana => sol_fut = Some(blockchain::fetch_solana(client)),
        }
    }

    // Await all requested futures concurrently.
    let (btc_res, eth_res, sol_res) = tokio::join!(
        async { match btc_fut { Some(f) => Some(f.await), None => None } },
        async { match eth_fut { Some(f) => Some(f.await), None => None } },
        async { match sol_fut { Some(f) => Some(f.await), None => None } },
    );

    if let Some(Ok(r)) = btc_res { results.push(r); }
    if let Some(Ok(r)) = eth_res { results.push(r); }
    if let Some(Ok(r)) = sol_res { results.push(r); }

    results
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

/// `GET /.well-known/agent.json` — A2A discovery endpoint.
async fn discovery() -> Json<AgentCard> {
    Json(AgentCard {
        name: "Blockchain-Explorer-Agent".into(),
        description: "Live block data for BTC, ETH, and SOL with AI-powered smart routing".into(),
        url: std::env::var("AGENT_URL").unwrap_or_else(|_| "http://0.0.0.0:8080".into()),
        skills: vec![
            Skill {
                id: "bitcoin_info".into(),
                description: "Get current Bitcoin block height".into(),
            },
            Skill {
                id: "ethereum_info".into(),
                description: "Get current Ethereum block number".into(),
            },
            Skill {
                id: "solana_info".into(),
                description: "Get current Solana slot number".into(),
            },
            Skill {
                id: "smart_route".into(),
                description: "AI-powered routing: describe what blockchain data you need in natural language".into(),
            },
        ],
    })
}

/// `POST /v1/bitcoin` — Direct Bitcoin query.
async fn handle_bitcoin(
    State(state): State<Arc<AppState>>,
    Json(req): Json<A2ARequest>,
) -> Json<serde_json::Value> {
    let result = blockchain::fetch_bitcoin(&state.http_client).await;
    let text = match result {
        Ok(r) => r.to_string(),
        Err(e) => format!("Error fetching Bitcoin data: {e}"),
    };
    Json(a2a_response(&req.id, &text))
}

/// `POST /v1/ethereum` — Direct Ethereum query.
async fn handle_ethereum(
    State(state): State<Arc<AppState>>,
    Json(req): Json<A2ARequest>,
) -> Json<serde_json::Value> {
    let result = blockchain::fetch_ethereum(&state.http_client).await;
    let text = match result {
        Ok(r) => r.to_string(),
        Err(e) => format!("Error fetching Ethereum data: {e}"),
    };
    Json(a2a_response(&req.id, &text))
}

/// `POST /v1/solana` — Direct Solana query.
async fn handle_solana(
    State(state): State<Arc<AppState>>,
    Json(req): Json<A2ARequest>,
) -> Json<serde_json::Value> {
    let result = blockchain::fetch_solana(&state.http_client).await;
    let text = match result {
        Ok(r) => r.to_string(),
        Err(e) => format!("Error fetching Solana data: {e}"),
    };
    Json(a2a_response(&req.id, &text))
}

/// `POST /v1/messages` — Smart routing endpoint.
///
/// Uses Gemini LLM to classify the user's message and route to the
/// appropriate blockchain fetcher(s). Falls back to keyword matching
/// when Gemini is unavailable.
async fn handle_message(
    State(state): State<Arc<AppState>>,
    Json(req): Json<A2ARequest>,
) -> Json<serde_json::Value> {
    let user_text = extract_text(&req.params.message);

    // Route: LLM if available, otherwise keyword fallback.
    let networks = match &state.gemini {
        Some(gemini) => llm::route_message(gemini, &user_text).await,
        None => llm::keyword_route(&user_text),
    };

    let results = fetch_networks(&state.http_client, &networks).await;
    let text = format_results(&results);

    Json(a2a_response(&req.id, &text))
}

// ---------------------------------------------------------------------------
// Entrypoint
// ---------------------------------------------------------------------------

#[tokio::main]
async fn main() {
    // Explicitly install the aws-lc-rs CryptoProvider to avoid a panic when
    // both `aws-lc-rs` and `ring` features are enabled on rustls 0.23+ via
    // transitive dependencies (reqwest → aws-lc-rs, gcp_auth → ring).
    rustls::crypto::aws_lc_rs::default_provider()
        .install_default()
        .expect("Failed to install default CryptoProvider");

    let http_client = reqwest::Client::new();
    let gemini = llm::GeminiClient::try_new(http_client.clone()).await;

    if gemini.is_some() {
        println!("LLM routing: ENABLED (Gemini via Vertex AI)");
    } else {
        println!("LLM routing: DISABLED (keyword fallback only — set GOOGLE_CLOUD_PROJECT to enable)");
    }

    let state = Arc::new(AppState { http_client, gemini });

    let app = Router::new()
        .route("/.well-known/agent.json", get(discovery))
        .route("/v1/bitcoin", post(handle_bitcoin))
        .route("/v1/ethereum", post(handle_ethereum))
        .route("/v1/solana", post(handle_solana))
        .route("/v1/messages", post(handle_message))
        .with_state(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("Agent online at {addr}");
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
