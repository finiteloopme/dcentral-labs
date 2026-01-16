/**
 * Chain adapter interface - implemented by each chain type (EVM, Midnight, etc.)
 */

import type { WalletAdapter } from './wallet.js';
import type { ContractAdapter } from './contract.js';

/**
 * Network configuration
 */
export interface NetworkConfig {
  /** Network identifier (e.g., "testnet", "mainnet") */
  id: string;
  /** Display name (e.g., "Somnia Testnet") */
  name: string;
  /** RPC endpoint URL */
  rpcUrl: string;
  /** Chain ID */
  chainId: number;
  /** Block explorer URL */
  explorerUrl?: string;
  /** Faucet URL (for testnets) */
  faucetUrl?: string;
  /** Whether this is a testnet */
  isTestnet: boolean;
  /** Whether this is the default network */
  isDefault?: boolean;
  /** Whether this is a local network (e.g., Anvil) */
  isLocal?: boolean;
}

/**
 * Node adapter interface for local development nodes
 */
export interface NodeAdapter {
  /** Start local node */
  start(options?: NodeOptions): Promise<void>;
  /** Stop local node */
  stop(): Promise<void>;
  /** Get node status */
  status(): Promise<NodeStatus>;
  /** Get node logs */
  logs(lines?: number): Promise<string>;
}

export interface NodeOptions {
  /** Port to listen on */
  port?: number;
  /** Number of accounts to create */
  accounts?: number;
  /** Balance per account (in native token) */
  balance?: string;
  /** Block time in seconds (0 = instant mining) */
  blockTime?: number;
  /** Fork from RPC URL */
  forkUrl?: string;
  /** Fork at specific block number */
  forkBlockNumber?: number;
}

export interface NodeStatus {
  /** Whether node is running */
  running: boolean;
  /** PID if running */
  pid?: number;
  /** Port if running */
  port?: number;
  /** RPC URL if running */
  rpcUrl?: string;
}

/**
 * Main chain adapter interface
 */
export interface ChainAdapter {
  /** Chain type identifier (e.g., "evm", "midnight") */
  readonly id: string;
  
  /** Display name (e.g., "Somnia", "Midnight") */
  readonly displayName: string;
  
  /** Wallet operations */
  readonly wallet: WalletAdapter;
  
  /** Contract operations */
  readonly contract: ContractAdapter;
  
  /** Local node operations (optional) */
  readonly node?: NodeAdapter;
  
  /** Available networks */
  readonly networks: NetworkConfig[];
  
  /** Get current network configuration */
  getCurrentNetwork(): NetworkConfig;
  
  /** Set current network */
  setCurrentNetwork(networkId: string): void;
}
