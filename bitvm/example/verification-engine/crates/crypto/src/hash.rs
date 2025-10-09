// Hash implementations for BitVM3

use sha2::{Sha256, Digest};
use blake3;

/// BitHash implementation optimized for Bitcoin Script
pub struct BitHash;

impl BitHash {
    /// Compute BitHash using Blake3 (optimized for Bitcoin)
    pub fn hash(data: &[u8]) -> [u8; 32] {
        let mut hasher = blake3::Hasher::new();
        hasher.update(data);
        let hash = hasher.finalize();
        
        let mut result = [0u8; 32];
        result.copy_from_slice(hash.as_bytes());
        result
    }
    
    /// Compute SHA256 hash (Bitcoin native)
    pub fn sha256(data: &[u8]) -> [u8; 32] {
        let mut hasher = Sha256::new();
        hasher.update(data);
        
        let result = hasher.finalize();
        let mut hash = [0u8; 32];
        hash.copy_from_slice(&result);
        hash
    }
    
    /// Verify a hash
    pub fn verify(data: &[u8], expected_hash: &[u8; 32]) -> bool {
        let computed = Self::hash(data);
        computed == *expected_hash
    }
    
    /// Double SHA256 (used in Bitcoin)
    pub fn double_sha256(data: &[u8]) -> [u8; 32] {
        let first_hash = Self::sha256(data);
        Self::sha256(&first_hash)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_bithash() {
        let data = b"test data";
        let hash1 = BitHash::hash(data);
        let hash2 = BitHash::hash(data);
        
        assert_eq!(hash1, hash2);
        assert!(BitHash::verify(data, &hash1));
    }
    
    #[test]
    fn test_sha256() {
        let data = b"bitcoin";
        let hash = BitHash::sha256(data);
        assert_eq!(hash.len(), 32);
    }
    
    #[test]
    fn test_double_sha256() {
        let data = b"block header";
        let hash = BitHash::double_sha256(data);
        assert_eq!(hash.len(), 32);
    }
}