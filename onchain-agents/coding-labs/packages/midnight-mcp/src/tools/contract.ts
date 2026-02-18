/**
 * Contract tools for the Midnight MCP server.
 *
 * Provides tools for deploying and calling compiled Compact contracts
 * using the toolkit's contract-custom command.
 *
 * These tools work with:
 *   - Compiled contract directories (output from compactc)
 *   - Intent files (.mn) that describe deploy/call operations
 *
 * NOTE: contract-simple is NOT supported as it requires internal test data.
 * See toolkit-client.ts for details.
 */

import type { MidnightMCPConfig } from '../config.js';
import { resolveNetwork, getNodeRpcUrl, getProofServerUrl } from '../config.js';
import {
  deployContract as deployContractToolkit,
  callContract as callContractToolkit,
  GENESIS_WALLET_SEED,
} from '../toolkit-client.js';
import { getWalletSeed } from './wallet.js';

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

export interface DeployResult {
  success: boolean;
  network: string;
  contractAddress: string;
  txId: string;
  message: string;
  errors?: string;
}

export interface CallResult {
  success: boolean;
  network: string;
  contractAddress: string;
  txId: string;
  message: string;
  errors?: string;
}

export interface DeployedContract {
  address: string;
  compiledContractDir: string;
  intentFile: string;
  network: string;
  deployedAt: Date;
  txId: string;
}

// -----------------------------------------------------------------------------
// In-Memory Contract Cache
// -----------------------------------------------------------------------------

/**
 * Cache of deployed contracts for this session.
 * Key is contract address.
 */
const contractCache = new Map<string, DeployedContract>();

/**
 * Get a cached contract by address.
 */
export function getCachedContract(
  address: string
): DeployedContract | undefined {
  return contractCache.get(address);
}

/**
 * List all cached contracts.
 */
export function listCachedContracts(): DeployedContract[] {
  return Array.from(contractCache.values());
}

/**
 * Clear all cached contracts.
 */
export function clearContractCache(): void {
  contractCache.clear();
}

// -----------------------------------------------------------------------------
// Contract Deploy
// -----------------------------------------------------------------------------

/**
 * Deploy a compiled Compact contract to the Midnight network.
 *
 * @param compiledContractDir - Path to compactc output directory
 * @param intentFile - Path to deploy intent .mn file
 * @param config - MCP config
 * @param network - Target network (optional, defaults to config)
 * @param fundingSeed - Optional funding wallet seed
 */
export async function deployContract(
  compiledContractDir: string,
  intentFile: string,
  config: MidnightMCPConfig,
  network?: string,
  fundingSeed?: string
): Promise<DeployResult> {
  const resolvedNetwork = resolveNetwork(config, network);

  try {
    // Determine funding seed: use provided, or cached wallet, or genesis
    let seed = fundingSeed;
    if (!seed) {
      seed = getWalletSeed(resolvedNetwork);
    }
    if (!seed) {
      seed = GENESIS_WALLET_SEED;
    }

    // Get node RPC URL and proof server URL
    const nodeRpcUrl = getNodeRpcUrl(config, resolvedNetwork);
    const proofServerUrl = getProofServerUrl(config, resolvedNetwork);

    // Deploy using toolkit
    const result = await deployContractToolkit(
      {
        compiledContractDir,
        intentFile,
        fundingSeed: seed,
      },
      nodeRpcUrl,
      proofServerUrl
    );

    if (!result.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress: '',
        txId: '',
        message: `Deployment failed: ${result.error}`,
        errors: result.error,
      };
    }

    // Cache the deployed contract
    if (result.contractAddress) {
      contractCache.set(result.contractAddress, {
        address: result.contractAddress,
        compiledContractDir,
        intentFile,
        network: resolvedNetwork,
        deployedAt: new Date(),
        txId: result.txId,
      });
    }

    return {
      success: true,
      network: resolvedNetwork,
      contractAddress: result.contractAddress,
      txId: result.txId,
      message:
        `Contract deployed successfully on ${resolvedNetwork}. ` +
        `Address: ${result.contractAddress}. ` +
        `TxId: ${result.txId}.`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return {
      success: false,
      network: resolvedNetwork,
      contractAddress: '',
      txId: '',
      message: `Deployment failed: ${errorMessage}`,
      errors: errorMessage,
    };
  }
}

// -----------------------------------------------------------------------------
// Contract Call
// -----------------------------------------------------------------------------

/**
 * Call a circuit on a deployed contract.
 *
 * @param compiledContractDir - Path to compactc output directory
 * @param intentFile - Path to call intent .mn file
 * @param config - MCP config
 * @param network - Target network (optional, defaults to config)
 * @param fundingSeed - Optional funding wallet seed
 */
export async function callContract(
  compiledContractDir: string,
  intentFile: string,
  config: MidnightMCPConfig,
  network?: string,
  fundingSeed?: string
): Promise<CallResult> {
  const resolvedNetwork = resolveNetwork(config, network);

  try {
    // Determine funding seed: use provided, or cached wallet, or genesis
    let seed = fundingSeed;
    if (!seed) {
      seed = getWalletSeed(resolvedNetwork);
    }
    if (!seed) {
      seed = GENESIS_WALLET_SEED;
    }

    // Get node RPC URL and proof server URL
    const nodeRpcUrl = getNodeRpcUrl(config, resolvedNetwork);
    const proofServerUrl = getProofServerUrl(config, resolvedNetwork);

    // Call using toolkit
    const result = await callContractToolkit(
      {
        compiledContractDir,
        intentFile,
        fundingSeed: seed,
      },
      nodeRpcUrl,
      proofServerUrl
    );

    if (!result.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress: '',
        txId: '',
        message: `Contract call failed: ${result.error}`,
        errors: result.error,
      };
    }

    return {
      success: true,
      network: resolvedNetwork,
      contractAddress: '', // Intent file doesn't expose address directly
      txId: result.txId,
      message: `Contract call executed successfully. TxId: ${result.txId}.`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return {
      success: false,
      network: resolvedNetwork,
      contractAddress: '',
      txId: '',
      message: `Contract call failed: ${errorMessage}`,
      errors: errorMessage,
    };
  }
}
