// Core BitVM3 protocol implementation in Rust

pub mod protocol;
pub mod transaction;
pub mod types;
pub mod bitvm_protocol;
pub mod taproot;

use bitcoin::{Network, Address};
use secp256k1::{Secp256k1, SecretKey};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum BitVM3Error {
    #[error("Invalid transaction: {0}")]
    InvalidTransaction(String),
    
    #[error("Insufficient funds: required {required}, available {available}")]
    InsufficientFunds { required: u64, available: u64 },
    
    #[error("Challenge failed: {0}")]
    ChallengeFailed(String),
    
    #[error("Cryptographic error: {0}")]
    CryptoError(String),
    
    #[error("State error: {0}")]
    StateError(String),
}

impl From<bitvm3_crypto::CryptoError> for BitVM3Error {
    fn from(err: bitvm3_crypto::CryptoError) -> Self {
        BitVM3Error::CryptoError(err.to_string())
    }
}

pub type Result<T> = std::result::Result<T, BitVM3Error>;

/// Core BitVM3 Protocol
pub struct BitVM3Protocol {
    participants: HashMap<String, Participant>,
    vault_state: VaultState,
    transaction_graph: TransactionGraph,
    secp: Secp256k1<secp256k1::All>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Participant {
    pub name: String,
    pub public_key: Vec<u8>,  // Store as bytes for serialization
    pub address: String,  // Store as string to avoid serialization issues
    pub balance: Balance,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Balance {
    pub btc: u64,  // Satoshis
    pub usdt: u64, // Cents
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VaultState {
    pub total_btc: u64,
    pub total_usdt: u64,
    pub block_height: u64,
    pub state_root: [u8; 32],
    pub lending_positions: HashMap<String, LendingPosition>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LendingPosition {
    pub id: String,
    pub lender: String,
    pub borrower: String,
    pub amount_usdt: u64,
    pub collateral_btc: u64,
    pub interest_rate: f64,
    pub start_block: u64,
    pub duration: u64,
    pub status: LendingStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum LendingStatus {
    Active,
    Repaid,
    Liquidated,
}

#[derive(Debug, Clone)]
pub struct TransactionGraph {
    pub nodes: HashMap<String, TransactionNode>,
    pub edges: HashMap<String, Vec<String>>,
    pub pre_signed: HashMap<String, PreSignedTransaction>,
}

#[derive(Debug, Clone)]
pub struct TransactionNode {
    pub id: String,
    pub transaction_id: String,  // Store ID instead of full transaction
    pub required_signatures: Vec<Vec<u8>>,  // Store public keys as bytes
    pub next_states: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct PreSignedTransaction {
    pub transaction_id: String,
    pub signatures: HashMap<String, Vec<u8>>,  // Use string keys
    pub raw_transaction: Vec<u8>,
}

impl BitVM3Protocol {
    pub fn new() -> Self {
        Self {
            participants: HashMap::new(),
            vault_state: VaultState {
                total_btc: 0,
                total_usdt: 0,
                block_height: 0,
                state_root: [0u8; 32],
                lending_positions: HashMap::new(),
            },
            transaction_graph: TransactionGraph {
                nodes: HashMap::new(),
                edges: HashMap::new(),
                pre_signed: HashMap::new(),
            },
            secp: Secp256k1::new(),
        }
    }
    
    pub async fn initialize(
        &mut self,
        alice_key: SecretKey,
        bob_key: SecretKey,
    ) -> Result<()> {
        tracing::info!("Initializing BitVM3 protocol");
        
        // Create participants
        let alice = self.create_participant("alice", alice_key)?;
        let bob = self.create_participant("bob", bob_key)?;
        
        self.participants.insert("alice".to_string(), alice);
        self.participants.insert("bob".to_string(), bob);
        
        // Generate transaction graph
        self.generate_transaction_graph().await?;
        
        // Pre-sign all transactions
        self.pre_sign_transactions().await?;
        
        tracing::info!("BitVM3 protocol initialized successfully");
        Ok(())
    }
    
    fn create_participant(
        &self,
        name: &str,
        secret_key: SecretKey,
    ) -> Result<Participant> {
        let public_key = secp256k1::PublicKey::from_secret_key(&self.secp, &secret_key);
        
        // Create Bitcoin address using CompressedPublicKey for bitcoin 0.32
        let pubkey_bytes = public_key.serialize();
        let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(&pubkey_bytes)
            .map_err(|e| BitVM3Error::CryptoError(e.to_string()))?;
        let address = Address::p2wpkh(&compressed_pubkey, Network::Bitcoin);
        
        Ok(Participant {
            name: name.to_string(),
            public_key: public_key.serialize().to_vec(),  // Store as bytes
            address: address.to_string(),
            balance: Balance {
                btc: if name == "alice" { 200_000_000 } else { 0 }, // 2 BTC
                usdt: if name == "bob" { 2_000_000 } else { 0 }, // 20k USDT
            },
        })
    }
    
    async fn generate_transaction_graph(&mut self) -> Result<()> {
        // Implementation for generating the complete transaction graph
        // This would create all possible state transitions
        tracing::debug!("Generating transaction graph");
        
        // Add deposit, withdrawal, challenge nodes
        // Connect them with edges representing valid transitions
        
        Ok(())
    }
    
    async fn pre_sign_transactions(&mut self) -> Result<()> {
        // Pre-sign all transactions in the graph
        tracing::debug!("Pre-signing {} transactions", self.transaction_graph.nodes.len());
        
        for (node_id, node) in &self.transaction_graph.nodes {
            // Get signatures from required participants
            // Store in pre_signed map
        }
        
        Ok(())
    }
    
    pub async fn deposit(&mut self, participant: &str, amount: u64, currency: &str) -> Result<()> {
        tracing::info!("Processing {} {} deposit from {}", amount, currency, participant);
        
        let participant = self.participants.get_mut(participant)
            .ok_or_else(|| BitVM3Error::StateError("Participant not found".to_string()))?;
        
        match currency {
            "BTC" => {
                if participant.balance.btc < amount {
                    return Err(BitVM3Error::InsufficientFunds {
                        required: amount,
                        available: participant.balance.btc,
                    });
                }
                participant.balance.btc -= amount;
                self.vault_state.total_btc += amount;
            }
            "USDT" => {
                if participant.balance.usdt < amount {
                    return Err(BitVM3Error::InsufficientFunds {
                        required: amount,
                        available: participant.balance.usdt,
                    });
                }
                participant.balance.usdt -= amount;
                self.vault_state.total_usdt += amount;
            }
            _ => return Err(BitVM3Error::InvalidTransaction("Invalid currency".to_string())),
        }
        
        self.update_state_root();
        self.vault_state.block_height += 1;
        
        Ok(())
    }
    
    pub async fn withdraw(&mut self, participant: &str, amount: u64, currency: &str) -> Result<()> {
        tracing::info!("Processing {} {} withdrawal to {}", amount, currency, participant);
        
        // First check vault has sufficient funds
        match currency {
            "BTC" => {
                if self.vault_state.total_btc < amount {
                    return Err(BitVM3Error::InsufficientFunds {
                        required: amount,
                        available: self.vault_state.total_btc,
                    });
                }
            }
            "USDT" => {
                if self.vault_state.total_usdt < amount {
                    return Err(BitVM3Error::InsufficientFunds {
                        required: amount,
                        available: self.vault_state.total_usdt,
                    });
                }
            }
            _ => return Err(BitVM3Error::InvalidTransaction("Invalid currency".to_string())),
        }
        
        // Get participant and update their balance
        let participant = self.participants.get_mut(participant)
            .ok_or_else(|| BitVM3Error::StateError("Participant not found".to_string()))?;
        
        match currency {
            "BTC" => {
                self.vault_state.total_btc -= amount;
                participant.balance.btc += amount;
            }
            "USDT" => {
                self.vault_state.total_usdt -= amount;
                participant.balance.usdt += amount;
            }
            _ => unreachable!(), // Already checked above
        }
        
        self.update_state_root();
        self.vault_state.block_height += 1;
        
        Ok(())
    }
    
    fn update_state_root(&mut self) {
        use sha2::{Sha256, Digest};
        
        let mut hasher = Sha256::new();
        hasher.update(self.vault_state.total_btc.to_le_bytes());
        hasher.update(self.vault_state.total_usdt.to_le_bytes());
        hasher.update(self.vault_state.block_height.to_le_bytes());
        
        let result = hasher.finalize();
        self.vault_state.state_root.copy_from_slice(&result);
    }
    
    pub fn get_vault_state(&self) -> &VaultState {
        &self.vault_state
    }
    
    pub fn get_participant(&self, name: &str) -> Option<&Participant> {
        self.participants.get(name)
    }
}
// Re-export Taproot functionality
pub use crate::taproot::{
    TaprootParticipant,
    VaultTaprootBuilder,
    PreSignedTransactionGraph,
    TaprootSecretKey,
    BitcoinNetwork,
};
