/**
 * Test suite for Trustless Vault
 */

import { TrustlessVault } from '../vault/TrustlessVault';

describe('TrustlessVault', () => {
  let vault: TrustlessVault;

  beforeEach(() => {
    vault = new TrustlessVault({
      minCollateralRatio: 1.5,
      liquidationThreshold: 1.2,
      interestRatePerBlock: 0.0001
    });
  });

  describe('Deposits', () => {
    test('should accept BTC deposits', async () => {
      const tx = await vault.depositBTC('alice', 1.0);
      
      expect(tx).toBeDefined();
      expect(tx.type).toBe('deposit');
      expect(tx.currency).toBe('BTC');
      expect(tx.amount).toBe(1.0);
      
      const state = vault.getState();
      expect(state.totalBTC).toBe(1.0);
    });

    test('should accept USDT deposits', async () => {
      const tx = await vault.depositUSDT('bob', 10000);
      
      expect(tx).toBeDefined();
      expect(tx.type).toBe('deposit');
      expect(tx.currency).toBe('USDT');
      expect(tx.amount).toBe(10000);
      
      const state = vault.getState();
      expect(state.totalUSDT).toBe(10000);
    });

    test('should reject negative deposits', async () => {
      await expect(vault.depositBTC('alice', -1)).rejects.toThrow('Deposit amount must be positive');
      await expect(vault.depositUSDT('bob', -1000)).rejects.toThrow('Deposit amount must be positive');
    });
  });

  describe('Withdrawals', () => {
    beforeEach(async () => {
      await vault.depositBTC('alice', 2.0);
      await vault.depositUSDT('bob', 20000);
    });

    test('should allow valid BTC withdrawal', async () => {
      const tx = await vault.withdrawBTC('alice', 0.5);
      
      expect(tx).toBeDefined();
      expect(tx.type).toBe('withdrawal');
      expect(tx.amount).toBe(0.5);
      
      const state = vault.getState();
      expect(state.totalBTC).toBe(1.5);
    });

    test('should reject withdrawal exceeding balance', async () => {
      await expect(vault.withdrawBTC('alice', 3.0))
        .rejects.toThrow('Insufficient BTC in vault');
    });
  });

  describe('Lending Positions', () => {
    beforeEach(async () => {
      await vault.depositBTC('alice', 1.0);
      await vault.depositUSDT('bob', 20000);
    });

    test('should create lending position with sufficient collateral', async () => {
      const position = await vault.createLendingPosition(
        'bob',
        'alice',
        5000,
        0.15
      );
      
      expect(position).toBeDefined();
      expect(position.lender).toBe('bob');
      expect(position.borrower).toBe('alice');
      expect(position.amountUSDT).toBe(5000);
      expect(position.collateralBTC).toBe(0.15);
      expect(position.status).toBe('active');
    });

    test('should reject position with insufficient collateral', async () => {
      // Collateral ratio would be 100% (50000 * 0.1 / 5000)
      await expect(vault.createLendingPosition('bob', 'alice', 5000, 0.1))
        .rejects.toThrow('Insufficient collateral');
    });

    test('should update vault balances when creating position', async () => {
      await vault.createLendingPosition('bob', 'alice', 5000, 0.15);
      
      const state = vault.getState();
      expect(state.totalUSDT).toBe(15000); // 20000 - 5000
      expect(state.totalBTC).toBe(1.15); // 1.0 + 0.15
    });
  });

  describe('Loan Repayment', () => {
    let positionId: string;

    beforeEach(async () => {
      await vault.depositBTC('alice', 1.0);
      await vault.depositUSDT('bob', 20000);
      
      const positions = vault.getActiveLendingPositions();
      await vault.createLendingPosition('bob', 'alice', 5000, 0.15);
      const activePositions = vault.getActiveLendingPositions();
      positionId = activePositions[0][0];
    });

    test('should repay loan with interest', async () => {
      // Simulate some time passing for interest
      await new Promise(resolve => setTimeout(resolve, 100));
      
      await vault.repayLoan(positionId, 5100); // Principal + interest
      
      const position = vault.getLendingPosition(positionId);
      expect(position?.status).toBe('repaid');
      
      const state = vault.getState();
      expect(state.totalBTC).toBe(1.0); // Collateral returned
    });

    test('should reject insufficient repayment', async () => {
      await expect(vault.repayLoan(positionId, 1000))
        .rejects.toThrow('Insufficient repayment');
    });
  });

  describe('Liquidations', () => {
    beforeEach(async () => {
      await vault.depositBTC('alice', 1.0);
      await vault.depositUSDT('bob', 20000);
    });

    test('should check for liquidations', async () => {
      await vault.createLendingPosition('bob', 'alice', 5000, 0.15);
      
      const liquidated = await vault.checkLiquidations();
      
      expect(liquidated).toBeDefined();
      expect(Array.isArray(liquidated)).toBe(true);
    });

    test('should not liquidate healthy positions', async () => {
      await vault.createLendingPosition('bob', 'alice', 5000, 0.2); // 200% ratio
      
      const liquidated = await vault.checkLiquidations();
      
      expect(liquidated).toHaveLength(0);
    });
  });

  describe('Statistics', () => {
    test('should provide vault statistics', async () => {
      await vault.depositBTC('alice', 1.0);
      await vault.depositUSDT('bob', 10000);
      await vault.createLendingPosition('bob', 'alice', 5000, 0.15);
      
      const stats = vault.getStatistics();
      
      expect(stats.totalBTC).toBe(1.15);
      expect(stats.totalUSDT).toBe(5000);
      expect(stats.totalLentUSDT).toBe(5000);
      expect(stats.totalCollateralBTC).toBe(0.15);
      expect(stats.activePositions).toBe(1);
      expect(stats.blockHeight).toBeGreaterThan(0);
      expect(stats.stateRoot).toBeDefined();
    });
  });
});