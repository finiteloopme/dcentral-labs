/**
 * Trustless Vault implementation for lending stablecoins with BTC
 * Manages deposits, withdrawals, and lending operations
 */

import { EventEmitter } from 'events';
import * as crypto from 'crypto';
import { 
  VaultState, 
  LendingPosition, 
  Participant,
  Transaction 
} from '../core/types';
import { GarbledCircuit } from '../crypto/GarbledCircuit';
import { SNARKVerifier } from '../crypto/SNARKVerifier';

/**
 * Vault configuration
 */
interface VaultConfig {
  minCollateralRatio: number;
  liquidationThreshold: number;
  maxLoanDuration: number;
  interestRatePerBlock: number;
}

/**
 * Trustless Vault for BTC-backed USDT lending
 */
export class TrustlessVault extends EventEmitter {
  private state: VaultState;
  private config: VaultConfig;
  private garbledCircuit: GarbledCircuit;
  private snarkVerifier: SNARKVerifier;
  private stateHistory: VaultState[];

  constructor(config?: Partial<VaultConfig>) {
    super();
    
    this.config = {
      minCollateralRatio: 1.5,
      liquidationThreshold: 1.2,
      maxLoanDuration: 30 * 24 * 60 * 60 * 1000, // 30 days in ms
      interestRatePerBlock: 0.0001, // 0.01% per block
      ...config
    };
    
    this.state = {
      totalBTC: 0,
      totalUSDT: 0,
      lendingPool: new Map(),
      collateralRatio: this.config.minCollateralRatio,
      lastStateRoot: '',
      blockHeight: 0
    };
    
    this.garbledCircuit = new GarbledCircuit();
    this.snarkVerifier = new SNARKVerifier();
    this.stateHistory = [];
    
    this.state.lastStateRoot = this.computeStateRoot();
  }

  /**
   * Deposit BTC into the vault
   */
  async depositBTC(depositor: string, amount: number): Promise<Transaction> {
    console.log(`💰 ${depositor} depositing ${amount} BTC...`);
    
    // Validate deposit
    if (amount <= 0) {
      throw new Error('Deposit amount must be positive');
    }
    
    // Update state
    const previousState = { ...this.state };
    this.state.totalBTC += amount;
    this.state.blockHeight++;
    
    // Generate state transition proof
    const proof = await this.generateStateTransitionProof(previousState, this.state);
    
    // Update state root
    this.state.lastStateRoot = this.computeStateRoot();
    this.stateHistory.push({ ...this.state });
    
    // Create transaction
    const transaction: Transaction = {
      id: this.generateTransactionId(),
      from: depositor,
      to: 'vault',
      amount,
      currency: 'BTC',
      timestamp: Date.now(),
      type: 'deposit',
      status: 'executed',
      signature: proof
    };
    
    this.emit('btc_deposited', { depositor, amount, newBalance: this.state.totalBTC });
    console.log(`✅ BTC deposit successful. Vault BTC balance: ${this.state.totalBTC}`);
    
    return transaction;
  }

  /**
   * Deposit USDT into the vault
   */
  async depositUSDT(depositor: string, amount: number): Promise<Transaction> {
    console.log(`💵 ${depositor} depositing ${amount} USDT...`);
    
    // Validate deposit
    if (amount <= 0) {
      throw new Error('Deposit amount must be positive');
    }
    
    // Update state
    const previousState = { ...this.state };
    this.state.totalUSDT += amount;
    this.state.blockHeight++;
    
    // Generate state transition proof
    const proof = await this.generateStateTransitionProof(previousState, this.state);
    
    // Update state root
    this.state.lastStateRoot = this.computeStateRoot();
    this.stateHistory.push({ ...this.state });
    
    // Create transaction
    const transaction: Transaction = {
      id: this.generateTransactionId(),
      from: depositor,
      to: 'vault',
      amount,
      currency: 'USDT',
      timestamp: Date.now(),
      type: 'deposit',
      status: 'executed',
      signature: proof
    };
    
    this.emit('usdt_deposited', { depositor, amount, newBalance: this.state.totalUSDT });
    console.log(`✅ USDT deposit successful. Vault USDT balance: ${this.state.totalUSDT}`);
    
    return transaction;
  }

  /**
   * Withdraw BTC from the vault with garbled circuit verification
   */
  async withdrawBTC(withdrawer: string, amount: number): Promise<Transaction> {
    console.log(`💸 ${withdrawer} withdrawing ${amount} BTC...`);
    
    // Run off-chain computation
    const computation = await this.garbledCircuit.evaluate({
      participant: withdrawer,
      amount,
      currency: 'BTC',
      vaultState: this.state
    });
    
    // Verify computation
    if (!computation.result) {
      throw new Error('Withdrawal not allowed: Failed garbled circuit verification');
    }
    
    // Verify SNARK proof
    const isValid = await this.snarkVerifier.verify(
      computation.proof,
      computation.publicInputs
    );
    
    if (!isValid) {
      throw new Error('Withdrawal not allowed: Invalid SNARK proof');
    }
    
    // Check vault balance
    if (amount > this.state.totalBTC) {
      throw new Error('Insufficient BTC in vault');
    }
    
    // Update state
    const previousState = { ...this.state };
    this.state.totalBTC -= amount;
    this.state.blockHeight++;
    
    // Update state root
    this.state.lastStateRoot = this.computeStateRoot();
    this.stateHistory.push({ ...this.state });
    
    // Create transaction
    const transaction: Transaction = {
      id: this.generateTransactionId(),
      from: 'vault',
      to: withdrawer,
      amount,
      currency: 'BTC',
      timestamp: Date.now(),
      type: 'withdrawal',
      status: 'executed',
      signature: computation.proof
    };
    
    this.emit('btc_withdrawn', { withdrawer, amount, newBalance: this.state.totalBTC });
    console.log(`✅ BTC withdrawal successful. Vault BTC balance: ${this.state.totalBTC}`);
    
    return transaction;
  }

  /**
   * Create a lending position
   */
  async createLendingPosition(
    lender: string,
    borrower: string,
    amountUSDT: number,
    collateralBTC: number
  ): Promise<LendingPosition> {
    console.log(`📝 Creating lending position: ${lender} -> ${borrower}`);
    
    // Calculate collateral ratio
    const btcPriceUSD = 50000; // Mock BTC price
    const collateralValue = collateralBTC * btcPriceUSD;
    const collateralRatio = collateralValue / amountUSDT;
    
    // Check minimum collateral ratio
    if (collateralRatio < this.config.minCollateralRatio) {
      throw new Error(`Insufficient collateral. Required ratio: ${this.config.minCollateralRatio}, provided: ${collateralRatio}`);
    }
    
    // Check vault balances
    if (amountUSDT > this.state.totalUSDT) {
      throw new Error('Insufficient USDT in vault for lending');
    }
    
    // Create position
    const position: LendingPosition = {
      lender,
      borrower,
      amountUSDT,
      collateralBTC,
      interestRate: this.config.interestRatePerBlock,
      startTime: Date.now(),
      duration: this.config.maxLoanDuration,
      status: 'active'
    };
    
    // Store position
    const positionId = this.generatePositionId();
    this.state.lendingPool.set(positionId, position);
    
    // Update vault state
    this.state.totalUSDT -= amountUSDT; // USDT goes to borrower
    this.state.totalBTC += collateralBTC; // BTC locked as collateral
    this.state.blockHeight++;
    this.state.lastStateRoot = this.computeStateRoot();
    
    this.emit('lending_position_created', { positionId, position });
    console.log(`✅ Lending position created: ${positionId}`);
    
    return position;
  }

  /**
   * Repay a lending position
   */
  async repayLoan(positionId: string, repaymentUSDT: number): Promise<void> {
    console.log(`💵 Repaying loan position: ${positionId}`);
    
    const position = this.state.lendingPool.get(positionId);
    if (!position) {
      throw new Error('Lending position not found');
    }
    
    if (position.status !== 'active') {
      throw new Error('Position is not active');
    }
    
    // Calculate interest
    const timeElapsed = Date.now() - position.startTime;
    const blocksElapsed = Math.floor(timeElapsed / 10000); // Mock: 1 block = 10 seconds
    const interest = position.amountUSDT * position.interestRate * blocksElapsed;
    const totalRepayment = position.amountUSDT + interest;
    
    if (repaymentUSDT < totalRepayment) {
      throw new Error(`Insufficient repayment. Required: ${totalRepayment} USDT`);
    }
    
    // Update position
    position.status = 'repaid';
    
    // Return collateral
    this.state.totalBTC -= position.collateralBTC;
    this.state.totalUSDT += totalRepayment;
    this.state.blockHeight++;
    this.state.lastStateRoot = this.computeStateRoot();
    
    this.emit('loan_repaid', { positionId, repayment: totalRepayment, interest });
    console.log(`✅ Loan repaid. Interest earned: ${interest} USDT`);
  }

  /**
   * Check and liquidate under-collateralized positions
   */
  async checkLiquidations(): Promise<string[]> {
    console.log('🔍 Checking for liquidations...');
    
    const liquidated: string[] = [];
    const btcPriceUSD = 50000; // Mock BTC price
    
    for (const [positionId, position] of this.state.lendingPool) {
      if (position.status !== 'active') continue;
      
      // Calculate current collateral ratio
      const collateralValue = position.collateralBTC * btcPriceUSD;
      const currentRatio = collateralValue / position.amountUSDT;
      
      // Check liquidation threshold
      if (currentRatio < this.config.liquidationThreshold) {
        console.log(`⚠️  Liquidating position ${positionId} (ratio: ${currentRatio})`);
        
        position.status = 'liquidated';
        
        // Liquidate collateral
        // In real implementation, this would auction the collateral
        this.state.totalUSDT += position.amountUSDT;
        
        liquidated.push(positionId);
        this.emit('position_liquidated', { positionId, collateralRatio: currentRatio });
      }
    }
    
    if (liquidated.length > 0) {
      this.state.blockHeight++;
      this.state.lastStateRoot = this.computeStateRoot();
      console.log(`✅ Liquidated ${liquidated.length} positions`);
    } else {
      console.log('✅ No positions require liquidation');
    }
    
    return liquidated;
  }

  /**
   * Generate state transition proof
   */
  private async generateStateTransitionProof(
    oldState: VaultState,
    newState: VaultState
  ): Promise<string> {
    const oldRoot = this.computeStateRootFromState(oldState);
    const newRoot = this.computeStateRootFromState(newState);
    
    const proof = await this.snarkVerifier.generateBitHashProof(oldRoot, newRoot);
    return proof.proof;
  }

  /**
   * Compute state root
   */
  private computeStateRoot(): string {
    return this.computeStateRootFromState(this.state);
  }

  /**
   * Compute state root from a given state
   */
  private computeStateRootFromState(state: VaultState): string {
    const stateData = {
      totalBTC: state.totalBTC,
      totalUSDT: state.totalUSDT,
      lendingPoolSize: state.lendingPool.size,
      blockHeight: state.blockHeight,
      timestamp: Date.now()
    };
    
    return crypto
      .createHash('sha256')
      .update(JSON.stringify(stateData))
      .digest('hex');
  }

  /**
   * Generate transaction ID
   */
  private generateTransactionId(): string {
    return `tx_${Date.now()}_${crypto.randomBytes(8).toString('hex')}`;
  }

  /**
   * Generate position ID
   */
  private generatePositionId(): string {
    return `pos_${Date.now()}_${crypto.randomBytes(8).toString('hex')}`;
  }

  /**
   * Get vault state
   */
  getState(): VaultState {
    return { ...this.state };
  }

  /**
   * Get lending position
   */
  getLendingPosition(positionId: string): LendingPosition | undefined {
    return this.state.lendingPool.get(positionId);
  }

  /**
   * Get all active lending positions
   */
  getActiveLendingPositions(): Array<[string, LendingPosition]> {
    const active: Array<[string, LendingPosition]> = [];
    
    for (const [id, position] of this.state.lendingPool) {
      if (position.status === 'active') {
        active.push([id, position]);
      }
    }
    
    return active;
  }

  /**
   * Get vault statistics
   */
  getStatistics() {
    const totalLentUSDT = Array.from(this.state.lendingPool.values())
      .filter(p => p.status === 'active')
      .reduce((sum, p) => sum + p.amountUSDT, 0);
    
    const totalCollateralBTC = Array.from(this.state.lendingPool.values())
      .filter(p => p.status === 'active')
      .reduce((sum, p) => sum + p.collateralBTC, 0);
    
    return {
      totalBTC: this.state.totalBTC,
      totalUSDT: this.state.totalUSDT,
      totalLentUSDT,
      totalCollateralBTC,
      activePositions: this.getActiveLendingPositions().length,
      blockHeight: this.state.blockHeight,
      stateRoot: this.state.lastStateRoot
    };
  }
}