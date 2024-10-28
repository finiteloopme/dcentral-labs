use ethereum_types::{H256, U256};
use thiserror::Error;

use crate::block::{BlockHeaderWitness, BlockWitness};
use crate::transaction::TransactionWitness;
use crate::state::StateTransitionWitness;

/// Error types for witness generation
#[derive(Error, Debug)]
pub enum WitnessError {
    #[error("Invalid block data: {0}")]
    InvalidBlockData(String),
    #[error("Missing state data: {0}")]
    MissingStateData(String),
    #[error("Witness generation failed: {0}")]
    GenerationError(String),
}

/// Main witness generator implementation
pub struct WitnessGenerator {
    chain_id: u64,
}

impl WitnessGenerator {
    /// Creates a new witness generator instance
    pub fn new(chain_id: u64) -> Self {
        Self { chain_id }
    }

    /// Generates witness data for a given block
    pub fn generate_witness(
        &self,
        block_header: BlockHeaderWitness,
        transactions: Vec<TransactionWitness>,
        state_data: Vec<StateTransitionWitness>,
    ) -> Result<BlockWitness, WitnessError> {
        // Validate inputs
        self.validate_block_data(&block_header, &transactions, &state_data)?;

        // Create witness
        Ok(BlockWitness {
            header: block_header,
            transactions,
            state_transitions: state_data,
        })
    }

    /// Validates the input data before witness generation
    fn validate_block_data(
        &self,
        header: &BlockHeaderWitness,
        transactions: &[TransactionWitness],
        state_data: &[StateTransitionWitness],
    ) -> Result<(), WitnessError> {
        // Validate block header
        if header.block_number == U256::zero() {
            return Err(WitnessError::InvalidBlockData(
                "Block number cannot be zero".to_string(),
            ));
        }

        // Validate transactions
        for tx in transactions {
            if tx.gas_limit == U256::zero() {
                return Err(WitnessError::InvalidBlockData(
                    "Transaction gas limit cannot be zero".to_string(),
                ));
            }
        }

        // Validate state transitions
        for transition in state_data {
            if transition.address == H256::zero() {
                return Err(WitnessError::InvalidBlockData(
                    "Invalid address in state transition".to_string(),
                ));
            }
        }

        Ok(())
    }

    /// Serializes the witness data to bytes
    pub fn serialize_witness(&self, witness: &BlockWitness) -> Result<Vec<u8>, WitnessError> {
        serde_json::to_vec(witness).map_err(|e| WitnessError::GenerationError(e.to_string()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::block_tests::create_mock_block_header;
    use crate::transaction::transaction_tests::create_mock_transaction;
    use crate::state::state_tests::create_mock_state_transition;

    #[test]
    fn test_witness_generation_success() {
        let generator = WitnessGenerator::new(1);
        let header = create_mock_block_header();
        let transactions = vec![create_mock_transaction()];
        let state_data = vec![create_mock_state_transition()];

        let result = generator.generate_witness(header, transactions, state_data);
        assert!(result.is_ok());
    }

    #[test]
    fn test_witness_serialization() {
        let generator = WitnessGenerator::new(1);
        let header = create_mock_block_header();
        let transactions = vec![create_mock_transaction()];
        let state_data = vec![create_mock_state_transition()];

        let witness = generator
            .generate_witness(header, transactions, state_data)
            .unwrap();
        let serialized = generator.serialize_witness(&witness);
        assert!(serialized.is_ok());
    }

}