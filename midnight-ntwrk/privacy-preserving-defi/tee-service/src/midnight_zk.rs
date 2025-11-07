/**
 * ZK Proof Service using Midnight.js Integration
 * 
 * This replaces the HTTP-based proof generation with proper
 * Midnight.js Compact contract integration.
 */

use ethers::types::Address;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use std::collections::HashMap;
use tokio::time::{timeout, Duration};

use crate::blockchain::MidnightProof;
use crate::config::ProofMode;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MidnightDepositRequest {
    pub user_address: Address,
    pub user_pubkey: String,
    pub amount: u64,
    pub current_tvl: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MidnightProofResult {
    pub proof: Vec<u8>,
    pub public_inputs: Vec<String>,
    pub verification_key: Vec<u8>,
}

pub struct MidnightZkService {
    proof_mode: ProofMode,
    midnight_integration_url: Option<String>,
}

impl MidnightZkService {
    pub fn new(proof_mode: ProofMode, midnight_integration_url: Option<String>) -> Self {
        MidnightZkService {
            proof_mode,
            midnight_integration_url,
        }
    }
    
    pub async fn process_deposit(
        &self,
        request: MidnightDepositRequest,
    ) -> Result<(MidnightProof, MidnightProof)> {
        match self.proof_mode {
            ProofMode::Mock => self.process_deposit_mock(request).await,
            ProofMode::Production => self.process_deposit_production(request).await,
        }
    }

    async fn process_deposit_mock(
        &self,
        request: MidnightDepositRequest,
    ) -> Result<(MidnightProof, MidnightProof)> {
        // Mock concentration proof
        let concentration_proof = MidnightProof {
            circuit_type: "check_concentration_limit".to_string(),
            public_inputs: vec![
                request.user_pubkey.clone(),
                request.amount.to_string(),
                request.current_tvl.to_string(),
            ],
            proof_bytes: vec![0u8; 100],
            verification_key: vec![0u8; 50],
        };

        // Mock balance update proof
        let balance_update_proof = MidnightProof {
            circuit_type: "update_balance".to_string(),
            public_inputs: vec![
                request.user_pubkey,
                request.amount.to_string(),
                (request.current_tvl + request.amount).to_string(),
            ],
            proof_bytes: vec![0u8; 100],
            verification_key: vec![0u8; 50],
        };

        Ok((concentration_proof, balance_update_proof))
    }

    async fn process_deposit_production(
        &self,
        request: MidnightDepositRequest,
    ) -> Result<(MidnightProof, MidnightProof)> {
        let integration_url = self.midnight_integration_url.as_ref()
            .ok_or_else(|| anyhow::anyhow!("Midnight integration URL not configured"))?;

        // Call our new Midnight integration service
        let client = reqwest::Client::new();
        
        let deposit_request = serde_json::json!({
            "userAddress": request.user_address.to_string(),
            "userPubkey": request.user_pubkey,
            "amount": request.amount,
            "currentTvl": request.current_tvl,
        });

        let url = format!("{}/process-deposit", integration_url);
        
        let response = timeout(
            Duration::from_millis(45000), // Longer timeout for complex proof generation
            client
                .post(&url)
                .header("Content-Type", "application/json")
                .json(&deposit_request)
                .send()
        ).await
        .map_err(|_| anyhow::anyhow!("Midnight integration request timed out"))?
        .map_err(|e| anyhow::anyhow!("Failed to send request to Midnight integration: {}", e))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(anyhow::anyhow!("Midnight integration failed: {} - {}", status, error_text));
        }

        let result: MidnightDepositResponse = response.json().await
            .map_err(|e| anyhow::anyhow!("Failed to parse Midnight integration response: {}", e))?;

        // Convert response to our internal format
        let concentration_proof = MidnightProof {
            circuit_type: "check_concentration_limit".to_string(),
            public_inputs: result.concentration_proof.public_inputs,
            proof_bytes: result.concentration_proof.proof,
            verification_key: result.concentration_proof.verification_key,
        };

        let balance_update_proof = MidnightProof {
            circuit_type: "update_balance".to_string(),
            public_inputs: result.balance_update_proof.public_inputs,
            proof_bytes: result.balance_update_proof.proof,
            verification_key: result.balance_update_proof.verification_key,
        };

        Ok((concentration_proof, balance_update_proof))
    }

        let result: MidnightDepositResponse = response.json().await
            .map_err(|e| anyhow::anyhow!("Failed to parse Midnight integration response: {}", e))?;

        // Convert the response to our internal format
        let concentration_proof = MidnightProof {
            circuit_type: "check_concentration_limit".to_string(),
            public_inputs: result.concentration_proof.public_inputs,
            proof_bytes: result.concentration_proof.proof,
            verification_key: result.concentration_proof.verification_key,
        };

        let balance_update_proof = MidnightProof {
            circuit_type: "update_balance".to_string(),
            public_inputs: result.balance_update_proof.public_inputs,
            proof_bytes: result.balance_update_proof.proof,
            verification_key: result.balance_update_proof.verification_key,
        };

        Ok((concentration_proof, balance_update_proof))
    }

    pub async fn update_tvl_mirror(
        &self,
        new_tvl: u64,
        tee_signature: &str,
    ) -> Result<MidnightProof> {
        match self.proof_mode {
            ProofMode::Mock => self.update_tvl_mirror_mock(new_tvl, tee_signature).await,
            ProofMode::Production => self.update_tvl_mirror_production(new_tvl, tee_signature).await,
        }
    }

    async fn update_tvl_mirror_mock(
        &self,
        new_tvl: u64,
        _tee_signature: &str,
    ) -> Result<MidnightProof> {
        Ok(MidnightProof {
            circuit_type: "update_tvl_mirror".to_string(),
            public_inputs: vec![
                new_tvl.to_string(),
                "mock_tee_signature".to_string(),
            ],
            proof_bytes: vec![0u8; 100],
            verification_key: vec![0u8; 50],
        })
    }

    async fn update_tvl_mirror_production(
        &self,
        new_tvl: u64,
        tee_signature: &str,
    ) -> Result<MidnightProof> {
        let integration_url = self.midnight_integration_url.as_ref()
            .ok_or_else(|| anyhow::anyhow!("Midnight integration URL not configured"))?;

        let client = reqwest::Client::new();
        
        let tvl_request = serde_json::json!({
            "newTvl": new_tvl,
            "teeSignature": tee_signature,
        });

        let url = format!("{}/update-tvl-mirror", integration_url);
        
        let response = timeout(
            Duration::from_millis(30000),
            client
                .post(&url)
                .header("Content-Type", "application/json")
                .json(&tvl_request)
                .send()
        ).await
        .map_err(|_| anyhow::anyhow!("TVL mirror update request timed out"))?
        .map_err(|e| anyhow::anyhow!("Failed to send TVL update request: {}", e))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(anyhow::anyhow!("TVL mirror update failed: {} - {}", status, error_text));
        }

        let result: MidnightProofResult = response.json().await
            .map_err(|e| anyhow::anyhow!("Failed to parse TVL update response: {}", e))?;

        Ok(MidnightProof {
            circuit_type: "update_tvl_mirror".to_string(),
            public_inputs: vec![
                new_tvl.to_string(),
                tee_signature.to_string(),
            ],
            proof_bytes: result.proof,
            verification_key: result.verification_key,
        })
    }

    pub async fn verify_proof(&self, proof: &MidnightProof) -> Result<bool> {
        match self.proof_mode {
            ProofMode::Mock => Ok(true), // Mock proofs always valid
            ProofMode::Production => self.verify_proof_production(proof).await,
        }
    }

    async fn verify_proof_production(&self, proof: &MidnightProof) -> Result<bool> {
        let integration_url = self.midnight_integration_url.as_ref()
            .ok_or_else(|| anyhow::anyhow!("Midnight integration URL not configured"))?;

        let client = reqwest::Client::new();
        
        let verify_request = serde_json::json!({
            "circuitName": proof.circuit_type,
            "proof": hex::encode(&proof.proof_bytes),
            "publicInputs": proof.public_inputs,
            "verificationKey": hex::encode(&proof.verification_key),
        });

        let url = format!("{}/verify-proof", integration_url);
        
        let response = timeout(
            Duration::from_millis(15000),
            client
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

        let result: serde_json::Value = response.json().await
            .map_err(|e| anyhow::anyhow!("Failed to parse verification response: {}", e))?;

        Ok(result["valid"].as_bool().unwrap_or(false))
    }

    pub fn create_tee_signature(&self, data: &[u8]) -> Result<String> {
        // In production, this would use TEE's secure private key
        // For now, create a mock signature
        let mut hasher = Sha256::new();
        hasher.update(data);
        let hash = hasher.finalize();
        
        Ok(format!("tee_sig_{:x}", hash))
    }
}

#[derive(Debug, Deserialize)]
struct MidnightDepositResponse {
    pub concentration_proof: MidnightProofResult,
    pub balance_update_proof: MidnightProofResult,
    pub success: bool,
}

// Legacy compatibility functions
pub async fn generate_zk_proof_with_midnight(
    user: Address,
    amount: u64,
    tvl: u64,
    midnight_tx: String,
    proof_mode: ProofMode,
    integration_url: Option<String>,
) -> Result<Vec<u8>> {
    let service = MidnightZkService::new(proof_mode, integration_url);
    
    let request = MidnightDepositRequest {
        user_address: user,
        user_pubkey: format!("0x{}", hex::encode(user.as_bytes())),
        amount,
        current_tvl: tvl,
    };

    let (concentration_proof, balance_update_proof) = service.process_deposit(request).await?;
    
    // Combine both proofs into a single composite proof
    let mut combined_proof = concentration_proof.proof_bytes;
    combined_proof.extend(balance_update_proof.proof_bytes);
    
    Ok(combined_proof)
}

pub fn verify_zk_proof_with_midnight(
    proof: &[u8],
    _public_inputs: &[u8],
    proof_mode: ProofMode,
    integration_url: Option<String>,
) -> Result<bool> {
    // For now, create a mock proof object for verification
    let mock_proof = MidnightProof {
        circuit_type: "deposit_flow".to_string(),
        public_inputs: vec![],
        proof_bytes: proof.to_vec(),
        verification_key: vec![],
    };

    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(async {
        let service = MidnightZkService::new(proof_mode, integration_url);
        service.verify_proof(&mock_proof).await
    })
}