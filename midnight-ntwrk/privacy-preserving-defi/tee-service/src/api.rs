use serde::{Deserialize, Serialize};
use ethers::types::Address;

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateSessionRequest {
    pub user_address: Address,
    pub user_pubkey: Option<String>, // Midnight public key
    pub signature: String, // User signature for authentication
    pub verify_attestation: Option<bool>, // Request TEE attestation verification
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SessionResponse {
    pub session_token: String,
    pub expires_at: String,
    pub midnight_pubkey: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub timestamp: String,
    pub midnight: Option<bool>,
    pub arc: Option<bool>,
    pub proof_server: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BalanceRequest {
    pub user_address: Address,
    pub user_pubkey: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BalanceResponse {
    pub encrypted_balance: String,
    pub proof: String,
}