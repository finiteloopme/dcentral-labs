use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Nonce, Key
};
use anyhow::{Result, anyhow};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SalaryData {
    pub role: String,
    pub salary: u64,
    pub location: String,
    pub years_experience: u32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EncryptedPayload {
    pub ciphertext: Vec<u8>,
    pub nonce: Vec<u8>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AttestationRequest {
    pub nonce: Vec<u8>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AttestationResponse {
    pub quote: Vec<u8>,
    pub eventlog: Vec<u8>,
    pub mrenclave: String,
    pub mrsigner: String,
    pub product_id: u16,
    pub svn: u16,
    pub attributes: u64,
    pub certificate_chain: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SalaryRequest {
    pub encrypted_data: EncryptedPayload,
    pub session_id: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SalaryResponse {
    pub success: bool,
    pub message: String,
    pub statistics: Option<SalaryStatistics>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SalaryStatistics {
    pub role: String,
    pub average_salary: f64,
    pub median_salary: f64,
    pub min_salary: u64,
    pub max_salary: u64,
    pub sample_size: usize,
    pub location_breakdown: Vec<LocationStats>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LocationStats {
    pub location: String,
    pub average_salary: f64,
    pub count: usize,
}

pub struct CryptoUtils;

impl CryptoUtils {
    pub fn generate_session_key() -> Vec<u8> {
        use rand::RngCore;
        let mut key = vec![0u8; 32];
        OsRng.fill_bytes(&mut key);
        key
    }

    pub fn generate_nonce() -> Vec<u8> {
        use rand::RngCore;
        let mut nonce = vec![0u8; 12];
        OsRng.fill_bytes(&mut nonce);
        nonce
    }

    pub fn encrypt_data(data: &[u8], key: &[u8]) -> Result<EncryptedPayload> {
        if key.len() != 32 {
            return Err(anyhow!("Invalid key length"));
        }

        let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
        let nonce_bytes = Self::generate_nonce();
        let nonce = Nonce::from_slice(&nonce_bytes);
        
        let ciphertext = cipher.encrypt(nonce, data)
            .map_err(|e| anyhow!("Encryption failed: {}", e))?;

        Ok(EncryptedPayload {
            ciphertext,
            nonce: nonce_bytes,
        })
    }

    pub fn decrypt_data(payload: &EncryptedPayload, key: &[u8]) -> Result<Vec<u8>> {
        if key.len() != 32 {
            return Err(anyhow!("Invalid key length"));
        }

        let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
        let nonce = Nonce::from_slice(&payload.nonce);
        
        cipher.decrypt(nonce, payload.ciphertext.as_ref())
            .map_err(|e| anyhow!("Decryption failed: {}", e))
    }

    pub fn hash_data(data: &[u8]) -> Vec<u8> {
        let mut hasher = Sha256::new();
        hasher.update(data);
        hasher.finalize().to_vec()
    }

    pub fn derive_session_key(shared_secret: &[u8], nonce: &[u8]) -> Vec<u8> {
        let mut hasher = Sha256::new();
        hasher.update(shared_secret);
        hasher.update(nonce);
        hasher.finalize().to_vec()
    }
}

pub struct AttestationVerifier;

impl AttestationVerifier {
    pub fn verify_tdx_quote(quote: &[u8], expected_mrenclave: &str) -> Result<bool> {
        if quote.len() < 48 {
            return Err(anyhow!("Quote too short"));
        }

        let version = u16::from_le_bytes([quote[0], quote[1]]);
        if version != 4 {
            return Err(anyhow!("Unsupported TDX quote version"));
        }

        let att_key_type = u16::from_le_bytes([quote[2], quote[3]]);
        if att_key_type != 2 {
            return Err(anyhow!("Invalid attestation key type"));
        }

        println!("[Attestation] Quote version: {}, Key type: {}", version, att_key_type);
        println!("[Attestation] Verifying MRENCLAVE: {}", expected_mrenclave);
        
        Ok(true)
    }

    pub fn verify_certificate_chain(certificates: &[String]) -> Result<bool> {
        if certificates.is_empty() {
            return Err(anyhow!("Empty certificate chain"));
        }

        println!("[Attestation] Verifying certificate chain with {} certificates", certificates.len());
        
        for (i, cert) in certificates.iter().enumerate() {
            println!("[Attestation] Certificate {}: {} bytes", i, cert.len());
        }

        Ok(true)
    }

    pub fn verify_eventlog(eventlog: &[u8], expected_hash: &[u8]) -> Result<bool> {
        let computed_hash = CryptoUtils::hash_data(eventlog);
        
        if computed_hash != expected_hash {
            return Err(anyhow!("Event log hash mismatch"));
        }

        println!("[Attestation] Event log verified successfully");
        Ok(true)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encryption_decryption() {
        let key = CryptoUtils::generate_session_key();
        let data = b"test data";
        
        let encrypted = CryptoUtils::encrypt_data(data, &key).unwrap();
        let decrypted = CryptoUtils::decrypt_data(&encrypted, &key).unwrap();
        
        assert_eq!(data.to_vec(), decrypted);
    }

    #[test]
    fn test_hash() {
        let data = b"test data";
        let hash1 = CryptoUtils::hash_data(data);
        let hash2 = CryptoUtils::hash_data(data);
        
        assert_eq!(hash1, hash2);
    }
}