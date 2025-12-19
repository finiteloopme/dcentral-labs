/**
 * Core type definitions for Midnight CLI
 * 
 * These types are used throughout the wallet and contract commands.
 */

/**
 * Supported Midnight network identifiers
 */
export const NetworkId = {
  MainNet: 'mainnet',
  TestNet: 'testnet',
  DevNet: 'devnet',
  QaNet: 'qanet',
  Undeployed: 'undeployed',
  Preview: 'preview',
  PreProd: 'preprod',
  Standalone: 'standalone',
} as const;

export type NetworkId = typeof NetworkId[keyof typeof NetworkId];

/**
 * Check if a string is a valid NetworkId
 */
export function isValidNetworkId(value: string): value is NetworkId {
  return Object.values(NetworkId).includes(value as NetworkId);
}

/**
 * Networks that support funding from genesis wallets
 */
export const FUNDABLE_NETWORKS: readonly NetworkId[] = [
  NetworkId.Standalone,
  NetworkId.DevNet,
  NetworkId.Undeployed,
] as const;

/**
 * Genesis wallet configurations for fundable networks
 */
export const GENESIS_WALLETS = [
  { seed: '0000000000000000000000000000000000000000000000000000000000000001', name: 'Genesis #1' },
  { seed: '0000000000000000000000000000000000000000000000000000000000000002', name: 'Genesis #2' },
  { seed: '0000000000000000000000000000000000000000000000000000000000000003', name: 'Genesis #3' },
  { seed: '0000000000000000000000000000000000000000000000000000000000000004', name: 'Genesis #4' },
] as const;

/**
 * Stored wallet metadata
 */
export interface StoredWallet {
  name: string;
  createdAt: string;
  network: NetworkId;
  seed: string;  // Hex-encoded (plaintext for now)
  addresses: {
    unshielded: string;
    shielded?: string;
    dust?: string;  // DUST token address for fee resource
    coinPublicKey: string;
  };
}

/**
 * Wallet store structure persisted to .private/wallets/wallets.json
 */
export interface WalletStore {
  version: number;
  default?: string;  // Default wallet name
  wallets: Record<string, StoredWallet>;
}

/**
 * Contract metadata stored in .private/contracts/<address>/
 */
export interface ContractMetadata {
  contractAddress: string;
  deployedAt: string;
  contractPath: string;  // Original path used during deploy
  network: NetworkId;
  deployTxHash: string;
  circuits: string[];
}

/**
 * Witness information extracted from contract-info.json
 */
export interface WitnessInfo {
  name: string;
  modifiesPrivateState: boolean;
  arguments: Array<{ name: string; type: string }>;
  returnType?: string;
}

/**
 * Service URLs configuration
 */
export interface ServiceUrls {
  nodeUrl: string | undefined;
  nodeWsUrl: string | undefined;
  indexerUrl: string | undefined;
  indexerWsUrl: string | undefined;
  proofServerUrl: string | undefined;
}

/**
 * Result of network detection
 */
export interface NetworkDetectionResult {
  network: NetworkId;
  source: 'env' | 'node' | 'url-pattern' | 'default';
  confidence: 'high' | 'medium' | 'low';
}
