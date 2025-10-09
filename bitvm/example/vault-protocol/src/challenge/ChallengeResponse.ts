/**
 * Challenge-Response mechanism for dispute resolution
 * Handles challenges to malicious withdrawals and operator misconduct
 */

import { EventEmitter } from 'events';
import * as crypto from 'crypto';
import { Challenge, Transaction } from '../core/types';
import { SNARKVerifier } from '../crypto/SNARKVerifier';
import { GarbledCircuit } from '../crypto/GarbledCircuit';

/**
 * Challenge parameters
 */
interface ChallengeParams {
  challengerId: string;
  operatorId: string;
  disputedTransaction: Transaction;
  evidence: string;
}

/**
 * Response to a challenge
 */
interface ChallengeResponse {
  responderId: string;
  challengeId: string;
  proof: string;
  counterEvidence: string;
  timestamp: number;
}

/**
 * Challenge-Response System for BitVM3
 */
export class ChallengeResponseSystem extends EventEmitter {
  private challenges: Map<string, Challenge>;
  private responses: Map<string, ChallengeResponse>;
  private snarkVerifier: SNARKVerifier;
  private garbledCircuit: GarbledCircuit;
  private challengeTimeout: number = 3600000; // 1 hour
  private responseTimeout: number = 1800000; // 30 minutes

  constructor() {
    super();
    this.challenges = new Map();
    this.responses = new Map();
    this.snarkVerifier = new SNARKVerifier();
    this.garbledCircuit = new GarbledCircuit();
  }

  /**
   * Initiate a challenge against a transaction
   */
  async initiateChallenge(params: ChallengeParams): Promise<Challenge> {
    console.log(`⚔️  ${params.challengerId} initiating challenge against ${params.operatorId}...`);
    
    // Validate the disputed transaction
    if (!this.validateTransaction(params.disputedTransaction)) {
      throw new Error('Invalid disputed transaction');
    }
    
    // Generate challenge proof
    const challengeProof = await this.generateChallengeProof(params);
    
    // Create challenge
    const challenge: Challenge = {
      id: this.generateChallengeId(),
      challenger: params.challengerId,
      operator: params.operatorId,
      disputedTransaction: params.disputedTransaction.id,
      proof: challengeProof,
      status: 'pending',
      timestamp: Date.now(),
      deadline: Date.now() + this.challengeTimeout
    };
    
    // Store challenge
    this.challenges.set(challenge.id, challenge);
    
    // Set timeout for automatic resolution
    this.setChallengeeTimeout(challenge);
    
    this.emit('challenge_initiated', challenge);
    console.log(`✅ Challenge initiated: ${challenge.id}`);
    
    return challenge;
  }

  /**
   * Respond to a challenge
   */
  async respondToChallenge(
    challengeId: string,
    responderId: string,
    counterProof: string
  ): Promise<ChallengeResponse> {
    console.log(`🛡️  ${responderId} responding to challenge ${challengeId}...`);
    
    const challenge = this.challenges.get(challengeId);
    if (!challenge) {
      throw new Error('Challenge not found');
    }
    
    if (challenge.status !== 'pending') {
      throw new Error(`Challenge is not pending (status: ${challenge.status})`);
    }
    
    if (Date.now() > challenge.deadline) {
      throw new Error('Challenge deadline has passed');
    }
    
    // Verify counter-proof
    const isValidResponse = await this.verifyResponse(challenge, counterProof);
    
    // Create response
    const response: ChallengeResponse = {
      responderId,
      challengeId,
      proof: counterProof,
      counterEvidence: await this.generateCounterEvidence(challenge, counterProof),
      timestamp: Date.now()
    };
    
    // Store response
    this.responses.set(challengeId, response);
    
    // Update challenge status
    if (isValidResponse) {
      challenge.status = 'disproved';
      console.log('✅ Challenge disproved by valid response');
    } else {
      challenge.status = 'proved';
      console.log('⚠️  Response invalid, challenge stands');
    }
    
    this.emit('challenge_responded', { challenge, response });
    
    return response;
  }

  /**
   * Generate proof for a challenge
   */
  private async generateChallengeProof(params: ChallengeParams): Promise<string> {
    console.log('🔨 Generating challenge proof...');
    
    // Create proof data
    const proofData = {
      challenger: params.challengerId,
      operator: params.operatorId,
      transaction: params.disputedTransaction,
      evidence: params.evidence,
      timestamp: Date.now()
    };
    
    // Generate SNARK proof
    const { proof } = await this.snarkVerifier.generateProof(
      proofData,
      [
        params.disputedTransaction.id,
        params.disputedTransaction.amount.toString(),
        params.evidence
      ]
    );
    
    // Hash the proof
    const proofHash = crypto
      .createHash('sha256')
      .update(JSON.stringify(proof))
      .digest('hex');
    
    return proofHash;
  }

  /**
   * Verify a response to a challenge
   */
  private async verifyResponse(
    challenge: Challenge,
    counterProof: string
  ): Promise<boolean> {
    console.log('🔍 Verifying challenge response...');
    
    // Verify the counter-proof using SNARK verifier
    const isValid = await this.snarkVerifier.verifyChallenge(counterProof);
    
    if (!isValid) {
      console.log('❌ Counter-proof verification failed');
      return false;
    }
    
    // Additional verification using garbled circuits
    const computation = await this.garbledCircuit.verifyComputation(
      counterProof,
      [challenge.disputedTransaction]
    );
    
    console.log(computation ? '✅ Response verified' : '❌ Response invalid');
    return computation;
  }

  /**
   * Generate counter-evidence for a response
   */
  private async generateCounterEvidence(
    challenge: Challenge,
    counterProof: string
  ): Promise<string> {
    const evidenceData = {
      challengeId: challenge.id,
      originalProof: challenge.proof,
      counterProof,
      timestamp: Date.now()
    };
    
    return crypto
      .createHash('sha256')
      .update(JSON.stringify(evidenceData))
      .digest('hex');
  }

  /**
   * Process on-chain challenge resolution
   */
  async resolveOnChain(challengeId: string): Promise<boolean> {
    console.log(`⛓️  Resolving challenge ${challengeId} on-chain...`);
    
    const challenge = this.challenges.get(challengeId);
    if (!challenge) {
      throw new Error('Challenge not found');
    }
    
    const response = this.responses.get(challengeId);
    
    // If no response, challenger wins by default
    if (!response && Date.now() > challenge.deadline) {
      challenge.status = 'proved';
      console.log('✅ Challenge proved (no response received)');
      this.emit('challenge_resolved', { challengeId, winner: 'challenger' });
      return true;
    }
    
    // Verify both proofs on-chain
    const challengeValid = await this.snarkVerifier.verifyChallenge(challenge.proof);
    const responseValid = response ? 
      await this.snarkVerifier.verifyChallenge(response.proof) : false;
    
    // Determine winner
    if (challengeValid && !responseValid) {
      challenge.status = 'proved';
      console.log('✅ Challenge proved');
      this.emit('challenge_resolved', { challengeId, winner: 'challenger' });
      return true;
    } else if (!challengeValid && responseValid) {
      challenge.status = 'disproved';
      console.log('✅ Challenge disproved');
      this.emit('challenge_resolved', { challengeId, winner: 'operator' });
      return false;
    } else {
      // Ambiguous case - needs manual resolution
      challenge.status = 'pending';
      console.log('⚠️  Ambiguous resolution, needs manual review');
      this.emit('challenge_ambiguous', { challengeId });
      return false;
    }
  }

  /**
   * Set timeout for challenge
   */
  private setChallengeeTimeout(challenge: Challenge): void {
    setTimeout(async () => {
      if (challenge.status === 'pending') {
        console.log(`⏰ Challenge ${challenge.id} timed out`);
        challenge.status = 'timeout';
        await this.resolveOnChain(challenge.id);
      }
    }, this.challengeTimeout);
  }

  /**
   * Validate transaction format
   */
  private validateTransaction(transaction: Transaction): boolean {
    return !!(
      transaction.id &&
      transaction.from &&
      transaction.to &&
      transaction.amount > 0 &&
      transaction.currency &&
      transaction.type
    );
  }

  /**
   * Generate challenge ID
   */
  private generateChallengeId(): string {
    return `challenge_${Date.now()}_${crypto.randomBytes(8).toString('hex')}`;
  }

  /**
   * Get challenge by ID
   */
  getChallenge(challengeId: string): Challenge | undefined {
    return this.challenges.get(challengeId);
  }

  /**
   * Get all challenges
   */
  getAllChallenges(): Challenge[] {
    return Array.from(this.challenges.values());
  }

  /**
   * Get active challenges
   */
  getActiveChallenges(): Challenge[] {
    return Array.from(this.challenges.values())
      .filter(c => c.status === 'pending');
  }

  /**
   * Get challenges for a specific operator
   */
  getChallengesForOperator(operatorId: string): Challenge[] {
    return Array.from(this.challenges.values())
      .filter(c => c.operator === operatorId);
  }

  /**
   * Calculate penalty for losing a challenge
   */
  calculatePenalty(challenge: Challenge): number {
    // Base penalty is 10% of disputed amount
    // In real implementation, this would be more sophisticated
    return 0.1;
  }

  /**
   * Process penalty payment
   */
  async processPenalty(
    challengeId: string,
    loser: 'challenger' | 'operator'
  ): Promise<void> {
    console.log(`💰 Processing penalty for ${loser}...`);
    
    const challenge = this.challenges.get(challengeId);
    if (!challenge) {
      throw new Error('Challenge not found');
    }
    
    const penalty = this.calculatePenalty(challenge);
    
    // In real implementation, this would transfer funds
    this.emit('penalty_processed', {
      challengeId,
      loser,
      penalty
    });
    
    console.log(`✅ Penalty of ${penalty} BTC processed`);
  }
}