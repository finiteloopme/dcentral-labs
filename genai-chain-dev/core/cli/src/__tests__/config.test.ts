import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { loadChainConfig, getConfigDir, getDataDir } from '../utils/config.js';
import { existsSync, mkdirSync, readFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir, homedir } from 'node:os';

describe('config', () => {
  const originalEnv = { ...process.env };

  afterEach(() => {
    process.env = { ...originalEnv };
  });

  describe('loadChainConfig', () => {
    it('should load config from environment variables', () => {
      process.env.CLI_NAME = 'testctl';
      process.env.CHAIN_NAME = 'TestChain';
      process.env.CHAIN_ID = '12345';
      process.env.RPC_URL = 'https://rpc.test.com';
      process.env.EXPLORER_URL = 'https://explorer.test.com';
      process.env.NATIVE_CURRENCY = 'TEST';
      process.env.NATIVE_DECIMALS = '18';
      // Ensure no config file is read
      process.env.CHAIN_CONFIG_DIR = '/nonexistent';

      const config = loadChainConfig();

      expect(config.cliName).toBe('testctl');
      expect(config.chainName).toBe('TestChain');
      expect(config.chainId).toBe(12345);
      expect(config.rpcUrl).toBe('https://rpc.test.com');
      expect(config.explorerUrl).toBe('https://explorer.test.com');
      expect(config.nativeCurrency).toBe('TEST');
      expect(config.nativeDecimals).toBe(18);
    });

    it('should use defaults when env vars not set', () => {
      process.env = {};
      process.env.CHAIN_CONFIG_DIR = '/nonexistent';

      const config = loadChainConfig();

      expect(config.cliName).toBe('evmctl');
      expect(config.chainName).toBe('EVM');
      expect(config.chainId).toBe(1);
      expect(config.rpcUrl).toBe('http://localhost:8545');
      expect(config.nativeCurrency).toBe('ETH');
      expect(config.nativeDecimals).toBe(18);
    });
  });

  describe('getConfigDir', () => {
    it('should return path in home directory', () => {
      const dir = getConfigDir('testcli');
      expect(dir).toContain('.config');
      expect(dir).toContain('testcli');
    });
  });

  describe('getDataDir', () => {
    it('should return path in home directory', () => {
      const dir = getDataDir('testcli');
      expect(dir).toContain('.local');
      expect(dir).toContain('share');
      expect(dir).toContain('testcli');
    });
  });
});
