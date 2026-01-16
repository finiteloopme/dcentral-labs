/**
 * EVM provider utilities using viem
 */

import {
  createPublicClient,
  createWalletClient,
  http,
  formatEther,
  parseEther,
  defineChain,
  type PublicClient,
  type WalletClient,
  type Chain,
  type Transport,
  type Account,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import type { ChainConfig } from './config.js';

/**
 * Build a viem Chain definition from ChainConfig
 * Creates a custom chain from TOML configuration
 */
export function buildChain(config: ChainConfig): Chain {
  return defineChain({
    id: config.chainId,
    name: config.chainName,
    nativeCurrency: {
      name: config.nativeCurrency,
      symbol: config.nativeCurrency,
      decimals: config.nativeDecimals,
    },
    rpcUrls: {
      default: { http: [config.rpcUrl] },
    },
    blockExplorers: config.explorerUrl
      ? {
          default: {
            name: 'Explorer',
            url: config.explorerUrl,
          },
        }
      : undefined,
  });
}

/**
 * Create a public client for read operations
 */
export function createProvider(config: ChainConfig, rpcUrl?: string): PublicClient {
  const chain = buildChain(config);
  const url = rpcUrl || config.rpcUrl;

  return createPublicClient({
    chain,
    transport: http(url),
  });
}

/**
 * Create a wallet client for write operations
 */
export function createWallet(
  privateKey: string,
  config: ChainConfig,
  rpcUrl?: string
): { walletClient: WalletClient<Transport, Chain, Account>; account: Account } {
  const chain = buildChain(config);
  const url = rpcUrl || config.rpcUrl;
  const account = privateKeyToAccount(privateKey as `0x${string}`);

  const walletClient = createWalletClient({
    account,
    chain,
    transport: http(url),
  });

  return { walletClient, account };
}

/**
 * Get balance for an address
 */
export async function getBalance(
  client: PublicClient,
  address: string,
  config: ChainConfig
): Promise<{ balance: bigint; formatted: string }> {
  const balance = await client.getBalance({ address: address as `0x${string}` });
  const formatted = `${formatEther(balance)} ${config.nativeCurrency}`;
  return { balance, formatted };
}

/**
 * Send native token
 */
export async function sendTransaction(
  walletClient: WalletClient<Transport, Chain, Account>,
  publicClient: PublicClient,
  to: string,
  amount: string,
  config: ChainConfig
): Promise<{ hash: string; blockNumber?: number }> {
  const hash = await walletClient.sendTransaction({
    to: to as `0x${string}`,
    value: parseEther(amount),
  });

  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  return {
    hash,
    blockNumber: receipt.blockNumber ? Number(receipt.blockNumber) : undefined,
  };
}

/**
 * Check if connected to local node
 */
export async function isLocalNode(client: PublicClient): Promise<boolean> {
  try {
    const chainId = await client.getChainId();
    // Anvil/Hardhat typically use chain ID 31337
    return chainId === 31337;
  } catch {
    return false;
  }
}

/**
 * Format explorer URL for transaction
 */
export function getExplorerTxUrl(config: ChainConfig, txHash: string): string | undefined {
  if (!config.explorerUrl) return undefined;
  return `${config.explorerUrl}/tx/${txHash}`;
}

/**
 * Format explorer URL for address
 */
export function getExplorerAddressUrl(config: ChainConfig, address: string): string | undefined {
  if (!config.explorerUrl) return undefined;
  return `${config.explorerUrl}/address/${address}`;
}

// Re-export formatEther for use in other modules
export { formatEther, parseEther };
