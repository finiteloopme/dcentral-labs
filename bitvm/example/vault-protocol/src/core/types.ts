/**
 * Core types and interfaces for BitVM3 implementation
 */

/**
 * Represents a participant in the BitVM3 protocol
 */
export interface Participant {
  name: string;
  publicKey: string;
  privateKey: string;
  balance: {
    BTC?: number;
    USDT?: number;
  };
}

/**
 * Represents a transaction in the transaction graph
 */
export interface Transaction {
  id: string;
  from: string;
  to: string;
  amount: number;
  currency: 'BTC' | 'USDT';
  signature?: string;
  timestamp: number;
  type: 'deposit' | 'withdrawal' | 'challenge' | 'response';
  status: 'pending' | 'signed' | 'executed' | 'challenged' | 'resolved';
}

/**
 * Represents the transaction graph with all possible execution paths
 */
export interface TransactionGraph {
  nodes: Map<string, TransactionNode>;
  edges: Map<string, string[]>;
  preSignedTransactions: Map<string, PreSignedTransaction>;
}

/**
 * Node in the transaction graph
 */
export interface TransactionNode {
  id: string;
  transaction: Transaction;
  requiredSignatures: string[];
  nextStates: string[];
}

/**
 * Pre-signed transaction stored in the graph
 */
export interface PreSignedTransaction {
  transactionId: string;
  signatures: Map<string, string>;
  rawTransaction: string;
  executionConditions: ExecutionCondition[];
}

/**
 * Conditions for executing a pre-signed transaction
 */
export interface ExecutionCondition {
  type: 'timelock' | 'multisig' | 'hashlock' | 'snark_proof';
  value: any;
  satisfied: boolean;
}

/**
 * Represents the vault state
 */
export interface VaultState {
  totalBTC: number;
  totalUSDT: number;
  lendingPool: Map<string, LendingPosition>;
  collateralRatio: number;
  lastStateRoot: string;
  blockHeight: number;
}

/**
 * Lending position in the vault
 */
export interface LendingPosition {
  lender: string;
  borrower: string;
  amountUSDT: number;
  collateralBTC: number;
  interestRate: number;
  startTime: number;
  duration: number;
  status: 'active' | 'repaid' | 'liquidated';
}

/**
 * Challenge in the dispute resolution system
 */
export interface Challenge {
  id: string;
  challenger: string;
  operator: string;
  disputedTransaction: string;
  proof: string;
  status: 'pending' | 'proved' | 'disproved' | 'timeout';
  timestamp: number;
  deadline: number;
}

/**
 * SNARK proof for state verification
 */
export interface SNARKProof {
  publicInputs: string[];
  proof: {
    a: string[];
    b: string[][];
    c: string[];
  };
  verificationKey: string;
}