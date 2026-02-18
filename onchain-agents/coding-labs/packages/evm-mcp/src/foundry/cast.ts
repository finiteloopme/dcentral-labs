/**
 * Cast command wrappers.
 *
 * Cast is Foundry's CLI for chain interaction. We use it for:
 * - Calling view functions (cast call)
 * - Sending transactions (cast send)
 * - Getting transaction receipts (cast receipt)
 * - Decoding data (cast decode)
 */

import { execFile } from 'child_process';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

export interface CallResult {
  success: boolean;
  result: string;
  decoded?: string;
  error?: string;
}

export interface SendResult {
  success: boolean;
  txHash?: string;
  unsignedTx?: {
    to: string;
    data: string;
    chainId: number;
    gasLimit: string;
    value: string;
  };
  error?: string;
}

export interface ReceiptResult {
  success: boolean;
  status: 'success' | 'failed' | 'pending';
  blockNumber?: number;
  gasUsed?: string;
  contractAddress?: string;
  logs?: unknown[];
  error?: string;
}

// -----------------------------------------------------------------------------
// Cast Call (Read Operations)
// -----------------------------------------------------------------------------

/**
 * Call a view/pure function on a contract.
 *
 * @param contractAddress - Contract address
 * @param functionSig - Function signature (e.g., "balanceOf(address)")
 * @param args - Function arguments
 * @param rpcUrl - RPC URL to use
 */
export async function castCall(
  contractAddress: string,
  functionSig: string,
  args: string[],
  rpcUrl: string
): Promise<CallResult> {
  try {
    const castArgs = [
      'call',
      contractAddress,
      functionSig,
      ...args,
      '--rpc-url',
      rpcUrl,
    ];

    console.log(`[evm-mcp] cast ${castArgs.join(' ')}`);
    const { stdout, stderr } = await execFileAsync('cast', castArgs, {
      timeout: 30000,
    });

    if (stderr && stderr.includes('Error')) {
      return {
        success: false,
        result: '',
        error: stderr,
      };
    }

    return {
      success: true,
      result: stdout.trim(),
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      success: false,
      result: '',
      error: errorMessage,
    };
  }
}

/**
 * Decode a call result using ABI.
 */
export async function castDecode(
  returnType: string,
  data: string
): Promise<{ success: boolean; decoded?: string; error?: string }> {
  try {
    const { stdout } = await execFileAsync(
      'cast',
      ['abi-decode', returnType, data],
      { timeout: 10000 }
    );

    return {
      success: true,
      decoded: stdout.trim(),
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      success: false,
      error: errorMessage,
    };
  }
}

// -----------------------------------------------------------------------------
// Cast Send (Write Operations)
// -----------------------------------------------------------------------------

/**
 * Send a transaction to a contract.
 *
 * If devMode is true, executes the transaction with the provided private key.
 * Otherwise, returns the unsigned transaction for user to sign.
 */
export async function castSend(
  contractAddress: string,
  functionSig: string,
  args: string[],
  options: {
    rpcUrl: string;
    chainId: number;
    value?: string;
    devMode?: boolean;
    privateKey?: string;
  }
): Promise<SendResult> {
  const { rpcUrl, chainId, value, devMode, privateKey } = options;

  // If not dev mode, return unsigned transaction data
  if (!devMode) {
    try {
      // Use cast calldata to encode the function call
      const calldataArgs = ['calldata', functionSig, ...args];
      const { stdout: calldata } = await execFileAsync('cast', calldataArgs, {
        timeout: 10000,
      });

      return {
        success: true,
        unsignedTx: {
          to: contractAddress,
          data: calldata.trim(),
          chainId,
          gasLimit: '500000', // Default, user can adjust
          value: value || '0x0',
        },
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      return {
        success: false,
        error: `Failed to encode calldata: ${errorMessage}`,
      };
    }
  }

  // Dev mode: execute transaction
  if (!privateKey) {
    return {
      success: false,
      error: 'Private key required for dev mode transaction',
    };
  }

  try {
    const castArgs = [
      'send',
      contractAddress,
      functionSig,
      ...args,
      '--rpc-url',
      rpcUrl,
      '--private-key',
      privateKey,
    ];

    if (value) {
      castArgs.push('--value', value);
    }

    console.log(`[evm-mcp] cast send ${contractAddress} ${functionSig}`);
    const { stdout } = await execFileAsync('cast', castArgs, {
      timeout: 120000,
    });

    // Parse transaction hash from output
    const lines = stdout.split('\n');
    let txHash = '';

    for (const line of lines) {
      if (line.startsWith('transactionHash')) {
        txHash = line.split(/\s+/)[1];
        break;
      }
    }

    return {
      success: true,
      txHash: txHash || stdout.trim(),
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      success: false,
      error: `Transaction failed: ${errorMessage}`,
    };
  }
}

// -----------------------------------------------------------------------------
// Cast Receipt
// -----------------------------------------------------------------------------

/**
 * Get transaction receipt.
 */
export async function castReceipt(
  txHash: string,
  rpcUrl: string
): Promise<ReceiptResult> {
  try {
    const { stdout, stderr } = await execFileAsync(
      'cast',
      ['receipt', txHash, '--rpc-url', rpcUrl, '--json'],
      { timeout: 30000 }
    );

    if (stderr && stderr.includes('Error')) {
      return {
        success: false,
        status: 'failed',
        error: stderr,
      };
    }

    // Handle case where transaction is pending
    if (!stdout.trim()) {
      return {
        success: true,
        status: 'pending',
      };
    }

    const receipt = JSON.parse(stdout);

    return {
      success: true,
      status: receipt.status === '0x1' ? 'success' : 'failed',
      blockNumber: parseInt(receipt.blockNumber, 16),
      gasUsed: receipt.gasUsed,
      contractAddress: receipt.contractAddress || undefined,
      logs: receipt.logs,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);

    // Check if it's a "not found" error (pending transaction)
    if (errorMessage.includes('not found') || errorMessage.includes('null')) {
      return {
        success: true,
        status: 'pending',
      };
    }

    return {
      success: false,
      status: 'failed',
      error: errorMessage,
    };
  }
}

/**
 * Get current block number.
 */
export async function castBlockNumber(rpcUrl: string): Promise<number | null> {
  try {
    const { stdout } = await execFileAsync(
      'cast',
      ['block-number', '--rpc-url', rpcUrl],
      { timeout: 10000 }
    );

    return parseInt(stdout.trim(), 10);
  } catch {
    return null;
  }
}
