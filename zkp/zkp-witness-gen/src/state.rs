use ethereum_types::{H256, U256};
use serde::{Deserialize, Serialize};

/// Witness data for state transitions
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateTransitionWitness {
    pub address: H256,
    pub pre_state: AccountStateWitness,
    pub post_state: AccountStateWitness,
}

/// Account state information for state transitions
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccountStateWitness {
    pub nonce: U256,
    pub balance: U256,
    pub storage_root: H256,
    pub code_hash: H256,
}


#[cfg(test)]
pub(crate) mod state_tests {
    use super::*;
    pub(crate) fn create_mock_state_transition() -> StateTransitionWitness {
        StateTransitionWitness {
            address: H256::random(),
            pre_state: AccountStateWitness {
                nonce: U256::zero(),
                balance: U256::from(1000000000),
                storage_root: H256::random(),
                code_hash: H256::random(),
            },
            post_state: AccountStateWitness {
                nonce: U256::one(),
                balance: U256::from(999979000),
                storage_root: H256::random(),
                code_hash: H256::random(),
            },
        }
    }
}