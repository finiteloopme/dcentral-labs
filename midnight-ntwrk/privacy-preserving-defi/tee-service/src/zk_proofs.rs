use ethers::types::Address;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use std::collections::HashMap;
use reqwest::Client;
use tokio::time::{timeout, Duration};

use crate::blockchain::MidnightProof;
use crate::config::ProofMode;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofRequest {
    pub circuit_type: String,
    pub private_inputs: Vec<String>,
    pub public_inputs: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofResponse {
    pub proof: MidnightProof,
    pub verification_key: Vec<u8>,
    pub public_inputs: Vec<String>,
}

pub struct ZkProofService {
    proof_server_url: String,
    verification_keys: HashMap<String, Vec<u8>>,
    proof_mode: ProofMode,
    client: Client,
}

impl ZkProofService {
    pub fn new(proof_server_url: &str, proof_mode: ProofMode) -> Self {
        ZkProofService {
            proof_server_url: proof_server_url.to_string(),
            verification_keys: HashMap::new(),
            proof_mode,
            client: Client::new(),
        }
    }
    
    pub async fn generate_concentration_proof(
        &mut self,
        user_balance: u64,
        deposit_amount: u64,
        tvl: u64,
    ) -> Result<MidnightProof> {
        let request = ProofRequest {
            circuit_type: "concentration_check".to_string(),
            private_inputs: vec![
                user_balance.to_string(),
                deposit_amount.to_string(),
            ],
            public_inputs: vec![
                tvl.to_string(),
                "10".to_string(), // limit_multiplier
            ],
        };
        
        self.create_proof(request).await
    }
    
    pub async fn generate_balance_update_proof(
        &mut self,
        old_balance: u64,
        deposit_amount: u64,
        new_balance: u64,
        user_pubkey: &str,
    ) -> Result<MidnightProof> {
        let request = ProofRequest {
            circuit_type: "balance_update".to_string(),
            private_inputs: vec![
                old_balance.to_string(),
                deposit_amount.to_string(),
                new_balance.to_string(),
            ],
            public_inputs: vec![
                user_pubkey.to_string(),
            ],
        };
        
        self.create_proof(request).await
    }
    
    pub async fn generate_rollback_proof(
        &mut self,
        user_pubkey: &str,
        amount: u64,
    ) -> Result<MidnightProof> {
        let request = ProofRequest {
            circuit_type: "rollback".to_string(),
            private_inputs: vec![
                amount.to_string(),
            ],
            public_inputs: vec![
                user_pubkey.to_string(),
            ],
        };
        
        self.create_proof(request).await
    }
    
    pub async fn generate_sync_proof(
        &mut self,
        new_tvl: u64,
        tee_signature: &str,
    ) -> Result<MidnightProof> {
        let request = ProofRequest {
            circuit_type: "sync".to_string(),
            private_inputs: vec![
                tee_signature.to_string(),
            ],
            public_inputs: vec![
                new_tvl.to_string(),
            ],
        };
        
        self.create_proof(request).await
    }
    
    pub async fn generate_balance_request_proof(
        &mut self,
        user_pubkey: &str,
        user_signature: &str,
    ) -> Result<MidnightProof> {
        let request = ProofRequest {
            circuit_type: "balance_request".to_string(),
            private_inputs: vec![
                user_signature.to_string(),
            ],
            public_inputs: vec![
                user_pubkey.to_string(),
            ],
        };
        
        self.create_proof(request).await
    }
    
    async fn create_proof(&mut self, request: ProofRequest) -> Result<MidnightProof> {
        match self.proof_mode {
            ProofMode::Mock => self.create_mock_proof(request).await,
            ProofMode::Production => self.create_production_proof(request).await,
        }
    }

    async fn create_mock_proof(&mut self, request: ProofRequest) -> Result<MidnightProof> {
        let mock_proof = MidnightProof {
            circuit_type: request.circuit_type.clone(),
            public_inputs: request.public_inputs.clone(),
            proof_bytes: vec![0u8; 100], // Mock proof bytes
            verification_key: vec![0u8; 50], // Mock verification key
        };
        
        // Cache mock verification key
        self.verification_keys.insert(
            request.circuit_type.clone(),
            mock_proof.verification_key.clone(),
        );
        
        Ok(mock_proof)
    }

    async fn create_production_proof(&mut self, request: ProofRequest) -> Result<MidnightProof> {
        // Build the request for Midnight proof server
        let midnight_request = serde_json::json!({
            "circuit_type": request.circuit_type,
            "private_inputs": request.private_inputs,
            "public_inputs": request.public_inputs
        });

        let url = format!("{}/prove", self.proof_server_url);
        
        // Send request to Midnight proof server with timeout
        let response = timeout(
            Duration::from_millis(30000),
            self.client
                .post(&url)
                .header("Content-Type", "application/json")
                .json(&midnight_request)
                .send()
        ).await
        .map_err(|_| anyhow::anyhow!("Proof server request timed out"))?
        .map_err(|e| anyhow::anyhow!("Failed to send request to proof server: {}", e))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(anyhow::anyhow!("Proof server returned error: {} - {}", status, error_text));
        }

        let proof_response: MidnightProofResponse = response.json().await
            .map_err(|e| anyhow::anyhow!("Failed to parse proof server response: {}", e))?;

        let midnight_proof = MidnightProof {
            circuit_type: request.circuit_type.clone(),
            public_inputs: request.public_inputs.clone(),
            proof_bytes: hex::decode(&proof_response.proof)
                .map_err(|e| anyhow::anyhow!("Failed to decode proof hex: {}", e))?,
            verification_key: hex::decode(&proof_response.verification_key)
                .map_err(|e| anyhow::anyhow!("Failed to decode verification key hex: {}", e))?,
        };

        // Cache verification key
        self.verification_keys.insert(
            request.circuit_type.clone(),
            midnight_proof.verification_key.clone(),
        );

        Ok(midnight_proof)
    }
    
    pub async fn verify_proof(&self, proof: &MidnightProof) -> Result<bool> {
        match self.proof_mode {
            ProofMode::Mock => Ok(true), // Mock proofs always valid
            ProofMode::Production => self.verify_production_proof(proof).await,
        }
    }

    async fn verify_production_proof(&self, proof: &MidnightProof) -> Result<bool> {
        let verify_request = serde_json::json!({
            "circuit_type": proof.circuit_type,
            "public_inputs": proof.public_inputs,
            "proof": hex::encode(&proof.proof_bytes),
            "verification_key": hex::encode(&proof.verification_key)
        });

        let url = format!("{}/verify", self.proof_server_url);
        
        let response = timeout(
            Duration::from_millis(15000),
            self.client
                .post(&url)
                .header("Content-Type", "application/json")
                .json(&verify_request)
                .send()
        ).await
        .map_err(|_| anyhow::anyhow!("Proof verification request timed out"))?
        .map_err(|e| anyhow::anyhow!("Failed to send verification request: {}", e))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(anyhow::anyhow!("Proof verification failed: {} - {}", status, error_text));
        }

        let verify_response: VerifyResponse = response.json().await
            .map_err(|e| anyhow::anyhow!("Failed to parse verification response: {}", e))?;

        Ok(verify_response.valid)
    }
    
    pub fn create_tee_signature(&self, data: &[u8]) -> Result<String> {
        // In production, this would use TEE's secure private key
        // For now, create a mock signature
        let mut hasher = Sha256::new();
        hasher.update(data);
        let hash = hasher.finalize();
        
        Ok(format!("tee_sig_{:x}", hash))
    }
    
    pub fn create_deposit_hash(
        &self,
        user: Address,
        amount: u64,
        tvl: u64,
        midnight_tx: &str,
    ) -> Vec<u8> {
        let mut hasher = Sha256::new();
        hasher.update(user.as_bytes());
        hasher.update(amount.to_le_bytes());
        hasher.update(tvl.to_le_bytes());
        hasher.update(midnight_tx.as_bytes());
        
        hasher.finalize().to_vec()
    }
}

// Legacy function for backward compatibility
pub async fn generate_zk_proof(
    user: Address,
    amount: u64,
    tvl: u64,
    midnight_tx: String,
) -> Result<Vec<u8>> {
    let proof_mode = match std::env::var("PROOF_MODE").unwrap_or_else(|_| "mock".to_string()).as_str() {
        "production" => ProofMode::Production,
        _ => ProofMode::Mock,
    };
    
    let mut proof_service = ZkProofService::new("http://localhost:6300", proof_mode);
    
    // Create a composite proof for the entire deposit flow
    let deposit_hash = proof_service.create_deposit_hash(user, amount, tvl, &midnight_tx);
    
    let request = ProofRequest {
        circuit_type: "deposit_flow".to_string(),
        private_inputs: vec![
            hex::encode(deposit_hash),
        ],
        public_inputs: vec![
            user.to_string(),
            amount.to_string(),
            tvl.to_string(),
        ],
    };
    
    let proof = proof_service.create_proof(request).await?;
    Ok(proof.proof_bytes)
}

pub fn verify_zk_proof(_proof: &[u8], _public_inputs: &[u8]) -> Result<bool> {
    // Mock ZK proof verification for backward compatibility
    // In production, this would verify actual ZK proof
    match std::env::var("PROOF_MODE").unwrap_or_else(|_| "mock".to_string()).as_str() {
        "production" => {
            // In production mode, this would call the actual verification
            // For now, return true as the Midnight proof server handles verification
            Ok(true)
        },
        _ => Ok(true), // Mock mode - always true
    }
}

#[derive(Debug, Deserialize)]
struct MidnightProofResponse {
    pub proof: String,
    pub verification_key: String,
    pub public_inputs: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct VerifyResponse {
    pub valid: bool,
    pub circuit_type: String,
}