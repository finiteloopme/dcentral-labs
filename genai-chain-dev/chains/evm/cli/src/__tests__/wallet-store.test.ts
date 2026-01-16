import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { WalletStore } from '../lib/wallet-store.js';
import { rmSync, existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

// Mock homedir to return a test-specific directory
vi.mock('node:os', async () => {
  const actual = await vi.importActual<typeof import('node:os')>('node:os');
  return {
    ...actual,
    homedir: () => process.env.TEST_HOME_DIR || actual.homedir(),
  };
});

describe('WalletStore', () => {
  let testDir: string;
  const testConfig = {
    cliName: 'test-cli',
    chainName: 'Test',
    chainId: 1,
    rpcUrl: 'http://localhost:8545',
    nativeCurrency: 'ETH',
    nativeDecimals: 18,
  };

  beforeEach(() => {
    // Create unique test directory for each test
    testDir = join(tmpdir(), 'wallet-store-test-' + Date.now() + '-' + Math.random().toString(36).slice(2));
    process.env.TEST_HOME_DIR = testDir;
    mkdirSync(testDir, { recursive: true });
  });

  afterEach(() => {
    // Cleanup
    if (existsSync(testDir)) {
      rmSync(testDir, { recursive: true, force: true });
    }
    delete process.env.TEST_HOME_DIR;
  });

  describe('create', () => {
    it('should create a new wallet with mnemonic', () => {
      const store = new WalletStore(testConfig);
      const wallet = store.create('test-wallet');

      expect(wallet.name).toBe('test-wallet');
      expect(wallet.address).toMatch(/^0x[a-fA-F0-9]{40}$/);
      expect(wallet.mnemonic).toBeDefined();
      expect(wallet.mnemonic?.split(' ').length).toBeGreaterThanOrEqual(12);
      expect(wallet.privateKey).toMatch(/^0x[a-fA-F0-9]{64}$/);
    });

    it('should throw if wallet already exists', () => {
      const store = new WalletStore(testConfig);
      store.create('test-wallet');

      expect(() => store.create('test-wallet')).toThrow("Wallet 'test-wallet' already exists");
    });

    it('should set first wallet as default', () => {
      const store = new WalletStore(testConfig);
      store.create('first-wallet');

      expect(store.getDefaultName()).toBe('first-wallet');
    });
  });

  describe('import', () => {
    const testMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const testPrivateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

    it('should import wallet from mnemonic', () => {
      const store = new WalletStore(testConfig);
      const wallet = store.import('imported', testMnemonic);

      expect(wallet.name).toBe('imported');
      expect(wallet.address).toMatch(/^0x[a-fA-F0-9]{40}$/);
      expect(wallet.mnemonic).toBe(testMnemonic);
    });

    it('should import wallet from private key', () => {
      const store = new WalletStore(testConfig);
      const wallet = store.import('imported', testPrivateKey);

      expect(wallet.name).toBe('imported');
      expect(wallet.address).toMatch(/^0x[a-fA-F0-9]{40}$/);
      expect(wallet.mnemonic).toBeUndefined();
      expect(wallet.privateKey).toBe(testPrivateKey);
    });
  });

  describe('list', () => {
    it('should return empty array when no wallets', () => {
      const store = new WalletStore(testConfig);
      expect(store.list()).toEqual([]);
    });

    it('should return all wallets', () => {
      const store = new WalletStore(testConfig);
      store.create('wallet1');
      store.create('wallet2');

      const wallets = store.list();
      expect(wallets.length).toBe(2);
      expect(wallets.map(w => w.name)).toContain('wallet1');
      expect(wallets.map(w => w.name)).toContain('wallet2');
    });
  });

  describe('remove', () => {
    it('should remove a wallet', () => {
      const store = new WalletStore(testConfig);
      store.create('to-remove');
      store.remove('to-remove');

      expect(store.get('to-remove')).toBeUndefined();
    });

    it('should throw if wallet does not exist', () => {
      const store = new WalletStore(testConfig);
      expect(() => store.remove('nonexistent')).toThrow("Wallet 'nonexistent' not found");
    });
  });

  describe('setDefault', () => {
    it('should set default wallet', () => {
      const store = new WalletStore(testConfig);
      store.create('wallet1');
      store.create('wallet2');
      store.setDefault('wallet2');

      expect(store.getDefaultName()).toBe('wallet2');
    });

    it('should throw if wallet does not exist', () => {
      const store = new WalletStore(testConfig);
      expect(() => store.setDefault('nonexistent')).toThrow("Wallet 'nonexistent' not found");
    });
  });
});
