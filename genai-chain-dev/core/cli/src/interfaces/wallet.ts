/**
 * Wallet adapter interface - implemented by chain-specific wallet handlers
 */

/**
 * Result from wallet creation
 */
export interface WalletResult {
  /** Wallet name */
  name: string;
  /** Primary address */
  address: string;
  /** BIP39 mnemonic (if generated) */
  mnemonic?: string;
  /** Derivation path used */
  derivationPath?: string;
}

/**
 * Wallet information (for listing)
 */
export interface WalletInfo {
  /** Wallet name */
  name: string;
  /** Primary address */
  address: string;
  /** Whether this is the default wallet */
  isDefault: boolean;
  /** When the wallet was created */
  createdAt: string;
}

/**
 * Balance result
 */
export interface BalanceResult {
  /** Wallet name */
  name: string;
  /** Wallet address */
  address: string;
  /** Native token balance */
  balance: string;
  /** Native token symbol */
  symbol: string;
  /** Formatted balance with symbol */
  formatted: string;
}

/**
 * Transaction result
 */
export interface TxResult {
  /** Transaction hash */
  hash: string;
  /** From address */
  from: string;
  /** To address */
  to: string;
  /** Amount sent */
  amount: string;
  /** Block number (if confirmed) */
  blockNumber?: number;
  /** Transaction status */
  status: 'pending' | 'confirmed' | 'failed';
  /** Explorer URL for transaction */
  explorerUrl?: string;
}

/**
 * Send options
 */
export interface SendOptions {
  /** Gas limit override */
  gasLimit?: bigint;
  /** Gas price override */
  gasPrice?: bigint;
  /** Max fee per gas (EIP-1559) */
  maxFeePerGas?: bigint;
  /** Max priority fee per gas (EIP-1559) */
  maxPriorityFeePerGas?: bigint;
  /** Nonce override */
  nonce?: number;
}

/**
 * Wallet adapter interface
 */
export interface WalletAdapter {
  /**
   * Create a new wallet with generated mnemonic
   * @param name - Wallet name
   */
  create(name: string): Promise<WalletResult>;
  
  /**
   * Import wallet from mnemonic or private key
   * @param name - Wallet name
   * @param secret - Mnemonic phrase or private key
   */
  import(name: string, secret: string): Promise<WalletResult>;
  
  /**
   * List all wallets
   */
  list(): Promise<WalletInfo[]>;
  
  /**
   * Get wallet balance
   * @param name - Wallet name (uses default if not specified)
   */
  balance(name?: string): Promise<BalanceResult>;
  
  /**
   * Send native tokens
   * @param to - Destination address
   * @param amount - Amount to send (in human-readable format, e.g., "1.5")
   * @param options - Optional transaction parameters
   */
  send(to: string, amount: string, options?: SendOptions): Promise<TxResult>;
  
  /**
   * Get wallet address
   * @param name - Wallet name (uses default if not specified)
   */
  address(name?: string): Promise<string>;
  
  /**
   * Remove a wallet
   * @param name - Wallet name
   */
  remove(name: string): Promise<void>;
  
  /**
   * Set default wallet
   * @param name - Wallet name
   */
  setDefault(name: string): Promise<void>;
  
  /**
   * Get default wallet name
   */
  getDefault(): Promise<string | null>;
  
  /**
   * Export wallet private key (for use with other tools)
   * @param name - Wallet name
   */
  exportPrivateKey(name: string): Promise<string>;
}
