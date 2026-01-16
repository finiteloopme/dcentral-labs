/**
 * Configuration management utilities
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { homedir } from 'node:os';

/**
 * Chain configuration (from environment/config file)
 */
export interface ChainConfig {
  cliName: string;
  chainName: string;
  chainId: number;
  rpcUrl: string;
  explorerUrl?: string;
  faucetUrl?: string;
  nativeCurrency: string;
  nativeDecimals: number;
}

/**
 * Get configuration directory for a CLI
 */
export function getConfigDir(cliName: string): string {
  const configDir = join(homedir(), '.config', cliName);
  if (!existsSync(configDir)) {
    mkdirSync(configDir, { recursive: true });
  }
  return configDir;
}

/**
 * Get data directory for a CLI
 */
export function getDataDir(cliName: string): string {
  const dataDir = join(homedir(), '.local', 'share', cliName);
  if (!existsSync(dataDir)) {
    mkdirSync(dataDir, { recursive: true });
  }
  return dataDir;
}

/**
 * Load chain configuration from environment
 */
export function loadChainConfig(): ChainConfig {
  const chainConfigDir = process.env.CHAIN_CONFIG_DIR || '/etc/chain';
  const configPath = join(chainConfigDir, 'config.env');
  
  // Try loading from config file
  if (existsSync(configPath)) {
    const content = readFileSync(configPath, 'utf-8');
    const config = parseEnvFile(content);
    return {
      cliName: config.CLI_NAME || 'evmctl',
      chainName: config.CHAIN_NAME || 'EVM',
      chainId: parseInt(config.CHAIN_ID || '1', 10),
      rpcUrl: config.RPC_URL || 'http://localhost:8545',
      explorerUrl: config.EXPLORER_URL || undefined,
      faucetUrl: config.FAUCET_URL || undefined,
      nativeCurrency: config.NATIVE_CURRENCY || 'ETH',
      nativeDecimals: parseInt(config.NATIVE_DECIMALS || '18', 10),
    };
  }
  
  // Fall back to environment variables
  return {
    cliName: process.env.CLI_NAME || 'evmctl',
    chainName: process.env.CHAIN_NAME || 'EVM',
    chainId: parseInt(process.env.CHAIN_ID || '1', 10),
    rpcUrl: process.env.RPC_URL || 'http://localhost:8545',
    explorerUrl: process.env.EXPLORER_URL || undefined,
    faucetUrl: process.env.FAUCET_URL || undefined,
    nativeCurrency: process.env.NATIVE_CURRENCY || 'ETH',
    nativeDecimals: parseInt(process.env.NATIVE_DECIMALS || '18', 10),
  };
}

/**
 * Parse an env file into a record
 */
function parseEnvFile(content: string): Record<string, string> {
  const result: Record<string, string> = {};
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const [key, ...valueParts] = trimmed.split('=');
    if (key && valueParts.length > 0) {
      result[key.trim()] = valueParts.join('=').trim();
    }
  }
  return result;
}

/**
 * Load JSON config file
 */
export function loadJsonConfig<T>(filePath: string, defaults: T): T {
  if (!existsSync(filePath)) {
    return defaults;
  }
  try {
    const content = readFileSync(filePath, 'utf-8');
    return { ...defaults, ...JSON.parse(content) };
  } catch {
    return defaults;
  }
}

/**
 * Save JSON config file
 */
export function saveJsonConfig<T>(filePath: string, config: T): void {
  const dir = dirname(filePath);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  writeFileSync(filePath, JSON.stringify(config, null, 2));
}

/**
 * Get current network from config
 */
export function getCurrentNetwork(cliName: string): string {
  const configDir = getConfigDir(cliName);
  const networkFile = join(configDir, 'network');
  if (existsSync(networkFile)) {
    return readFileSync(networkFile, 'utf-8').trim();
  }
  return 'testnet'; // Default
}

/**
 * Set current network
 */
export function setCurrentNetwork(cliName: string, network: string): void {
  const configDir = getConfigDir(cliName);
  const networkFile = join(configDir, 'network');
  writeFileSync(networkFile, network);
}
