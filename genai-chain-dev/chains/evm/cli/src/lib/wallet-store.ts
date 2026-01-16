/**
 * Wallet storage - plaintext JSON for development convenience
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
import {
  generateMnemonic,
  mnemonicToAccount,
  privateKeyToAccount,
  english,
} from 'viem/accounts';
import type { ChainConfig } from './config.js';

export interface StoredWallet {
  name: string;
  address: string;
  privateKey: string;
  mnemonic?: string;
  derivationPath?: string;
  createdAt: string;
}

export interface WalletStoreData {
  version: 1;
  defaultWallet: string | null;
  wallets: StoredWallet[];
}

const DEFAULT_DERIVATION_PATH = "m/44'/60'/0'/0/0";

export class WalletStore {
  private readonly storePath: string;
  private data: WalletStoreData;

  constructor(config: ChainConfig) {
    const configDir = join(homedir(), '.config', config.cliName);
    if (!existsSync(configDir)) {
      mkdirSync(configDir, { recursive: true });
    }
    this.storePath = join(configDir, 'wallets.json');
    this.data = this.load();
  }

  private load(): WalletStoreData {
    if (!existsSync(this.storePath)) {
      return { version: 1, defaultWallet: null, wallets: [] };
    }
    try {
      const content = readFileSync(this.storePath, 'utf-8');
      return JSON.parse(content);
    } catch {
      return { version: 1, defaultWallet: null, wallets: [] };
    }
  }

  private save(): void {
    writeFileSync(this.storePath, JSON.stringify(this.data, null, 2));
  }

  /**
   * Create a new wallet with generated mnemonic
   */
  create(name: string): StoredWallet {
    if (this.get(name)) {
      throw new Error(`Wallet '${name}' already exists`);
    }

    // Generate random 24-word mnemonic
    const mnemonic = generateMnemonic(english, 256);
    const account = mnemonicToAccount(mnemonic, {
      path: DEFAULT_DERIVATION_PATH,
    });

    const storedWallet: StoredWallet = {
      name,
      address: account.address,
      privateKey: account.getHdKey().privateKey
        ? `0x${Buffer.from(account.getHdKey().privateKey!).toString('hex')}`
        : '',
      mnemonic,
      derivationPath: DEFAULT_DERIVATION_PATH,
      createdAt: new Date().toISOString(),
    };

    this.data.wallets.push(storedWallet);

    // Set as default if first wallet
    if (this.data.wallets.length === 1) {
      this.data.defaultWallet = name;
    }

    this.save();
    return storedWallet;
  }

  /**
   * Import wallet from mnemonic or private key
   */
  import(name: string, secret: string): StoredWallet {
    if (this.get(name)) {
      throw new Error(`Wallet '${name}' already exists`);
    }

    let address: string;
    let privateKey: string;
    let mnemonic: string | undefined;
    let derivationPath: string | undefined;

    // Determine if secret is mnemonic or private key
    const words = secret.trim().split(/\s+/);
    if (words.length >= 12) {
      // Mnemonic phrase
      const account = mnemonicToAccount(secret.trim(), {
        path: DEFAULT_DERIVATION_PATH,
      });
      address = account.address;
      privateKey = account.getHdKey().privateKey
        ? `0x${Buffer.from(account.getHdKey().privateKey!).toString('hex')}`
        : '';
      mnemonic = secret.trim();
      derivationPath = DEFAULT_DERIVATION_PATH;
    } else {
      // Private key
      const key = (secret.startsWith('0x') ? secret : `0x${secret}`) as `0x${string}`;
      const account = privateKeyToAccount(key);
      address = account.address;
      privateKey = key;
    }

    const storedWallet: StoredWallet = {
      name,
      address,
      privateKey,
      mnemonic,
      derivationPath,
      createdAt: new Date().toISOString(),
    };

    this.data.wallets.push(storedWallet);

    // Set as default if first wallet
    if (this.data.wallets.length === 1) {
      this.data.defaultWallet = name;
    }

    this.save();
    return storedWallet;
  }

  /**
   * Get wallet by name
   */
  get(name: string): StoredWallet | undefined {
    return this.data.wallets.find((w) => w.name === name);
  }

  /**
   * Get default wallet
   */
  getDefault(): StoredWallet | undefined {
    if (!this.data.defaultWallet) return undefined;
    return this.get(this.data.defaultWallet);
  }

  /**
   * Get wallet by name or default
   */
  getOrDefault(name?: string): StoredWallet {
    const wallet = name ? this.get(name) : this.getDefault();
    if (!wallet) {
      throw new Error(name ? `Wallet '${name}' not found` : 'No default wallet set');
    }
    return wallet;
  }

  /**
   * List all wallets
   */
  list(): StoredWallet[] {
    return this.data.wallets;
  }

  /**
   * Remove a wallet
   */
  remove(name: string): void {
    const index = this.data.wallets.findIndex((w) => w.name === name);
    if (index === -1) {
      throw new Error(`Wallet '${name}' not found`);
    }
    this.data.wallets.splice(index, 1);

    // Clear default if removed
    if (this.data.defaultWallet === name) {
      this.data.defaultWallet = this.data.wallets[0]?.name || null;
    }

    this.save();
  }

  /**
   * Set default wallet
   */
  setDefault(name: string): void {
    if (!this.get(name)) {
      throw new Error(`Wallet '${name}' not found`);
    }
    this.data.defaultWallet = name;
    this.save();
  }

  /**
   * Get default wallet name
   */
  getDefaultName(): string | null {
    return this.data.defaultWallet;
  }
}
