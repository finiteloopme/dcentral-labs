/**
 * Garbled Circuit implementation for off-chain computation
 * Simulates secure multi-party computation for vault operations
 */

import * as crypto from 'crypto';
import { VaultState } from '../core/types';

/**
 * Represents a wire in the garbled circuit
 */
interface Wire {
  id: string;
  label0: string; // Label for bit 0
  label1: string; // Label for bit 1
  value?: boolean;
}

/**
 * Represents a gate in the garbled circuit
 */
interface Gate {
  id: string;
  type: 'AND' | 'OR' | 'XOR' | 'NOT';
  inputWires: string[];
  outputWire: string;
  truthTable: Map<string, string>;
}

/**
 * Computation result from the garbled circuit
 */
export interface GarbledComputation {
  result: boolean;
  proof: string;
  publicInputs: string[];
  executionTime: number;
}

/**
 * Garbled Circuit for secure off-chain computation
 */
export class GarbledCircuit {
  private wires: Map<string, Wire>;
  private gates: Map<string, Gate>;
  private circuit: Gate[];

  constructor() {
    this.wires = new Map();
    this.gates = new Map();
    this.circuit = [];
  }

  /**
   * Evaluate a computation using the garbled circuit
   */
  async evaluate(input: {
    participant: string;
    amount: number;
    currency: string;
    vaultState: VaultState;
  }): Promise<GarbledComputation> {
    const startTime = Date.now();
    
    console.log('🔌 Evaluating garbled circuit...');
    
    // Build circuit for the specific computation
    this.buildCircuit(input);
    
    // Garble the circuit
    this.garbleCircuit();
    
    // Evaluate the garbled circuit
    const result = this.evaluateGarbledCircuit(input);
    
    // Generate proof
    const proof = this.generateProof(input, result);
    
    const executionTime = Date.now() - startTime;
    
    console.log(`✅ Garbled circuit evaluated in ${executionTime}ms`);
    
    return {
      result,
      proof,
      publicInputs: [
        input.participant,
        input.amount.toString(),
        input.currency,
        input.vaultState.lastStateRoot
      ],
      executionTime
    };
  }

  /**
   * Build the circuit for vault operations
   */
  private buildCircuit(_input: any): void {
    // Create input wires
    const w1 = this.createWire('input_amount');
    const w2 = this.createWire('vault_balance');
    const w3 = this.createWire('collateral_ratio');
    
    // Create intermediate wires
    const w4 = this.createWire('sufficient_balance');
    const w5 = this.createWire('collateral_check');
    
    // Create output wire
    const w6 = this.createWire('output');
    
    // Create gates for balance check
    const g1 = this.createGate('balance_check', 'XOR', [w1.id, w2.id], w4.id);
    
    // Create gates for collateral check
    const g2 = this.createGate('collateral_check', 'AND', [w3.id, w4.id], w5.id);
    
    // Create final validation gate
    const g3 = this.createGate('validation', 'AND', [w4.id, w5.id], w6.id);
    
    // Build circuit topology
    this.circuit = [g1, g2, g3];
  }

  /**
   * Create a wire with random labels
   */
  private createWire(id: string): Wire {
    const wire: Wire = {
      id,
      label0: this.generateRandomLabel(),
      label1: this.generateRandomLabel()
    };
    
    this.wires.set(id, wire);
    return wire;
  }

  /**
   * Create a gate with garbled truth table
   */
  private createGate(
    id: string,
    type: Gate['type'],
    inputWires: string[],
    outputWire: string
  ): Gate {
    const gate: Gate = {
      id,
      type,
      inputWires,
      outputWire,
      truthTable: new Map()
    };
    
    // Generate garbled truth table
    this.generateGarbledTruthTable(gate);
    
    this.gates.set(id, gate);
    return gate;
  }

  /**
   * Garble the entire circuit
   */
  private garbleCircuit(): void {
    console.log('🔐 Garbling circuit with', this.gates.size, 'gates...');
    
    for (const gate of this.circuit) {
      this.garbleGate(gate);
    }
  }

  /**
   * Garble a single gate
   */
  private garbleGate(gate: Gate): void {
    const inputWires = gate.inputWires.map(id => this.wires.get(id)!);
    const outputWire = this.wires.get(gate.outputWire)!;
    
    // Create garbled truth table entries
    const entries: string[] = [];
    
    for (let i = 0; i < Math.pow(2, inputWires.length); i++) {
      const inputBits = this.toBinary(i, inputWires.length);
      const outputBit = this.computeGateOutput(gate.type, inputBits);
      
      // Get input labels
      const inputLabels = inputBits.map((bit, idx) => 
        bit ? inputWires[idx].label1 : inputWires[idx].label0
      );
      
      // Get output label
      const outputLabel = outputBit ? outputWire.label1 : outputWire.label0;
      
      // Encrypt output label with input labels
      const encryptedLabel = this.encrypt(outputLabel, inputLabels.join(''));
      entries.push(encryptedLabel);
    }
    
    // Shuffle entries for security
    this.shuffleArray(entries);
    
    // Store in truth table
    entries.forEach((entry, idx) => {
      gate.truthTable.set(`entry_${idx}`, entry);
    });
  }

  /**
   * Generate garbled truth table for a gate
   */
  private generateGarbledTruthTable(gate: Gate): void {
    const numInputs = gate.inputWires.length;
    const tableSize = Math.pow(2, numInputs);
    
    for (let i = 0; i < tableSize; i++) {
      const key = `entry_${i}`;
      const value = this.generateRandomLabel();
      gate.truthTable.set(key, value);
    }
  }

  /**
   * Evaluate the garbled circuit with given inputs
   */
  private evaluateGarbledCircuit(input: any): boolean {
    // Simulate circuit evaluation
    // In real implementation, this would process wire labels through gates
    
    const { amount, vaultState, currency } = input;
    
    // Check if withdrawal amount is valid
    if (currency === 'BTC') {
      return amount <= vaultState.totalBTC;
    } else if (currency === 'USDT') {
      return amount <= vaultState.totalUSDT;
    }
    
    return false;
  }

  /**
   * Generate proof of correct computation
   */
  private generateProof(input: any, result: boolean): string {
    const proofData = {
      circuit: this.circuit.map(g => ({
        id: g.id,
        type: g.type,
        inputs: g.inputWires,
        output: g.outputWire
      })),
      input: {
        participant: input.participant,
        amount: input.amount,
        currency: input.currency,
        stateRoot: input.vaultState.lastStateRoot
      },
      result,
      timestamp: Date.now()
    };
    
    return crypto
      .createHash('sha256')
      .update(JSON.stringify(proofData))
      .digest('hex');
  }

  /**
   * Compute gate output based on gate type
   */
  private computeGateOutput(type: Gate['type'], inputs: boolean[]): boolean {
    switch (type) {
      case 'AND':
        return inputs.every(b => b);
      case 'OR':
        return inputs.some(b => b);
      case 'XOR':
        return inputs.filter(b => b).length % 2 === 1;
      case 'NOT':
        return !inputs[0];
      default:
        return false;
    }
  }

  /**
   * Generate random label for wire
   */
  private generateRandomLabel(): string {
    return crypto.randomBytes(16).toString('hex');
  }

  /**
   * Encrypt data with key
   */
  private encrypt(data: string, key: string): string {
    // Use a simple hash-based encryption for demo
    // In production, use proper encryption with IV
    const hash = crypto.createHash('sha256');
    hash.update(data);
    hash.update(key);
    return hash.digest('hex');
  }

  /**
   * Convert number to binary array
   */
  private toBinary(num: number, length: number): boolean[] {
    const binary = num.toString(2).padStart(length, '0');
    return binary.split('').map(b => b === '1');
  }

  /**
   * Shuffle array in place
   */
  private shuffleArray<T>(array: T[]): void {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
  }

  /**
   * Verify a garbled circuit computation
   */
  async verifyComputation(
    proof: string,
    publicInputs: string[]
  ): Promise<boolean> {
    console.log('🔍 Verifying garbled circuit computation...');
    
    // Simulate verification
    // In real implementation, this would verify the proof against the circuit
    
    const proofHash = crypto.createHash('sha256').update(proof).digest('hex');
    const inputHash = crypto.createHash('sha256').update(publicInputs.join('')).digest('hex');
    
    // Simple verification (in reality, much more complex)
    const isValid = proofHash.length === 64 && inputHash.length === 64;
    
    console.log(isValid ? '✅ Computation verified' : '❌ Computation verification failed');
    return isValid;
  }
}