/**
 * EVM chain configuration
 */

import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

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
 * Load chain configuration from environment or config file
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
