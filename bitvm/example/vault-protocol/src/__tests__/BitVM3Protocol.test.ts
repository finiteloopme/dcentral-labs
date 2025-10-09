/**
 * Test suite for BitVM3 Protocol
 */

import { BitVM3Protocol } from '../core/BitVM3Protocol';
import { TransactionManager } from '../core/TransactionManager';
import { Participant } from '../core/types';

describe('BitVM3Protocol', () => {
  let protocol: BitVM3Protocol;
  let transactionManager: TransactionManager;
  let alice: Participant;
  let bob: Participant;

  beforeEach(async () => {
    protocol = new BitVM3Protocol();
    transactionManager = new TransactionManager();

    // Generate key pairs
    const aliceKeys = transactionManager.generateKeyPair();
    const bobKeys = transactionManager.generateKeyPair();

    // Create participants
    alice = {
      name: 'Alice',
      publicKey: aliceKeys.publicKey,
      privateKey: aliceKeys.privateKey,
      balance: { BTC: 2.0, USDT: 0 }
    };

    bob = {
      name: 'Bob',
      publicKey: bobKeys.publicKey,
      privateKey: bobKeys.privateKey,
      balance: { BTC: 0, USDT: 20000 }
    };

    // Initialize protocol
    await protocol.initialize(alice, bob);
  });

  describe('Initialization', () => {
    test('should initialize with participants', () => {
      const aliceData = protocol.getParticipant('alice');
      const bobData = protocol.getParticipant('bob');

      expect(aliceData).toBeDefined();
      expect(bobData).toBeDefined();
      expect(aliceData?.name).toBe('Alice');
      expect(bobData?.name).toBe('Bob');
    });

    test('should create initial vault state', () => {
      const vaultState = protocol.getVaultState();

      expect(vaultState).toBeDefined();
      expect(vaultState.totalBTC).toBe(0);
      expect(vaultState.totalUSDT).toBe(0);
      expect(vaultState.blockHeight).toBe(0);
      expect(vaultState.lastStateRoot).toBeDefined();
    });
  });

  describe('Deposits', () => {
    test('should handle BTC deposit', async () => {
      await protocol.deposit('alice', 1.0, 'BTC');
      
      const vaultState = protocol.getVaultState();
      const aliceData = protocol.getParticipant('alice');
      
      expect(vaultState.totalBTC).toBe(1.0);
      expect(aliceData?.balance.BTC).toBe(1.0); // 2.0 - 1.0
    });

    test('should handle USDT deposit', async () => {
      await protocol.deposit('bob', 10000, 'USDT');
      
      const vaultState = protocol.getVaultState();
      const bobData = protocol.getParticipant('bob');
      
      expect(vaultState.totalUSDT).toBe(10000);
      expect(bobData?.balance.USDT).toBe(10000); // 20000 - 10000
    });

    test('should update block height on deposit', async () => {
      const initialHeight = protocol.getVaultState().blockHeight;
      
      await protocol.deposit('alice', 0.5, 'BTC');
      
      const newHeight = protocol.getVaultState().blockHeight;
      expect(newHeight).toBe(initialHeight + 1);
    });
  });

  describe('Withdrawals', () => {
    beforeEach(async () => {
      // Setup: deposit funds first
      await protocol.deposit('alice', 1.0, 'BTC');
      await protocol.deposit('bob', 10000, 'USDT');
    });

    test('should handle valid BTC withdrawal', async () => {
      const success = await protocol.withdraw('alice', 0.5, 'BTC');
      
      expect(success).toBe(true);
      
      const vaultState = protocol.getVaultState();
      expect(vaultState.totalBTC).toBe(0.5); // 1.0 - 0.5
    });

    test('should reject withdrawal exceeding balance', async () => {
      const success = await protocol.withdraw('alice', 2.0, 'BTC');
      
      expect(success).toBe(false);
      
      const vaultState = protocol.getVaultState();
      expect(vaultState.totalBTC).toBe(1.0); // Unchanged
    });
  });

  describe('Challenges', () => {
    test('should create a challenge', async () => {
      const challenge = await protocol.challengeTransaction(
        'alice',
        'test_tx_id',
        'test_proof'
      );
      
      expect(challenge).toBeDefined();
      expect(challenge.challenger).toBe('alice');
      expect(challenge.operator).toBe('bob');
      expect(challenge.disputedTransaction).toBe('test_tx_id');
    });

    test('should track challenges', async () => {
      await protocol.challengeTransaction('alice', 'tx1', 'proof1');
      await protocol.challengeTransaction('alice', 'tx2', 'proof2');
      
      const challenges = protocol.getChallenges();
      
      expect(challenges).toHaveLength(2);
      expect(challenges[0].disputedTransaction).toBe('tx1');
      expect(challenges[1].disputedTransaction).toBe('tx2');
    });
  });

  describe('State Management', () => {
    test('should update state root on changes', async () => {
      const initialRoot = protocol.getVaultState().lastStateRoot;
      
      await protocol.deposit('alice', 0.1, 'BTC');
      
      const newRoot = protocol.getVaultState().lastStateRoot;
      expect(newRoot).not.toBe(initialRoot);
    });

    test('should maintain consistent state', async () => {
      await protocol.deposit('alice', 1.0, 'BTC');
      await protocol.deposit('bob', 5000, 'USDT');
      await protocol.withdraw('alice', 0.3, 'BTC');
      
      const vaultState = protocol.getVaultState();
      
      expect(vaultState.totalBTC).toBe(0.7);
      expect(vaultState.totalUSDT).toBe(5000);
      expect(vaultState.blockHeight).toBeGreaterThan(0);
    });
  });
});