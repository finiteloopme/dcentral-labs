use ethereum_types::{H256, U256};
use serde::{Deserialize, Serialize};

use crate::state::StateTransitionWitness;
use crate::transaction::TransactionWitness;

/// Represents the witness data for an Ethereum block that will be used in ZK proof generation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockWitness {
    /// Block header information
    pub header: BlockHeaderWitness,
    /// List of transaction witnesses in the block
    pub transactions: Vec<TransactionWitness>,
    /// State transitions for the block
    pub state_transitions: Vec<StateTransitionWitness>,
}

/// Witness data specifically for block headers
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockHeaderWitness {
    pub parent_hash: H256,
    pub state_root: H256,
    pub transactions_root: H256,
    pub receipts_root: H256,
    pub block_number: U256,
    pub gas_used: U256,
    pub timestamp: U256,
}

#[cfg(test)]
pub(crate) mod block_tests {
    use super::*;
    use crate::transaction::transaction_tests::create_mock_transaction;
    use crate::state::state_tests::create_mock_state_transition;

    pub(crate) fn create_mock_block_header() -> BlockHeaderWitness {
        BlockHeaderWitness {
            parent_hash: H256::random(),
            state_root: H256::random(),
            transactions_root: H256::random(),
            receipts_root: H256::random(),
            block_number: U256::from(1),
            gas_used: U256::from(21000),
            timestamp: U256::from(1634567890),
        }
    }


    #[test]
    fn test_witness_generation_invalid_block() {
        let generator = crate::witness::WitnessGenerator::new(1);
        let mut header = create_mock_block_header();
        header.block_number = U256::zero();
        let transactions = vec![create_mock_transaction()];
        let state_data = vec![create_mock_state_transition()];

        let result = generator.generate_witness(header, transactions, state_data);
        assert!(matches!(result, Err(crate::witness::WitnessError::InvalidBlockData(_))));
    }

}