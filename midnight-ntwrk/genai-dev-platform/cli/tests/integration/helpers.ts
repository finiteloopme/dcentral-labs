/**
 * Integration Test Helpers
 * 
 * Utilities for creating, funding, and cleaning up test wallets.
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';
import * as fs from 'fs';
import { getServiceConfig, getCliDir, getProjectRoot } from './setup.js';

const execAsync = promisify(exec);

/** Prefix for all test wallets */
export const TEST_WALLET_PREFIX = '_test_';

/** Track created test wallets for cleanup */
const createdWallets: string[] = [];

/**
 * Generate a unique test wallet name
 */
export function generateTestWalletName(suffix?: string): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 6);
  const name = `${TEST_WALLET_PREFIX}${suffix || 'wallet'}_${timestamp}_${random}`;
  return name;
}

/**
 * Run a CLI command and return the result
 */
export async function runCli(
  args: string,
  options: { timeout?: number; cwd?: string } = {}
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  const cliDir = getCliDir();
  const cwd = options.cwd || getProjectRoot();
  const timeout = options.timeout || 120000; // 2 minutes default
  
  // Use node to run the compiled CLI
  const command = `node "${path.join(cliDir, 'dist', 'index.js')}" ${args}`;
  
  try {
    const { stdout, stderr } = await execAsync(command, {
      cwd,
      timeout,
      env: {
        ...process.env,
        // Ensure .env is loaded by the CLI
        NODE_ENV: 'test',
      },
    });
    return { stdout, stderr, exitCode: 0 };
  } catch (error: any) {
    return {
      stdout: error.stdout || '',
      stderr: error.stderr || error.message,
      exitCode: error.code || 1,
    };
  }
}

/**
 * Create a test wallet
 */
export async function createTestWallet(name?: string): Promise<{
  name: string;
  address: string;
  success: boolean;
  output: string;
}> {
  const walletName = name || generateTestWalletName();
  
  const result = await runCli(`wallet create ${walletName} --json`);
  
  if (result.exitCode === 0) {
    createdWallets.push(walletName);
    
    try {
      const data = JSON.parse(result.stdout);
      return {
        name: walletName,
        address: data.addresses?.unshielded || '',
        success: true,
        output: result.stdout,
      };
    } catch {
      return {
        name: walletName,
        address: '',
        success: true,
        output: result.stdout,
      };
    }
  }
  
  return {
    name: walletName,
    address: '',
    success: false,
    output: result.stderr || result.stdout,
  };
}

/**
 * Fund a test wallet from genesis
 */
export async function fundTestWallet(
  name: string,
  amount: number
): Promise<{
  success: boolean;
  txHash?: string;
  output: string;
}> {
  const result = await runCli(`wallet fund ${name} ${amount} --json`, {
    timeout: 180000, // 3 minutes for transaction
  });
  
  if (result.exitCode === 0) {
    try {
      const data = JSON.parse(result.stdout);
      return {
        success: data.success || true,
        txHash: data.txHash,
        output: result.stdout,
      };
    } catch {
      return {
        success: true,
        output: result.stdout,
      };
    }
  }
  
  return {
    success: false,
    output: result.stderr || result.stdout,
  };
}

/**
 * Get wallet balance
 */
export async function getTestWalletBalance(name: string): Promise<{
  success: boolean;
  shielded: bigint;
  unshielded: bigint;
  total: bigint;
  output: string;
}> {
  const result = await runCli(`wallet balance ${name} --json`);
  
  if (result.exitCode === 0) {
    try {
      const data = JSON.parse(result.stdout);
      return {
        success: true,
        shielded: BigInt(data.balances?.shielded?.NIGHT || '0'),
        unshielded: BigInt(data.balances?.unshielded?.NIGHT || '0'),
        total: BigInt(data.balances?.total?.NIGHT || '0'),
        output: result.stdout,
      };
    } catch {
      return {
        success: false,
        shielded: 0n,
        unshielded: 0n,
        total: 0n,
        output: result.stdout,
      };
    }
  }
  
  return {
    success: false,
    shielded: 0n,
    unshielded: 0n,
    total: 0n,
    output: result.stderr || result.stdout,
  };
}

/**
 * Remove a wallet
 */
export async function removeTestWallet(name: string): Promise<boolean> {
  const result = await runCli(`wallet remove ${name} --force`);
  return result.exitCode === 0;
}

/**
 * Query the indexer directly
 */
export async function queryIndexer(query: string): Promise<any> {
  const config = getServiceConfig();
  
  let url = config.indexerUrl;
  if (!url.includes('/api/')) {
    url = url.replace(/\/$/, '') + '/api/v3/graphql';
  }
  
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query }),
  });
  
  if (!response.ok) {
    throw new Error(`Indexer query failed: ${response.statusText}`);
  }
  
  return response.json();
}

/**
 * Get current block height from indexer
 */
export async function getCurrentBlockHeight(): Promise<number> {
  const result = await queryIndexer('{ block { height } }');
  return result.data?.block?.height || 0;
}

/**
 * Wait for a condition to be true
 */
export async function waitFor(
  condition: () => Promise<boolean>,
  options: { timeout?: number; interval?: number; message?: string } = {}
): Promise<void> {
  const timeout = options.timeout || 30000;
  const interval = options.interval || 1000;
  const message = options.message || 'Condition not met';
  
  const startTime = Date.now();
  
  while (Date.now() - startTime < timeout) {
    if (await condition()) {
      return;
    }
    await new Promise(resolve => setTimeout(resolve, interval));
  }
  
  throw new Error(`Timeout: ${message}`);
}

/**
 * Clean up all test wallets created during tests
 */
export async function cleanupTestWallets(): Promise<{
  cleaned: string[];
  failed: string[];
}> {
  const cleaned: string[] = [];
  const failed: string[] = [];
  
  // Clean up tracked wallets
  for (const name of createdWallets) {
    try {
      const success = await removeTestWallet(name);
      if (success) {
        cleaned.push(name);
      } else {
        failed.push(name);
      }
    } catch {
      failed.push(name);
    }
  }
  
  // Clear the tracking array
  createdWallets.length = 0;
  
  // Also scan for any orphaned test wallets
  const listResult = await runCli('wallet list --json');
  if (listResult.exitCode === 0) {
    try {
      const data = JSON.parse(listResult.stdout);
      const wallets = data.wallets || [];
      
      for (const wallet of wallets) {
        if (wallet.name?.startsWith(TEST_WALLET_PREFIX) && !cleaned.includes(wallet.name)) {
          try {
            const success = await removeTestWallet(wallet.name);
            if (success) {
              cleaned.push(wallet.name);
            } else {
              failed.push(wallet.name);
            }
          } catch {
            failed.push(wallet.name);
          }
        }
      }
    } catch {
      // Ignore parse errors
    }
  }
  
  return { cleaned, failed };
}

/**
 * Format NIGHT balance for display (from raw units)
 */
export function formatNight(balance: bigint): string {
  const whole = balance / 1_000_000n;
  const fraction = balance % 1_000_000n;
  
  if (fraction === 0n) {
    return `${whole}.00`;
  }
  
  const fractionStr = fraction.toString().padStart(6, '0').replace(/0+$/, '');
  return `${whole}.${fractionStr}`;
}
