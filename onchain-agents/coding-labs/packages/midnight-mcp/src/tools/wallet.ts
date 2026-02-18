/**
 * wallet_create tool
 *
 * Creates or retrieves a headless Midnight wallet for the given network.
 * On standalone (local) chains, uses the genesis seed which has pre-minted tDUST.
 * On testnets, generates a random seed (requires faucet funding).
 *
 * Uses the toolkit CLI for all wallet operations instead of the SDK.
 */

import type { MidnightMCPConfig } from '../config.js';
import { resolveNetwork, NETWORKS } from '../config.js';
import {
  showAddress,
  showWallet,
  generateWalletSeed,
  GENESIS_WALLET_SEED,
  getNodeRpcUrl,
} from '../toolkit-client.js';

export interface WalletCreateResult {
  success: boolean;
  network: string;
  address: string;
  balance: string;
  seed: string;
  message: string;
  errors?: string;
}

/**
 * Cached wallet seeds keyed by network name.
 * The toolkit is stateless, so we only cache the seed.
 */
const walletCache = new Map<string, string>();

export async function createWallet(
  config: MidnightMCPConfig,
  network?: string
): Promise<WalletCreateResult> {
  try {
    const resolvedNetwork = resolveNetwork(config, network);
    const net = NETWORKS[resolvedNetwork];

    if (!net) {
      return {
        success: false,
        network: resolvedNetwork,
        address: '',
        balance: '0',
        seed: '',
        message: `Unknown network: ${resolvedNetwork}`,
        errors: `Network "${resolvedNetwork}" not found in configuration`,
      };
    }

    // Determine seed: use genesis seed for standalone, random for testnets
    let seed = walletCache.get(resolvedNetwork);
    if (!seed) {
      seed =
        net.networkId === 'undeployed'
          ? GENESIS_WALLET_SEED
          : generateWalletSeed();
      walletCache.set(resolvedNetwork, seed);
    }

    // Get address via toolkit
    const address = await showAddress(seed, resolvedNetwork);

    // Try to get balance via show-wallet (may fail if node not reachable)
    let balance = '0';
    try {
      const nodeRpcUrl = getNodeRpcUrl(resolvedNetwork);
      const walletState = await showWallet(seed, resolvedNetwork, nodeRpcUrl);
      // Extract balance from wallet state
      // The coins field contains the balance information
      if (walletState.coins && typeof walletState.coins === 'object') {
        const coins = walletState.coins as Record<string, unknown>;
        // Sum all coin values (native token balance)
        let totalBalance = 0n;
        for (const val of Object.values(coins)) {
          if (typeof val === 'number') totalBalance += BigInt(val);
          else if (typeof val === 'string') totalBalance += BigInt(val);
          else if (typeof val === 'bigint') totalBalance += val;
        }
        balance = totalBalance.toString();
      }
    } catch {
      // Node may not be reachable, balance will be 0
      console.warn(
        `[wallet_create] Could not fetch balance for ${resolvedNetwork}`
      );
    }

    return {
      success: true,
      network: resolvedNetwork,
      address,
      balance,
      seed,
      message:
        `Wallet ready on ${resolvedNetwork}. ` +
        `Address: ${address}. ` +
        `Balance: ${balance} tDUST.`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return {
      success: false,
      network: network || 'unknown',
      address: '',
      balance: '0',
      seed: '',
      message: `Failed to create wallet: ${errorMessage}`,
      errors: errorMessage,
    };
  }
}

/**
 * Get the cached seed for a network.
 * Returns undefined if no wallet has been created for that network.
 */
export function getWalletSeed(network: string): string | undefined {
  return walletCache.get(network);
}
