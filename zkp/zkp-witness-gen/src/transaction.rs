use ethereum_types::{H256, U256};
use serde::{Deserialize, Serialize};

/// Witness data for individual transactions
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionWitness {
    pub hash: H256,
    pub from: H256,
    pub to: Option<H256>,
    pub value: U256,
    pub nonce: U256,
    pub gas_limit: U256,
    pub gas_price: U256,
    pub input: Vec<u8>,
}


#[cfg(test)]
pub(crate) mod transaction_tests {
    use super::*;

    pub(crate) fn create_mock_transaction() -> TransactionWitness {
        TransactionWitness {
            hash: H256::random(),
            from: H256::random(),
            to: Some(H256::random()),
            value: U256::from(1000000000),
            nonce: U256::from(0),
            gas_limit: U256::from(21000),
            gas_price: U256::from(1000000000),
            input: vec![],
        }
    }

}