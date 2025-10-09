/**
 * Transaction Manager for handling transaction creation, signing, and verification
 */

import * as crypto from 'crypto';
import { ec as EC } from 'elliptic';
import { Transaction, PreSignedTransaction, ExecutionCondition } from './types';

/**
 * Manages transactions and their signatures
 */
export class TransactionManager {
  private ec: EC;

  constructor() {
    // Initialize elliptic curve for digital signatures
    this.ec = new EC('secp256k1');
  }

  /**
   * Create a new transaction
   */
  createTransaction(
    from: string,
    to: string,
    amount: number,
    currency: 'BTC' | 'USDT',
    type: Transaction['type']
  ): Transaction {
    return {
      id: this.generateTransactionId(),
      from,
      to,
      amount,
      currency,
      timestamp: Date.now(),
      type,
      status: 'pending'
    };
  }

  /**
   * Sign a transaction with private key
   */
  async signTransaction(transaction: Transaction, privateKey: string): Promise<string> {
    const txHash = this.hashTransaction(transaction);
    const key = this.ec.keyFromPrivate(privateKey, 'hex');
    const signature = key.sign(txHash);
    
    return signature.toDER('hex');
  }

  /**
   * Verify transaction signature
   */
  verifySignature(
    transaction: Transaction,
    signature: string,
    publicKey: string
  ): boolean {
    try {
      const txHash = this.hashTransaction(transaction);
      const key = this.ec.keyFromPublic(publicKey, 'hex');
      return key.verify(txHash, signature);
    } catch (error) {
      console.error('Signature verification failed:', error);
      return false;
    }
  }

  /**
   * Create a pre-signed transaction
   */
  createPreSignedTransaction(
    transaction: Transaction,
    signatures: Map<string, string>,
    conditions: ExecutionCondition[]
  ): PreSignedTransaction {
    return {
      transactionId: transaction.id,
      signatures,
      rawTransaction: JSON.stringify(transaction),
      executionConditions: conditions
    };
  }

  /**
   * Verify all conditions for transaction execution
   */
  verifyExecutionConditions(preSignedTx: PreSignedTransaction): boolean {
    for (const condition of preSignedTx.executionConditions) {
      if (!this.verifyCondition(condition)) {
        console.log(`❌ Condition ${condition.type} not satisfied`);
        return false;
      }
    }
    return true;
  }

  /**
   * Verify a single execution condition
   */
  private verifyCondition(condition: ExecutionCondition): boolean {
    switch (condition.type) {
      case 'timelock':
        return Date.now() >= condition.value;
      
      case 'multisig':
        return condition.satisfied;
      
      case 'hashlock':
        // In real implementation, would verify hash preimage
        return condition.satisfied;
      
      case 'snark_proof':
        // In real implementation, would verify SNARK proof
        return condition.satisfied;
      
      default:
        return false;
    }
  }

  /**
   * Execute a pre-signed transaction if conditions are met
   */
  async executePreSignedTransaction(
    preSignedTx: PreSignedTransaction
  ): Promise<{ success: boolean; transaction?: Transaction; error?: string }> {
    console.log(`📝 Executing pre-signed transaction ${preSignedTx.transactionId}...`);
    
    // Verify all conditions
    if (!this.verifyExecutionConditions(preSignedTx)) {
      return {
        success: false,
        error: 'Execution conditions not met'
      };
    }
    
    // Parse transaction
    const transaction: Transaction = JSON.parse(preSignedTx.rawTransaction);
    
    // Verify all required signatures
    for (const [signer, signature] of preSignedTx.signatures) {
      // In real implementation, would verify against actual public keys
      if (!signature) {
        return {
          success: false,
          error: `Missing signature from ${signer}`
        };
      }
    }
    
    // Mark transaction as executed
    transaction.status = 'executed';
    
    console.log(`✅ Transaction ${transaction.id} executed successfully`);
    return {
      success: true,
      transaction
    };
  }

  /**
   * Generate unique transaction ID
   */
  private generateTransactionId(): string {
    return `tx_${Date.now()}_${crypto.randomBytes(8).toString('hex')}`;
  }

  /**
   * Hash a transaction for signing
   */
  private hashTransaction(transaction: Transaction): string {
    const txData = {
      id: transaction.id,
      from: transaction.from,
      to: transaction.to,
      amount: transaction.amount,
      currency: transaction.currency,
      timestamp: transaction.timestamp,
      type: transaction.type
    };
    
    return crypto
      .createHash('sha256')
      .update(JSON.stringify(txData))
      .digest('hex');
  }

  /**
   * Generate a new key pair for a participant
   */
  generateKeyPair(): { publicKey: string; privateKey: string } {
    const key = this.ec.genKeyPair();
    return {
      publicKey: key.getPublic('hex'),
      privateKey: key.getPrivate('hex')
    };
  }

  /**
   * Create a multi-signature transaction
   */
  createMultiSigTransaction(
    transaction: Transaction,
    requiredSignatures: number,
    totalSigners: number
  ): { transaction: Transaction; threshold: number } {
    transaction.status = 'pending';
    
    return {
      transaction,
      threshold: requiredSignatures
    };
  }

  /**
   * Validate transaction format
   */
  validateTransaction(transaction: Transaction): { valid: boolean; errors: string[] } {
    const errors: string[] = [];
    
    if (!transaction.id) {
      errors.push('Transaction ID is required');
    }
    
    if (!transaction.from) {
      errors.push('From address is required');
    }
    
    if (!transaction.to) {
      errors.push('To address is required');
    }
    
    if (transaction.amount <= 0) {
      errors.push('Amount must be positive');
    }
    
    if (!['BTC', 'USDT'].includes(transaction.currency)) {
      errors.push('Invalid currency');
    }
    
    if (!['deposit', 'withdrawal', 'challenge', 'response'].includes(transaction.type)) {
      errors.push('Invalid transaction type');
    }
    
    return {
      valid: errors.length === 0,
      errors
    };
  }
}