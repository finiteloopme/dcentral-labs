import type { Address, Hex } from 'viem';

/**
 * Wallet context passed from OpenCode to agents via A2A message metadata.
 * 
 * Note: Private keys are NEVER passed. The agent returns unsigned transactions
 * which are then signed by the user's wallet (injected provider).
 */
export interface WalletContext {
  /** The connected wallet address */
  address: Address;
  
  /** The chain ID the wallet is connected to */
  chainId: number;
  
  /** Whether the wallet is currently connected */
  connected: boolean;
}

/**
 * Unsigned transaction to be signed by user's wallet
 */
export interface UnsignedTransaction {
  /** Transaction recipient */
  to?: Address;
  
  /** Value in wei */
  value?: bigint;
  
  /** Transaction data (for contract interactions) */
  data?: Hex;
  
  /** Gas limit */
  gas?: bigint;
  
  /** Max fee per gas (EIP-1559) */
  maxFeePerGas?: bigint;
  
  /** Max priority fee per gas (EIP-1559) */
  maxPriorityFeePerGas?: bigint;
  
  /** Nonce (optional, can be auto-filled) */
  nonce?: number;
  
  /** Chain ID */
  chainId: number;
}

/**
 * Contract deployment transaction data
 */
export interface DeployTransaction extends UnsignedTransaction {
  /** Contract bytecode */
  data: Hex;
  
  /** Constructor arguments (ABI-encoded) */
  constructorArgs?: Hex;
}

/**
 * Response from agent when deployment is requested
 */
export interface DeploymentResponse {
  /** The unsigned transaction for the user to sign */
  unsignedTransaction: UnsignedTransaction;
  
  /** Human-readable description */
  description: string;
  
  /** Estimated gas cost in native currency */
  estimatedCost?: string;
  
  /** Contract ABI for verification */
  abi?: unknown[];
  
  /** Source code for verification */
  sourceCode?: string;
}
