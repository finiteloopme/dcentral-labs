/**
 * Provider factory for connecting to Midnight services
 * 
 * Creates instances of the various providers needed for
 * wallet operations and contract deployment.
 */

import { getServiceUrls, getNetworkSync } from './network.js';
import { type NetworkId, type ServiceUrls, GENESIS_WALLETS, FUNDABLE_NETWORKS } from './types.js';

/**
 * Provider configuration for runtime operations
 */
export interface ProviderConfig {
  network: NetworkId;
  urls: ServiceUrls;
}

/**
 * Get provider configuration from environment
 */
export function getProviderConfig(): ProviderConfig {
  return {
    network: getNetworkSync(),
    urls: getServiceUrls(),
  };
}

/**
 * Validate that required services are configured
 */
export function validateServiceConfig(config: ProviderConfig): { valid: boolean; missing: string[] } {
  const missing: string[] = [];
  
  if (!config.urls.nodeWsUrl) missing.push('MIDNIGHT_NODE_URL');
  if (!config.urls.indexerUrl) missing.push('INDEXER_URL');
  if (!config.urls.proofServerUrl) missing.push('PROOF_SERVER_URL');
  
  return {
    valid: missing.length === 0,
    missing,
  };
}

/**
 * Check if the current network supports funding from genesis wallets
 */
export function isFundableNetwork(network: NetworkId): boolean {
  return FUNDABLE_NETWORKS.includes(network as any);
}

/**
 * Get the default genesis wallet for funding
 */
export function getDefaultGenesisWallet(): { seed: string; name: string } {
  return GENESIS_WALLETS[0];
}

/**
 * Get a genesis wallet by index (1-4)
 */
export function getGenesisWallet(index: number): { seed: string; name: string } | null {
  if (index < 1 || index > GENESIS_WALLETS.length) {
    return null;
  }
  return GENESIS_WALLETS[index - 1];
}

/**
 * Create a wallet provider using the @midnight-ntwrk/wallet SDK
 * 
 * This is a factory function that creates a wallet instance
 * connected to the configured services.
 * 
 * Note: This requires the SDK packages to be installed and
 * services to be running.
 */
export async function createWalletProvider(
  seed: string,
  config: ProviderConfig
): Promise<any> {
  // Validate configuration
  const validation = validateServiceConfig(config);
  if (!validation.valid) {
    throw new Error(
      `Missing service configuration: ${validation.missing.join(', ')}. ` +
      'Set these environment variables or check your .env file.'
    );
  }
  
  // Dynamically import wallet SDK
  // This allows the CLI to work even if SDK is not installed
  try {
    const { WalletBuilder } = await import('@midnight-ntwrk/wallet');
    const { getZswapNetworkId } = await import('@midnight-ntwrk/midnight-js-network-id');
    
    const wallet = await WalletBuilder.buildFromSeed(
      config.urls.indexerUrl!,
      config.urls.indexerWsUrl!,
      config.urls.proofServerUrl!,
      config.urls.nodeWsUrl!,
      seed,
      getZswapNetworkId(),
      'warn'
    );
    
    return wallet;
    
  } catch (error) {
    if ((error as any).code === 'ERR_MODULE_NOT_FOUND') {
      throw new Error(
        'Midnight SDK not installed. Run `npm install` to install dependencies.'
      );
    }
    throw error;
  }
}

/**
 * Create providers for contract operations
 * 
 * Returns the full set of providers needed for contract deployment
 * and interaction.
 */
export async function createContractProviders(
  seed: string,
  config: ProviderConfig,
  options: {
    privateStateDir: string;
    zkConfigPath: string;
  }
): Promise<any> {
  const validation = validateServiceConfig(config);
  if (!validation.valid) {
    throw new Error(
      `Missing service configuration: ${validation.missing.join(', ')}. ` +
      'Set these environment variables or check your .env file.'
    );
  }
  
  try {
    // Dynamic imports for SDK packages
    const { indexerPublicDataProvider } = await import('@midnight-ntwrk/midnight-js-indexer-public-data-provider');
    const { httpClientProofProvider } = await import('@midnight-ntwrk/midnight-js-http-client-proof-provider');
    const { levelPrivateStateProvider } = await import('@midnight-ntwrk/midnight-js-level-private-state-provider');
    const { NodeZkConfigProvider } = await import('@midnight-ntwrk/midnight-js-node-zk-config-provider');
    
    // Create wallet provider first
    const wallet = await createWalletProvider(seed, config);
    
    // Create wallet/midnight provider adapter
    const walletProvider = await createWalletMidnightProvider(wallet);
    
    return {
      privateStateProvider: levelPrivateStateProvider({
        privateStateStoreName: options.privateStateDir,
      }),
      publicDataProvider: indexerPublicDataProvider(
        config.urls.indexerUrl!,
        config.urls.indexerWsUrl!
      ),
      zkConfigProvider: new NodeZkConfigProvider(options.zkConfigPath),
      proofProvider: httpClientProofProvider(config.urls.proofServerUrl!),
      walletProvider,
      midnightProvider: walletProvider,
      wallet, // Raw wallet for direct access
    };
    
  } catch (error) {
    if ((error as any).code === 'ERR_MODULE_NOT_FOUND') {
      throw new Error(
        'Midnight SDK not installed. Run `npm install` to install dependencies.'
      );
    }
    throw error;
  }
}

/**
 * Create a combined wallet/midnight provider from a wallet instance
 */
async function createWalletMidnightProvider(wallet: any): Promise<any> {
  const { firstValueFrom } = await import('rxjs');
  const { Transaction, nativeToken } = await import('@midnight-ntwrk/ledger');
  const { Transaction: ZswapTransaction } = await import('@midnight-ntwrk/zswap');
  const { getLedgerNetworkId, getZswapNetworkId } = await import('@midnight-ntwrk/midnight-js-network-id');
  const { createBalancedTx } = await import('@midnight-ntwrk/midnight-js-types');
  
  const state: any = await firstValueFrom(wallet.state());
  
  return {
    coinPublicKey: state.coinPublicKey,
    encryptionPublicKey: state.encryptionPublicKey,
    
    async balanceTx(tx: any, newCoins: any[]): Promise<any> {
      const zswapTx = ZswapTransaction.deserialize(
        tx.serialize(getLedgerNetworkId()),
        getZswapNetworkId()
      );
      const balanced = await wallet.balanceTransaction(zswapTx, newCoins);
      const proved = await wallet.proveTransaction(balanced);
      const ledgerTx = Transaction.deserialize(
        proved.serialize(getZswapNetworkId()),
        getLedgerNetworkId()
      );
      return createBalancedTx(ledgerTx);
    },
    
    async submitTx(tx: any): Promise<string> {
      return wallet.submitTransaction(tx);
    },
  };
}

/**
 * Wait for wallet to sync and have sufficient balance
 */
export async function waitForWalletSync(
  wallet: any,
  options: {
    minBalance?: bigint;
    onProgress?: (synced: bigint, remaining: bigint) => void;
    timeout?: number;
  } = {}
): Promise<{ balance: bigint; synced: boolean }> {
  const { firstValueFrom, timeout, filter, tap, throttleTime, map } = await import('rxjs');
  const { nativeToken } = await import('@midnight-ntwrk/ledger');
  
  const minBalance = options.minBalance ?? 0n;
  const timeoutMs = options.timeout ?? 120000; // 2 minutes default
  
  try {
    const result: { balance: bigint; synced: boolean } = await firstValueFrom(
      wallet.state().pipe(
        throttleTime(5000),
        tap((state: any) => {
          if (options.onProgress) {
            const synced = state.syncProgress?.synced ?? 0n;
            const remaining = state.syncProgress?.lag?.applyGap ?? 0n;
            options.onProgress(synced, remaining);
          }
        }),
        filter((state: any) => {
          // Check if we're synced enough
          const synced = typeof state.syncProgress?.synced === 'bigint' 
            ? state.syncProgress.synced : 0n;
          const total = typeof state.syncProgress?.lag?.applyGap === 'bigint'
            ? state.syncProgress.lag.applyGap : 1000n;
          const isSynced = total - synced < 100n;
          
          // Check balance if required
          const balance = state.balances[nativeToken()] ?? 0n;
          const hasBalance = balance >= minBalance;
          
          return isSynced && (minBalance === 0n || hasBalance);
        }),
        map((state: any) => ({
          balance: (state.balances[nativeToken()] ?? 0n) as bigint,
          synced: true as const,
        })),
        timeout(timeoutMs)
      )
    );
    
    return result;
    
  } catch (error) {
    // Timeout or other error
    const currentState: any = await firstValueFrom(wallet.state());
    return {
      balance: (currentState.balances?.[nativeToken()] ?? 0n) as bigint,
      synced: false,
    };
  }
}
