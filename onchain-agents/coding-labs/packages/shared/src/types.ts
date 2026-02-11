/**
 * Network configuration for blockchain chains
 */
export interface NetworkConfig {
  chainId: number;
  name: string;
  rpcUrl: string;
  explorerUrl: string;
  nativeCurrency: {
    name: string;
    symbol: string;
    decimals: number;
  };
}

/**
 * Somnia network configurations
 */
export const SOMNIA_MAINNET: NetworkConfig = {
  chainId: 5031,
  name: 'Somnia Mainnet',
  rpcUrl: 'https://api.infra.mainnet.somnia.network/',
  explorerUrl: 'https://explorer.somnia.network',
  nativeCurrency: {
    name: 'SOMI',
    symbol: 'SOMI',
    decimals: 18,
  },
};

export const SOMNIA_TESTNET: NetworkConfig = {
  chainId: 50312,
  name: 'Somnia Testnet (Shannon)',
  rpcUrl: 'https://dream-rpc.somnia.network/',
  explorerUrl: 'https://shannon-explorer.somnia.network',
  nativeCurrency: {
    name: 'STT',
    symbol: 'STT',
    decimals: 18,
  },
};

/**
 * A2A Message metadata for wallet context
 */
export interface WalletMetadata {
  wallet?: {
    address: string;
    chainId: number;
    connected: boolean;
  };
  network?: 'mainnet' | 'testnet';
}

/**
 * Skill execution result
 */
export interface SkillResult {
  success: boolean;
  data?: unknown;
  error?: string;
  artifacts?: Array<{
    name: string;
    content: string;
    mimeType?: string;
  }>;
}

/**
 * Contract deployment result
 */
export interface DeploymentResult {
  contractAddress: string;
  transactionHash: string;
  blockNumber: number;
  gasUsed: bigint;
}

/**
 * Transaction status result
 */
export interface TransactionStatus {
  hash: string;
  status: 'pending' | 'success' | 'failed';
  blockNumber?: number;
  gasUsed?: bigint;
  from: string;
  to?: string;
  logs?: Array<{
    address: string;
    topics: string[];
    data: string;
  }>;
}
