/**
 * Core BitVM3 Protocol implementation
 * Manages the overall protocol flow and coordinates between components
 */

import { EventEmitter } from 'events';
import { 
  Participant, 
  Transaction, 
  TransactionGraph, 
  VaultState, 
  Challenge,
  TransactionNode,
  PreSignedTransaction,
  ExecutionCondition
} from './types';
import { GarbledCircuit } from '../crypto/GarbledCircuit';
import { SNARKVerifier } from '../crypto/SNARKVerifier';
import { TransactionManager } from './TransactionManager';

/**
 * Main BitVM3 Protocol class that orchestrates the entire system
 */
export class BitVM3Protocol extends EventEmitter {
  private participants: Map<string, Participant>;
  private transactionGraph: TransactionGraph;
  private vaultState: VaultState;
  private challenges: Map<string, Challenge>;
  private garbledCircuit: GarbledCircuit;
  private snarkVerifier: SNARKVerifier;
  private transactionManager: TransactionManager;

  constructor() {
    super();
    this.participants = new Map();
    this.challenges = new Map();
    this.garbledCircuit = new GarbledCircuit();
    this.snarkVerifier = new SNARKVerifier();
    this.transactionManager = new TransactionManager();
    
    this.transactionGraph = {
      nodes: new Map(),
      edges: new Map(),
      preSignedTransactions: new Map()
    };

    this.vaultState = {
      totalBTC: 0,
      totalUSDT: 0,
      lendingPool: new Map(),
      collateralRatio: 1.5,
      lastStateRoot: '',  // Initialize as empty, will be set after
      blockHeight: 0
    };
    
    // Now generate the state root after vaultState is initialized
    this.vaultState.lastStateRoot = this.generateStateRoot();
  }

  /**
   * Initialize the protocol with participants
   */
  async initialize(alice: Participant, bob: Participant): Promise<void> {
    console.log('🚀 Initializing BitVM3 Protocol...');
    
    this.participants.set('alice', alice);
    this.participants.set('bob', bob);
    
    // Generate transaction graph
    await this.generateTransactionGraph();
    
    // Pre-sign all transactions
    await this.preSignTransactions();
    
    this.emit('initialized', { alice, bob });
    console.log('✅ BitVM3 Protocol initialized successfully');
  }

  /**
   * Generate the complete transaction graph with all possible execution paths
   */
  private async generateTransactionGraph(): Promise<void> {
    console.log('📊 Generating transaction graph...');
    
    // Create deposit nodes
    const aliceDepositNode = this.createTransactionNode(
      'alice_deposit',
      'alice',
      'vault',
      1.0,
      'BTC',
      'deposit'
    );
    
    const bobDepositNode = this.createTransactionNode(
      'bob_deposit',
      'bob',
      'vault',
      10000,
      'USDT',
      'deposit'
    );
    
    // Create withdrawal nodes
    const aliceWithdrawNode = this.createTransactionNode(
      'alice_withdraw',
      'vault',
      'alice',
      1.0,
      'BTC',
      'withdrawal'
    );
    
    const bobWithdrawNode = this.createTransactionNode(
      'bob_withdraw',
      'vault',
      'bob',
      10000,
      'USDT',
      'withdrawal'
    );
    
    // Create challenge nodes
    const challengeNode = this.createTransactionNode(
      'challenge',
      'alice',
      'protocol',
      0,
      'BTC',
      'challenge'
    );
    
    // Create response nodes
    const responseNode = this.createTransactionNode(
      'response',
      'bob',
      'protocol',
      0,
      'BTC',
      'response'
    );
    
    // Add nodes to graph
    this.transactionGraph.nodes.set('alice_deposit', aliceDepositNode);
    this.transactionGraph.nodes.set('bob_deposit', bobDepositNode);
    this.transactionGraph.nodes.set('alice_withdraw', aliceWithdrawNode);
    this.transactionGraph.nodes.set('bob_withdraw', bobWithdrawNode);
    this.transactionGraph.nodes.set('challenge', challengeNode);
    this.transactionGraph.nodes.set('response', responseNode);
    
    // Define edges (state transitions)
    this.transactionGraph.edges.set('alice_deposit', ['bob_deposit', 'alice_withdraw']);
    this.transactionGraph.edges.set('bob_deposit', ['alice_withdraw', 'bob_withdraw']);
    this.transactionGraph.edges.set('alice_withdraw', ['challenge']);
    this.transactionGraph.edges.set('bob_withdraw', ['challenge']);
    this.transactionGraph.edges.set('challenge', ['response']);
    this.transactionGraph.edges.set('response', ['alice_withdraw', 'bob_withdraw']);
    
    console.log('✅ Transaction graph generated with', this.transactionGraph.nodes.size, 'nodes');
  }

  /**
   * Create a transaction node
   */
  private createTransactionNode(
    id: string,
    from: string,
    to: string,
    amount: number,
    currency: 'BTC' | 'USDT',
    type: Transaction['type']
  ): TransactionNode {
    const transaction: Transaction = {
      id,
      from,
      to,
      amount,
      currency,
      timestamp: Date.now(),
      type,
      status: 'pending'
    };
    
    return {
      id,
      transaction,
      requiredSignatures: [from],
      nextStates: []
    };
  }

  /**
   * Pre-sign all transactions in the graph
   */
  private async preSignTransactions(): Promise<void> {
    console.log('✍️  Pre-signing transactions...');
    
    for (const [nodeId, node] of this.transactionGraph.nodes) {
      const signatures = new Map<string, string>();
      
      // Get signatures from required participants
      for (const signer of node.requiredSignatures) {
        const participant = this.participants.get(signer);
        if (participant) {
          const signature = await this.transactionManager.signTransaction(
            node.transaction,
            participant.privateKey
          );
          signatures.set(signer, signature);
        }
      }
      
      // Create pre-signed transaction
      const preSignedTx: PreSignedTransaction = {
        transactionId: node.transaction.id,
        signatures,
        rawTransaction: JSON.stringify(node.transaction),
        executionConditions: this.generateExecutionConditions(node.transaction.type)
      };
      
      this.transactionGraph.preSignedTransactions.set(nodeId, preSignedTx);
    }
    
    console.log('✅ Pre-signed', this.transactionGraph.preSignedTransactions.size, 'transactions');
  }

  /**
   * Generate execution conditions for a transaction
   */
  private generateExecutionConditions(type: Transaction['type']): ExecutionCondition[] {
    const conditions: ExecutionCondition[] = [];
    
    switch (type) {
      case 'deposit':
        conditions.push({
          type: 'multisig',
          value: 1,
          satisfied: false
        });
        break;
      
      case 'withdrawal':
        conditions.push({
          type: 'timelock',
          value: Date.now() + 86400000, // 24 hours
          satisfied: false
        });
        conditions.push({
          type: 'snark_proof',
          value: null,
          satisfied: false
        });
        break;
      
      case 'challenge':
        conditions.push({
          type: 'hashlock',
          value: this.generateHashlock(),
          satisfied: false
        });
        break;
      
      case 'response':
        conditions.push({
          type: 'snark_proof',
          value: null,
          satisfied: false
        });
        break;
    }
    
    return conditions;
  }

  /**
   * Execute a deposit transaction
   */
  async deposit(participantName: string, amount: number, currency: 'BTC' | 'USDT'): Promise<void> {
    console.log(`💰 Processing ${currency} deposit from ${participantName}...`);
    
    const participant = this.participants.get(participantName);
    if (!participant) {
      throw new Error(`Participant ${participantName} not found`);
    }
    
    // Update vault state
    if (currency === 'BTC') {
      this.vaultState.totalBTC += amount;
      if (participant.balance.BTC !== undefined) {
        participant.balance.BTC -= amount;
      }
    } else {
      this.vaultState.totalUSDT += amount;
      if (participant.balance.USDT !== undefined) {
        participant.balance.USDT -= amount;
      }
    }
    
    // Update state root
    this.vaultState.lastStateRoot = this.generateStateRoot();
    this.vaultState.blockHeight++;
    
    this.emit('deposit', { participant: participantName, amount, currency });
    console.log(`✅ Deposit successful. New vault balance: ${currency} ${currency === 'BTC' ? this.vaultState.totalBTC : this.vaultState.totalUSDT}`);
  }

  /**
   * Execute a withdrawal with off-chain computation
   */
  async withdraw(participantName: string, amount: number, currency: 'BTC' | 'USDT'): Promise<boolean> {
    console.log(`💸 Processing ${currency} withdrawal for ${participantName}...`);
    
    // Run off-chain computation using garbled circuit
    const computation = await this.garbledCircuit.evaluate({
      participant: participantName,
      amount,
      currency,
      vaultState: this.vaultState
    });
    
    // Verify with SNARK
    const isValid = await this.snarkVerifier.verify(
      computation.proof,
      computation.publicInputs
    );
    
    if (!isValid) {
      console.log('❌ Withdrawal failed: Invalid proof');
      this.emit('withdrawal_failed', { participant: participantName, reason: 'Invalid proof' });
      return false;
    }
    
    // Update vault state
    if (currency === 'BTC') {
      this.vaultState.totalBTC -= amount;
    } else {
      this.vaultState.totalUSDT -= amount;
    }
    
    const participant = this.participants.get(participantName);
    if (participant) {
      if (currency === 'BTC' && participant.balance.BTC !== undefined) {
        participant.balance.BTC += amount;
      } else if (currency === 'USDT' && participant.balance.USDT !== undefined) {
        participant.balance.USDT += amount;
      }
    }
    
    this.vaultState.lastStateRoot = this.generateStateRoot();
    this.vaultState.blockHeight++;
    
    this.emit('withdrawal', { participant: participantName, amount, currency });
    console.log(`✅ Withdrawal successful. New vault balance: ${currency} ${currency === 'BTC' ? this.vaultState.totalBTC : this.vaultState.totalUSDT}`);
    return true;
  }

  /**
   * Challenge a transaction
   */
  async challengeTransaction(
    challengerId: string,
    transactionId: string,
    proof: string
  ): Promise<Challenge> {
    console.log(`⚔️  ${challengerId} challenging transaction ${transactionId}...`);
    
    const challenge: Challenge = {
      id: `challenge_${Date.now()}`,
      challenger: challengerId,
      operator: 'bob', // Assuming Bob is always the operator
      disputedTransaction: transactionId,
      proof,
      status: 'pending',
      timestamp: Date.now(),
      deadline: Date.now() + 3600000 // 1 hour deadline
    };
    
    this.challenges.set(challenge.id, challenge);
    
    // Process challenge on-chain
    const result = await this.processChallengeOnChain(challenge);
    challenge.status = result ? 'proved' : 'disproved';
    
    this.emit('challenge', challenge);
    console.log(`✅ Challenge ${challenge.status}: ${challenge.id}`);
    return challenge;
  }

  /**
   * Process challenge on-chain
   */
  private async processChallengeOnChain(challenge: Challenge): Promise<boolean> {
    console.log('⛓️  Processing challenge on-chain...');
    
    // Simulate on-chain verification
    // In real implementation, this would interact with Bitcoin Script
    const isValidChallenge = await this.snarkVerifier.verifyChallenge(challenge.proof);
    
    if (isValidChallenge) {
      // Revert the disputed transaction
      console.log('✅ Challenge valid. Reverting transaction...');
      return true;
    }
    
    console.log('❌ Challenge invalid');
    return false;
  }

  /**
   * Generate state root for the vault
   */
  private generateStateRoot(): string {
    const crypto = require('crypto');
    const stateData = JSON.stringify({
      totalBTC: this.vaultState.totalBTC,
      totalUSDT: this.vaultState.totalUSDT,
      blockHeight: this.vaultState.blockHeight,
      timestamp: Date.now()
    });
    
    return crypto.createHash('sha256').update(stateData).digest('hex');
  }

  /**
   * Generate hashlock for challenge conditions
   */
  private generateHashlock(): string {
    const crypto = require('crypto');
    return crypto.randomBytes(32).toString('hex');
  }

  /**
   * Get current vault state
   */
  getVaultState(): VaultState {
    return this.vaultState;
  }

  /**
   * Get participant info
   */
  getParticipant(name: string): Participant | undefined {
    return this.participants.get(name);
  }

  /**
   * Get all challenges
   */
  getChallenges(): Challenge[] {
    return Array.from(this.challenges.values());
  }
}