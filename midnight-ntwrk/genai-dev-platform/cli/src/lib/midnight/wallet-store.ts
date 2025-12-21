/**
 * Wallet storage manager for .private/wallets/
 * 
 * Stores wallet metadata and seeds at the project level.
 * Seeds are stored in plaintext for now (encryption to be added later).
 */

import * as fs from 'fs';
import * as path from 'path';
import { type StoredWallet, type WalletStore, type NetworkId } from './types.js';
import { generateMnemonic, mnemonicToHexSeed, validateHexSeed, normalizeHexSeed } from './mnemonic.js';
import { detectNetwork, normalizeNetworkForAddresses } from './network.js';
import { createToolkit, isToolkitAvailable } from './toolkit.js';

/**
 * Error message for when toolkit is not available
 */
const TOOLKIT_INSTALL_INSTRUCTIONS = `
Wallet creation requires the midnight-node-toolkit binary.

To install the toolkit:

  1. Pull the toolkit Docker image:
     docker pull midnightntwrk/midnight-node-toolkit:0.18.0

  2. Extract the binary:
     docker run --rm -v /usr/local/bin:/out midnightntwrk/midnight-node-toolkit:0.18.0 \\
       cp /usr/bin/midnight-node-toolkit /out/

  Or set MIDNIGHT_TOOLKIT_PATH environment variable to point to an existing binary.
`.trim();

const WALLET_STORE_VERSION = 1;
const PRIVATE_DIR = '.private';
const WALLETS_DIR = 'wallets';
const WALLETS_FILE = 'wallets.json';

/**
 * Find the project root by looking for common project markers
 */
export function findProjectRoot(startDir: string = process.cwd()): string {
  let currentDir = startDir;
  
  // Look for project markers
  const markers = ['package.json', '.env', 'contracts', '.private'];
  
  while (currentDir !== path.dirname(currentDir)) {
    for (const marker of markers) {
      if (fs.existsSync(path.join(currentDir, marker))) {
        return currentDir;
      }
    }
    currentDir = path.dirname(currentDir);
  }
  
  // Fall back to current directory
  return startDir;
}

/**
 * Wallet manager for project-level wallet storage
 */
export class WalletManager {
  private projectRoot: string;
  private storePath: string;
  private storeDir: string;
  
  constructor(projectRoot?: string) {
    this.projectRoot = projectRoot || findProjectRoot();
    this.storeDir = path.join(this.projectRoot, PRIVATE_DIR, WALLETS_DIR);
    this.storePath = path.join(this.storeDir, WALLETS_FILE);
  }
  
  /**
   * Ensure the .private/wallets directory exists
   */
  private ensureStoreDir(): void {
    if (!fs.existsSync(this.storeDir)) {
      fs.mkdirSync(this.storeDir, { recursive: true });
    }
  }
  
  /**
   * Load the wallet store from disk
   */
  private loadStore(): WalletStore {
    this.ensureStoreDir();
    
    if (!fs.existsSync(this.storePath)) {
      return {
        version: WALLET_STORE_VERSION,
        wallets: {},
      };
    }
    
    try {
      const data = fs.readFileSync(this.storePath, 'utf-8');
      const store = JSON.parse(data) as WalletStore;
      
      // Validate version
      if (store.version !== WALLET_STORE_VERSION) {
        // Future: handle migrations
        console.warn(`Wallet store version mismatch: ${store.version} vs ${WALLET_STORE_VERSION}`);
      }
      
      return store;
    } catch (error) {
      throw new Error(`Failed to load wallet store: ${error instanceof Error ? error.message : 'unknown error'}`);
    }
  }
  
  /**
   * Save the wallet store to disk
   */
  private saveStore(store: WalletStore): void {
    this.ensureStoreDir();
    fs.writeFileSync(this.storePath, JSON.stringify(store, null, 2), 'utf-8');
  }
  
  /**
   * Create a new wallet from a mnemonic
   * 
   * Requires the midnight-node-toolkit binary to be installed for address derivation.
   * 
   * @param name - Wallet name
   * @param options - Creation options
   * @returns Created wallet and mnemonic words
   */
  async create(
    name: string,
    options: {
      wordCount?: 12 | 24;
      setDefault?: boolean;
    } = {}
  ): Promise<{ wallet: StoredWallet; mnemonic: string[] }> {
    // Check toolkit availability first
    if (!(await isToolkitAvailable())) {
      throw new Error(TOOLKIT_INSTALL_INSTRUCTIONS);
    }
    
    const store = this.loadStore();
    
    // Check if wallet already exists
    if (store.wallets[name]) {
      throw new Error(`Wallet "${name}" already exists`);
    }
    
    // Generate mnemonic
    const strength = options.wordCount === 12 ? 128 : 256;
    const mnemonic = generateMnemonic(strength);
    
    // Derive seed from mnemonic
    const seed = mnemonicToHexSeed(mnemonic);
    
    // Detect network
    const networkResult = await detectNetwork();
    const network = networkResult.network;
    
    // Normalize network for address encoding
    // This ensures addresses match what the toolkit/chain expects
    // (e.g., 'standalone' -> 'undeployed')
    const addressNetwork = normalizeNetworkForAddresses(network);
    
    // Use toolkit to derive real addresses
    const toolkit = createToolkit({ network: addressNetwork });
    const derivedAddresses = await toolkit.getAddresses(seed);
    
    // Create wallet record with toolkit-derived addresses
    // Note: Toolkit uses seed directly (legacy derivation), not HD wallet derivation
    const wallet: StoredWallet = {
      name,
      createdAt: new Date().toISOString(),
      network: addressNetwork,
      seed,
      addresses: {
        unshielded: derivedAddresses.unshielded,
        shielded: derivedAddresses.shielded || undefined,
        dust: derivedAddresses.dust || undefined,
        coinPublicKey: seed, // Keep seed as reference (actual coinPublicKey would require SDK)
      },
    };
    
    // Store wallet
    store.wallets[name] = wallet;
    
    // Set as default if requested or if it's the first wallet
    if (options.setDefault || Object.keys(store.wallets).length === 1) {
      store.default = name;
    }
    
    this.saveStore(store);
    
    return { wallet, mnemonic };
  }
  
  /**
   * Import a wallet from a hex seed
   * 
   * Requires the midnight-node-toolkit binary to be installed for address derivation.
   * 
   * @param name - Wallet name
   * @param seed - Hex-encoded seed
   * @param options - Import options
   * @returns Imported wallet
   */
  async importFromSeed(
    name: string,
    seed: string,
    options: { setDefault?: boolean } = {}
  ): Promise<StoredWallet> {
    // Check toolkit availability first
    if (!(await isToolkitAvailable())) {
      throw new Error(TOOLKIT_INSTALL_INSTRUCTIONS);
    }
    
    // Validate seed
    const validation = validateHexSeed(seed);
    if (!validation.valid) {
      throw new Error(validation.error);
    }
    
    const normalizedSeed = normalizeHexSeed(seed);
    const store = this.loadStore();
    
    // Check if wallet already exists
    if (store.wallets[name]) {
      throw new Error(`Wallet "${name}" already exists`);
    }
    
    // Detect network
    const networkResult = await detectNetwork();
    const network = networkResult.network;
    
    // Normalize network for address encoding
    const addressNetwork = normalizeNetworkForAddresses(network);
    
    // Use toolkit to derive real addresses
    const toolkit = createToolkit({ network: addressNetwork });
    const derivedAddresses = await toolkit.getAddresses(normalizedSeed);
    
    // Create wallet record with toolkit-derived addresses
    // Note: Both SDK and toolkit use identical BIP44 HD derivation paths
    const wallet: StoredWallet = {
      name,
      createdAt: new Date().toISOString(),
      network: addressNetwork,
      seed: normalizedSeed,
      addresses: {
        unshielded: derivedAddresses.unshielded,
        shielded: derivedAddresses.shielded || undefined,
        dust: derivedAddresses.dust || undefined,
        coinPublicKey: normalizedSeed,
      },
    };
    
    // Store wallet
    store.wallets[name] = wallet;
    
    // Set as default if requested or if it's the first wallet
    if (options.setDefault || Object.keys(store.wallets).length === 1) {
      store.default = name;
    }
    
    this.saveStore(store);
    
    return wallet;
  }
  
  /**
   * Import a wallet from a mnemonic
   * 
   * @param name - Wallet name
   * @param mnemonic - Mnemonic words (array or space-separated string)
   * @param options - Import options
   * @returns Imported wallet
   */
  async importFromMnemonic(
    name: string,
    mnemonic: string[] | string,
    options: { setDefault?: boolean; passphrase?: string } = {}
  ): Promise<StoredWallet> {
    // Convert mnemonic to seed
    const seed = mnemonicToHexSeed(mnemonic, options.passphrase);
    return this.importFromSeed(name, seed, options);
  }
  
  /**
   * Get a wallet by name
   */
  get(name: string): StoredWallet | null {
    const store = this.loadStore();
    return store.wallets[name] || null;
  }
  
  /**
   * Get the default wallet
   */
  getDefault(): StoredWallet | null {
    const store = this.loadStore();
    
    // If default is set, use it
    if (store.default && store.wallets[store.default]) {
      return store.wallets[store.default];
    }
    
    // If only one wallet exists, use it
    const walletNames = Object.keys(store.wallets);
    if (walletNames.length === 1) {
      return store.wallets[walletNames[0]];
    }
    
    return null;
  }
  
  /**
   * List all wallets
   */
  list(): StoredWallet[] {
    const store = this.loadStore();
    return Object.values(store.wallets);
  }
  
  /**
   * Check if any wallets exist
   */
  hasWallets(): boolean {
    const store = this.loadStore();
    return Object.keys(store.wallets).length > 0;
  }
  
  /**
   * Get the default wallet name
   */
  getDefaultName(): string | null {
    const store = this.loadStore();
    
    if (store.default) return store.default;
    
    const walletNames = Object.keys(store.wallets);
    if (walletNames.length === 1) return walletNames[0];
    
    return null;
  }
  
  /**
   * Set the default wallet
   */
  setDefault(name: string): void {
    const store = this.loadStore();
    
    if (!store.wallets[name]) {
      throw new Error(`Wallet "${name}" does not exist`);
    }
    
    store.default = name;
    this.saveStore(store);
  }
  
  /**
   * Remove a wallet
   */
  remove(name: string): void {
    const store = this.loadStore();
    
    if (!store.wallets[name]) {
      throw new Error(`Wallet "${name}" does not exist`);
    }
    
    delete store.wallets[name];
    
    // Clear default if it was the removed wallet
    if (store.default === name) {
      const remaining = Object.keys(store.wallets);
      store.default = remaining.length === 1 ? remaining[0] : undefined;
    }
    
    this.saveStore(store);
  }
  
  /**
   * Get or create a default wallet
   * If no wallets exist, creates one named "default"
   */
  async getOrCreateDefault(): Promise<{ wallet: StoredWallet; created: boolean; mnemonic?: string[] }> {
    // Check if we have any wallets
    if (this.hasWallets()) {
      const wallet = this.getDefault();
      if (wallet) {
        return { wallet, created: false };
      }
      
      // Multiple wallets, none default - can't auto-select
      throw new Error('Multiple wallets exist. Specify --wallet or set a default with `midnightctl wallet set-default <name>`');
    }
    
    // No wallets - create default
    const { wallet, mnemonic } = await this.create('default', { setDefault: true });
    return { wallet, created: true, mnemonic };
  }
  
  /**
   * Resolve a wallet by name or get default
   * 
   * @param name - Wallet name (optional, uses default if not provided)
   * @param autoCreate - If true, creates default wallet if none exist
   */
  async resolve(name?: string, autoCreate: boolean = true): Promise<StoredWallet> {
    if (name) {
      const wallet = this.get(name);
      if (!wallet) {
        throw new Error(`Wallet "${name}" not found. Run \`midnightctl wallet list\` to see available wallets.`);
      }
      return wallet;
    }
    
    if (autoCreate) {
      const result = await this.getOrCreateDefault();
      return result.wallet;
    }
    
    const wallet = this.getDefault();
    if (!wallet) {
      throw new Error('No default wallet. Specify --wallet or create one with `midnightctl wallet create <name>`');
    }
    
    return wallet;
  }
  
  /**
   * Get the project root directory
   */
  getProjectRoot(): string {
    return this.projectRoot;
  }
  
  /**
   * Get the private directory path
   */
  getPrivateDir(): string {
    return path.join(this.projectRoot, PRIVATE_DIR);
  }
}

/**
 * Default wallet manager instance
 */
let defaultManager: WalletManager | null = null;

/**
 * Get the default wallet manager
 */
export function getWalletManager(): WalletManager {
  if (!defaultManager) {
    defaultManager = new WalletManager();
  }
  return defaultManager;
}
