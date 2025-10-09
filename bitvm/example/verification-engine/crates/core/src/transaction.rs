// Transaction management


use bitcoin::Transaction;
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionWrapper {
    pub id: String,
    pub raw: Vec<u8>,
    pub status: TransactionStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TransactionStatus {
    Pending,
    Signed,
    Broadcast,
    Confirmed,
    Failed,
}

impl TransactionWrapper {
    pub fn new(id: String, tx: &Transaction) -> Self {
        use bitcoin::consensus::Encodable;
        let mut raw = Vec::new();
        let _ = tx.consensus_encode(&mut raw);
        
        Self {
            id,
            raw,
            status: TransactionStatus::Pending,
        }
    }
}