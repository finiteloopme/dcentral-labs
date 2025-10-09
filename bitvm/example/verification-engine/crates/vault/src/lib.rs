// Trustless Vault implementation

use bitvm3_core::{VaultState, LendingPosition, LendingStatus};
use bitvm3_crypto::snark::SNARKVerifier;
use std::collections::HashMap;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum VaultError {
    #[error("Insufficient balance: {0}")]
    InsufficientBalance(String),
    
    #[error("Invalid collateral ratio: {0}")]
    InvalidCollateral(String),
    
    #[error("Position not found: {0}")]
    PositionNotFound(String),
}

pub type Result<T> = std::result::Result<T, VaultError>;

pub struct TrustlessVault {
    state: VaultState,
    config: VaultConfig,
}

pub struct VaultConfig {
    pub min_collateral_ratio: f64,
    pub liquidation_threshold: f64,
    pub interest_rate_per_block: f64,
}

impl Default for VaultConfig {
    fn default() -> Self {
        Self {
            min_collateral_ratio: 1.5,
            liquidation_threshold: 1.2,
            interest_rate_per_block: 0.0001,
        }
    }
}

impl TrustlessVault {
    pub fn new(config: VaultConfig) -> Self {
        Self {
            state: VaultState {
                total_btc: 0,
                total_usdt: 0,
                block_height: 0,
                state_root: [0u8; 32],
                lending_positions: HashMap::new(),
            },
            config,
        }
    }
    
    pub async fn create_lending_position(
        &mut self,
        lender: String,
        borrower: String,
        amount_usdt: u64,
        collateral_btc: u64,
    ) -> Result<String> {
        // Check collateral ratio (assuming 1 BTC = $50,000)
        let btc_value = collateral_btc * 50000;
        let ratio = btc_value as f64 / amount_usdt as f64;
        
        if ratio < self.config.min_collateral_ratio {
            return Err(VaultError::InvalidCollateral(
                format!("Ratio {} is below minimum {}", ratio, self.config.min_collateral_ratio)
            ));
        }
        
        let position_id = format!("pos_{}", self.state.block_height);
        
        let position = LendingPosition {
            id: position_id.clone(),
            lender,
            borrower,
            amount_usdt,
            collateral_btc,
            interest_rate: self.config.interest_rate_per_block,
            start_block: self.state.block_height,
            duration: 30 * 24 * 60, // 30 days in blocks (1 min blocks)
            status: LendingStatus::Active,
        };
        
        self.state.lending_positions.insert(position_id.clone(), position);
        self.state.total_usdt -= amount_usdt;
        self.state.total_btc += collateral_btc;
        self.state.block_height += 1;
        
        Ok(position_id)
    }
    
    pub async fn check_liquidations(&mut self) -> Vec<String> {
        let mut liquidated = Vec::new();
        
        for (id, position) in &mut self.state.lending_positions {
            if position.status != LendingStatus::Active {
                continue;
            }
            
            // Check collateral ratio
            let btc_value = position.collateral_btc * 50000;
            let ratio = btc_value as f64 / position.amount_usdt as f64;
            
            if ratio < self.config.liquidation_threshold {
                position.status = LendingStatus::Liquidated;
                liquidated.push(id.clone());
                
                // Return USDT to vault
                self.state.total_usdt += position.amount_usdt;
            }
        }
        
        liquidated
    }
    
    pub fn get_state(&self) -> &VaultState {
        &self.state
    }
}