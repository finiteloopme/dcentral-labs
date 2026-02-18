/**
 * Anvil process management.
 *
 * Anvil is Foundry's local EVM node. We use it to:
 * - Fork from real chain RPCs (has real state, balances, contracts)
 * - Provide pre-funded test accounts for dev mode
 * - Enable instant transaction confirmation
 */

import { spawn, type ChildProcess } from 'child_process';
import type { ChainConfig } from '../config.js';
import { ANVIL_ACCOUNTS } from '../config.js';
import { getSession, setAnvilProcess } from '../session.js';

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

export interface AnvilStartResult {
  success: boolean;
  rpcUrl: string;
  chainId: number;
  accounts: Array<{ address: string; privateKey: string }>;
  error?: string;
}

export interface AnvilStopResult {
  success: boolean;
  message: string;
}

// -----------------------------------------------------------------------------
// Anvil Management
// -----------------------------------------------------------------------------

/**
 * Start Anvil fork of a chain.
 *
 * @param chainConfig - Chain to fork from
 * @param port - Local port for Anvil (default: 8545)
 * @param blockNumber - Optional block number to fork from
 */
export async function startAnvil(
  chainConfig: ChainConfig,
  port: number = 8545,
  blockNumber?: number
): Promise<AnvilStartResult> {
  const session = getSession();

  // Check if Anvil is already running for this session
  if (session?.anvilProcess) {
    return {
      success: true,
      rpcUrl: session.anvilRpcUrl,
      chainId: chainConfig.chainId,
      accounts: [...ANVIL_ACCOUNTS],
    };
  }

  return new Promise((resolve) => {
    const args = [
      '--fork-url',
      chainConfig.rpcUrl,
      '--port',
      port.toString(),
      '--chain-id',
      chainConfig.chainId.toString(),
    ];

    if (blockNumber) {
      args.push('--fork-block-number', blockNumber.toString());
    }

    console.log(`[evm-mcp] Starting Anvil: anvil ${args.join(' ')}`);

    const anvilProcess = spawn('anvil', args, {
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let started = false;
    let errorOutput = '';

    // Listen for Anvil startup message
    anvilProcess.stdout?.on('data', (data: Buffer) => {
      const output = data.toString();
      console.log(`[anvil] ${output}`);

      // Anvil prints "Listening on 127.0.0.1:8545" when ready
      if (output.includes('Listening on') && !started) {
        started = true;
        setAnvilProcess(anvilProcess);
        resolve({
          success: true,
          rpcUrl: `http://localhost:${port}`,
          chainId: chainConfig.chainId,
          accounts: [...ANVIL_ACCOUNTS],
        });
      }
    });

    anvilProcess.stderr?.on('data', (data: Buffer) => {
      const output = data.toString();
      console.error(`[anvil] ${output}`);
      errorOutput += output;
    });

    anvilProcess.on('error', (error) => {
      console.error(`[evm-mcp] Failed to start Anvil:`, error);
      resolve({
        success: false,
        rpcUrl: '',
        chainId: chainConfig.chainId,
        accounts: [],
        error: `Failed to start Anvil: ${error.message}`,
      });
    });

    anvilProcess.on('exit', (code) => {
      if (!started) {
        resolve({
          success: false,
          rpcUrl: '',
          chainId: chainConfig.chainId,
          accounts: [],
          error: `Anvil exited with code ${code}: ${errorOutput}`,
        });
      }
    });

    // Timeout after 30 seconds
    setTimeout(() => {
      if (!started) {
        anvilProcess.kill();
        resolve({
          success: false,
          rpcUrl: '',
          chainId: chainConfig.chainId,
          accounts: [],
          error: 'Anvil startup timed out after 30 seconds',
        });
      }
    }, 30000);
  });
}

/**
 * Stop the Anvil process for the current session.
 */
export function stopAnvil(): AnvilStopResult {
  const session = getSession();

  if (!session) {
    return {
      success: false,
      message: 'No active session',
    };
  }

  if (!session.anvilProcess) {
    return {
      success: false,
      message: 'Anvil is not running',
    };
  }

  session.anvilProcess.kill('SIGTERM');
  setAnvilProcess(null as unknown as ChildProcess);

  return {
    success: true,
    message: 'Anvil stopped',
  };
}

/**
 * Check if Anvil is running and healthy.
 */
export async function checkAnvilHealth(rpcUrl: string): Promise<boolean> {
  try {
    const response = await fetch(rpcUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'eth_chainId',
        params: [],
        id: 1,
      }),
    });

    if (!response.ok) {
      return false;
    }

    const result = (await response.json()) as { result?: string };
    return !!result.result;
  } catch {
    return false;
  }
}
