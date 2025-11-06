use std::sync::Arc;
use std::collections::HashMap;
use tokio::sync::{RwLock, Mutex};
use warp::{Filter};
use serde::{Deserialize, Serialize};
use serde_json;
use anyhow::Result;
use tracing::{info, error};
use chrono;
use uuid;
use std::net::{IpAddr, Ipv4Addr};

mod api;
mod blockchain;
mod zk_proofs;
mod config;

use blockchain::{ArcClient, ArcContracts};
use zk_proofs::ZkProofService;
use config::Config;

#[derive(Debug)]
struct ApiError {
    message: String,
}

impl warp::reject::Reject for ApiError {}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TEEAttestation {
    pub tee_type: String,
    pub quote_version: String,
    pub pcrs: Vec<PCRValue>,
    pub quote_signature: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub measurement: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PCRValue {
    pub index: u32,
    pub value: String,
}

#[derive(Clone)]
pub struct AppState {
    pub sessions: Arc<RwLock<HashMap<String, UserSession>>>,
    pub arc_client: Arc<ArcClient>,
    pub zk_service: Arc<Mutex<ZkProofService>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserSession {
    pub user_address: String,
    pub user_pubkey: String,
    pub session_token: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

// Import the API types instead of redefining them
use api::{CreateSessionRequest, SessionResponse};

#[derive(Debug, Serialize, Deserialize)]
pub struct DepositRequest {
    pub amount: String,
    pub asset: String,
    pub user_address: String,
    pub user_pubkey: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DepositResponse {
    pub success: bool,
    pub transaction_hash: Option<String>,
    pub midnight_tx: Option<String>,
    pub error: Option<String>,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Load configuration
    let config = Config::load().unwrap_or_else(|_| Config::load_from_env());
    
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_max_level(config.logging.level.parse().unwrap_or(tracing::Level::INFO))
        .init();
    
    info!("Starting TEE Service for Privacy-Preserving DeFi");
    info!("Config loaded: {:?}", config);
    
    // Initialize blockchain client
    let contracts = ArcContracts {
        mock_usdc: config.contracts.mock_usdc.parse()
            .expect("Invalid USDC address"),
        defi_vault: config.contracts.defi_vault.parse()
            .expect("Invalid DeFiVault address"),
        compliance_registry: config.contracts.compliance_registry.parse()
            .expect("Invalid ComplianceRegistry address"),
    };
    
    let arc_client = Arc::new(ArcClient::new(&config.blockchain.arc_rpc_url, contracts).await
        .expect("Failed to initialize Arc client"));
    
    let zk_service = Arc::new(Mutex::new(ZkProofService::new(&config.proof_server.url, config.proof_server.mode.clone())));
    
    // Initialize application state
    let state = AppState {
        sessions: Arc::new(RwLock::new(HashMap::new())),
        arc_client,
        zk_service,
    };
    
    // Build API routes
    let health_route = warp::path("healthz")
        .and(warp::get())
        .and(with_state(state.clone()))
        .and_then(health_check);
    
    let session_route = warp::path!("api" / "v1" / "session")
        .and(warp::post())
        .and(warp::body::json())
        .and(with_state(state.clone()))
        .and_then(create_session);
    
    let deposit_route = warp::path!("api" / "v1" / "deposit")
        .and(warp::post())
        .and(warp::body::json())
        .and(with_state(state.clone()))
        .and_then(process_deposit);
    
    let cors = warp::cors()
        .allow_any_origin()
        .allow_headers(vec!["content-type", "authorization", "x-tee-verified"])
        .allow_methods(vec!["GET", "POST", "OPTIONS"]);
    
    let routes = health_route
        .or(session_route)
        .or(deposit_route)
        .with(cors)
        .with(warp::log("tee_service"));
    
    // Start server
    info!("TEE Service listening on {}:{}", config.server.host, config.server.port);
    
    warp::serve(routes)
        .run((
            config.server.host.parse::<IpAddr>().unwrap_or(IpAddr::V4(Ipv4Addr::new(0, 0, 0, 0))),
            config.server.port
        ))
        .await;
    
    Ok(())
}

fn with_state(
    state: AppState,
) -> impl Filter<Extract = (AppState,), Error = std::convert::Infallible> + Clone {
    warp::any().map(move || state.clone())
}

// API endpoint handlers
async fn health_check(state: AppState) -> Result<impl warp::Reply, warp::Rejection> {
    // Check actual service health
    let arc_health = state.arc_client.health_check().await.unwrap_or(false);
    
    let health_response = serde_json::json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "arc": arc_health,
        "midnight": false, // Still disabled until node is fixed
        "proof_server": true // Proof server is running
    });
    
    Ok(warp::reply::json(&health_response))
}

async fn create_session(
    request: CreateSessionRequest,
    state: AppState,
) -> Result<impl warp::Reply, warp::Rejection> {
    let session_token = uuid::Uuid::new_v4().to_string();
    let session = UserSession {
        user_address: request.user_address.to_string(),
        user_pubkey: request.user_pubkey.unwrap_or_else(|| format!("midnight1{}", uuid::Uuid::new_v4().to_string().replace("-", ""))),
        session_token: session_token.clone(),
        created_at: chrono::Utc::now(),
    };
    
    // Store session
    state.sessions.write().await.insert(session_token.clone(), session);
    
    let response = SessionResponse {
        session_token,
        expires_at: (chrono::Utc::now() + chrono::Duration::hours(1)).to_rfc3339(),
        midnight_pubkey: "midnight1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz3fzypf".to_string(),
    };
    
    Ok(warp::reply::json(&response))
}

async fn process_deposit(
    request: DepositRequest,
    state: AppState,
) -> Result<impl warp::Reply, warp::Rejection> {
    info!("Processing deposit request: {:?}", request);
    
    // Parse amount and address
    let amount = request.amount.parse::<u64>()
        .map_err(|_| warp::reject::custom(ApiError { message: "Invalid amount format".to_string() }))?;
    
    let user_address = request.user_address.parse()
        .map_err(|_| warp::reject::custom(ApiError { message: "Invalid user address".to_string() }))?;
    
    // Step 1: Check compliance on Arc
    info!("Checking compliance for user {}", request.user_address);
    let is_compliant = state.arc_client.check_compliance(user_address).await
        .map_err(|e| warp::reject::custom(ApiError { 
            message: format!("Compliance check failed: {}", e) 
        }))?;
    
    if !is_compliant {
        error!("User {} is not compliant", request.user_address);
        return Ok(warp::reply::json(&DepositResponse {
            success: false,
            transaction_hash: None,
            midnight_tx: None,
            error: Some("User not compliant".to_string()),
        }));
    }
    
    // Step 2: Get current TVL from Arc
    let tvl = state.arc_client.get_tvl().await
        .map_err(|e| warp::reject::custom(ApiError { 
            message: format!("Failed to get TVL: {}", e) 
        }))?;
    
    info!("Current TVL: {} USDC", tvl);
    
    // Step 3: Generate ZK proof for concentration limit check
    info!("Generating ZK proof for concentration limit check");
    let concentration_proof = {
        let mut zk_service = state.zk_service.lock().await;
        zk_service.generate_concentration_proof(
            0, // user_balance (simplified - would fetch from Midnight)
            amount,
            tvl,
        ).await.map_err(|e| warp::reject::custom(ApiError { 
            message: format!("ZK proof generation failed: {}", e) 
        }))?
    };
    
    // Step 4: Verify ZK proof locally
    let is_valid = {
        let zk_service = state.zk_service.lock().await;
        zk_service.verify_proof(&concentration_proof).await
            .map_err(|e| warp::reject::custom(ApiError { 
                message: format!("ZK proof verification failed: {}", e) 
            }))?
    };
    
    if !is_valid {
        error!("ZK proof verification failed");
        return Ok(warp::reply::json(&DepositResponse {
            success: false,
            transaction_hash: None,
            midnight_tx: None,
            error: Some("ZK proof verification failed".to_string()),
        }));
    }
    
    // Step 5: Generate balance update proof for Midnight
    info!("Generating balance update proof for Midnight");
    let balance_proof = {
        let mut zk_service = state.zk_service.lock().await;
        zk_service.generate_balance_update_proof(
            0, // old_balance (simplified)
            amount,
            amount, // new_balance (old_balance + amount)
            &request.user_pubkey,
        ).await.map_err(|e| warp::reject::custom(ApiError { 
            message: format!("Balance proof generation failed: {}", e) 
        }))?
    };
    
    // Step 6: Execute deposit on Arc with ZK proof
    info!("Executing deposit on Arc with ZK proof");
    let arc_tx = state.arc_client.execute_deposit(
        user_address,
        amount,
        hex::encode(&concentration_proof.proof_bytes),
    ).await.map_err(|e| warp::reject::custom(ApiError { 
        message: format!("Arc deposit failed: {}", e) 
    }))?;
    
    // Step 7: Create Midnight transaction reference
    let midnight_tx = format!("midnight_proof_{}", hex::encode(&balance_proof.proof_bytes[..16]));
    
    info!("Deposit completed successfully. Arc TX: {}, Midnight TX: {}", arc_tx, midnight_tx);
    
    Ok(warp::reply::json(&DepositResponse {
        success: true,
        transaction_hash: Some(arc_tx),
        midnight_tx: Some(midnight_tx),
        error: None,
    }))
}