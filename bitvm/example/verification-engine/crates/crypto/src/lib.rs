// Cryptographic components for BitVM3

pub mod garbled;
pub mod snark;
pub mod hash;
pub mod groth16_verifier;
pub mod bitvm_integration;

use thiserror::Error;

#[derive(Error, Debug)]
pub enum CryptoError {
    #[error("Garbled circuit error: {0}")]
    GarbledCircuitError(String),
    
    #[error("SNARK error: {0}")]
    SNARKError(String),
    
    #[error("Hash error: {0}")]
    HashError(String),
    
    #[error("Verification failed")]
    VerificationFailed,
}

pub type Result<T> = std::result::Result<T, CryptoError>;