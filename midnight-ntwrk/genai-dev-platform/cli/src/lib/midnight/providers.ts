/**
 * Provider factory for connecting to Midnight services
 * 
 * Creates instances of the various providers needed for
 * wallet operations and contract deployment.
 * 
 * Updated for Midnight SDK 3.x which uses:
 * - @midnight-ntwrk/wallet-sdk-facade (WalletFacade combining 3 wallet types)
 * - @midnight-ntwrk/wallet-sdk-shielded (ShieldedWallet)
 * - @midnight-ntwrk/wallet-sdk-unshielded-wallet (UnshieldedWallet)
 * - @midnight-ntwrk/wallet-sdk-dust-wallet (DustWallet for fees)
 * - @midnight-ntwrk/wallet-sdk-hd (HD wallet for seed derivation)
 * - @midnight-ntwrk/ledger (ledger-v6)
 */

import { getServiceUrls, getNetworkSync } from './network.js';
import { type NetworkId, NetworkId as NetworkIdValues, type ServiceUrls, GENESIS_WALLETS, FUNDABLE_NETWORKS } from './types.js';
import { parseSeed, type ParsedSeed } from './seed.js';

/**
 * Map our internal network ID to the SDK's NetworkId string
 * SDK 3.x uses lowercase strings: 'undeployed', 'devnet', 'testnet', 'mainnet'
 */
function mapToSdkNetworkId(network: NetworkId): string {
  switch (network) {
    case NetworkIdValues.Standalone:
    case NetworkIdValues.Undeployed:
      return 'undeployed';
    case NetworkIdValues.DevNet:
      return 'devnet';
    case NetworkIdValues.TestNet:
    case NetworkIdValues.Preview:
    case NetworkIdValues.PreProd:
    case NetworkIdValues.QaNet:
      return 'testnet';
    case NetworkIdValues.MainNet:
      return 'mainnet';
    default:
      return 'undeployed';
  }
}

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
 * SDK 3.x Wallet interface
 * Contains shielded, unshielded, and dust wallet instances plus the facade
 */
export interface Sdk3Wallet {
  /** Shielded wallet for private transactions */
  shielded: any;
  /** Unshielded wallet for public transactions */
  unshielded: any;
  /** Dust wallet for fee payments */
  dust: any;
  /** Combined facade for coordinated operations */
  facade: any;
  /** Zswap secret keys for shielded operations */
  zswapSecretKeys: any;
  /** Dust secret key for fee payments */
  dustSecretKey: any;
  /** Unshielded keystore for signing */
  unshieldedKeystore: any;
  
  // Lifecycle methods
  start(): Promise<void>;
  close(): Promise<void>;
  
  // State and operations
  state(): any;
  transferTransaction(transfers: any[]): Promise<any>;
  signTransaction(tx: any): Promise<any>;
  finalizeTransaction(recipe: any): Promise<any>;
  submitTransaction(tx: any): Promise<string>;
  
  // Balance queries
  getBalances(): Promise<WalletBalances>;
}

/**
 * Wallet balances across all wallet types
 */
export interface WalletBalances {
  shielded: bigint;
  unshielded: bigint;
  dust: bigint;
  total: bigint;
}

/**
 * Wallet creation error with context
 */
export class WalletCreationError extends Error {
  public readonly cause?: Error;
  public readonly phase: string;
  
  constructor(message: string, phase: string, cause?: Error) {
    super(message);
    this.name = 'WalletCreationError';
    this.phase = phase;
    this.cause = cause;
  }
}

/**
 * Create a wallet provider using the SDK 3.x wallet-sdk packages
 * 
 * SDK 3.x uses three wallet types:
 * - ShieldedWallet: For private (shielded) transactions
 * - UnshieldedWallet: For public (unshielded) transactions
 * - DustWallet: For fee payments
 * 
 * These are combined into a WalletFacade for coordinated operations.
 * 
 * @param seedInput - Mnemonic (12-24 words) or hex seed (64 or 128 chars)
 * @param config - Provider configuration with network and URLs
 * @returns Sdk3Wallet instance
 */
export async function createWalletProvider(
  seedInput: string,
  config: ProviderConfig
): Promise<Sdk3Wallet> {
  // Validate configuration
  const validation = validateServiceConfig(config);
  if (!validation.valid) {
    throw new WalletCreationError(
      `Missing service configuration: ${validation.missing.join(', ')}. ` +
      'Set these environment variables or check your .env file.',
      'validation'
    );
  }
  
  try {
    // Parse seed input (mnemonic or hex)
    let parsedSeed: ParsedSeed;
    try {
      parsedSeed = parseSeed(seedInput);
    } catch (error) {
      throw new WalletCreationError(
        `Invalid seed: ${(error as Error).message}`,
        'seed-parsing',
        error as Error
      );
    }
    
    // SDK 3.x imports
    const { setNetworkId } = await import('@midnight-ntwrk/midnight-js-network-id');
    const { ShieldedWallet } = await import('@midnight-ntwrk/wallet-sdk-shielded');
    const { 
      UnshieldedWallet, 
      createKeystore, 
      PublicKey,
      InMemoryTransactionHistoryStorage 
    } = await import('@midnight-ntwrk/wallet-sdk-unshielded-wallet');
    const { DustWallet } = await import('@midnight-ntwrk/wallet-sdk-dust-wallet');
    const { WalletFacade } = await import('@midnight-ntwrk/wallet-sdk-facade');
    const { HDWallet, Roles } = await import('@midnight-ntwrk/wallet-sdk-hd');
    const ledger = await import('@midnight-ntwrk/ledger');

    // Set global network ID
    const networkIdStr = mapToSdkNetworkId(config.network);
    setNetworkId(networkIdStr);

    // Wallet configuration
    const walletConfig = {
      networkId: networkIdStr,
      indexerClientConnection: {
        indexerHttpUrl: config.urls.indexerUrl!,
        indexerWsUrl: config.urls.indexerWsUrl || config.urls.indexerUrl!.replace('http', 'ws'),
      },
      provingServerUrl: new URL(config.urls.proofServerUrl!),
      relayURL: new URL(config.urls.nodeWsUrl!),
    };

    // Derive seeds using HD wallet
    let shieldedSeed: Uint8Array;
    let unshieldedSeed: Uint8Array;
    let dustSeed: Uint8Array;
    
    try {
      const hdResult = HDWallet.fromSeed(parsedSeed.seed);
      if (hdResult.type !== 'seedOk') {
        throw new Error(`HD wallet initialization failed: ${hdResult.type}`);
      }
      
      const hdWallet = hdResult.hdWallet;
      const derivationResult = hdWallet
        .selectAccount(0)
        .selectRoles([Roles.Zswap, Roles.NightExternal, Roles.Dust])
        .deriveKeysAt(0);
      
      if (derivationResult.type !== 'keysDerived') {
        throw new Error(`Key derivation failed: ${derivationResult.type}`);
      }
      
      shieldedSeed = derivationResult.keys[Roles.Zswap];
      unshieldedSeed = derivationResult.keys[Roles.NightExternal];
      dustSeed = derivationResult.keys[Roles.Dust];
      
      // Clear sensitive HD wallet data
      hdWallet.clear();
    } catch (error) {
      throw new WalletCreationError(
        `Failed to derive wallet keys: ${(error as Error).message}`,
        'key-derivation',
        error as Error
      );
    }

    // Create secret keys
    const zswapSecretKeys = ledger.ZswapSecretKeys.fromSeed(shieldedSeed);
    const dustSecretKey = ledger.DustSecretKey.fromSeed(dustSeed);
    const unshieldedKeystore = createKeystore(unshieldedSeed, networkIdStr);

    // Create wallets using factory pattern
    let shieldedWallet: any;
    let unshieldedWallet: any;
    let dustWallet: any;
    
    try {
      shieldedWallet = ShieldedWallet(walletConfig).startWithSecretKeys(zswapSecretKeys);
    } catch (error) {
      throw new WalletCreationError(
        `Failed to create shielded wallet: ${(error as Error).message}`,
        'shielded-wallet',
        error as Error
      );
    }
    
    try {
      unshieldedWallet = UnshieldedWallet({
        ...walletConfig,
        txHistoryStorage: new InMemoryTransactionHistoryStorage(),
      }).startWithPublicKey(PublicKey.fromKeyStore(unshieldedKeystore));
    } catch (error) {
      throw new WalletCreationError(
        `Failed to create unshielded wallet: ${(error as Error).message}`,
        'unshielded-wallet',
        error as Error
      );
    }

    try {
      const dustParameters = ledger.LedgerParameters.initialParameters().dust;
      dustWallet = DustWallet({
        ...walletConfig,
        costParameters: {
          additionalFeeOverhead: 300_000_000_000_000n,
          feeBlocksMargin: 5,
        },
      }).startWithSecretKey(dustSecretKey, dustParameters);
    } catch (error) {
      throw new WalletCreationError(
        `Failed to create dust wallet: ${(error as Error).message}`,
        'dust-wallet',
        error as Error
      );
    }

    // Create facade
    const facade = new WalletFacade(shieldedWallet, unshieldedWallet, dustWallet);

    // Start all wallets
    try {
      await facade.start(zswapSecretKeys, dustSecretKey);
    } catch (error) {
      throw new WalletCreationError(
        `Failed to start wallets: ${(error as Error).message}`,
        'wallet-start',
        error as Error
      );
    }

    // Return combined wallet interface
    return {
      shielded: shieldedWallet,
      unshielded: unshieldedWallet,
      dust: dustWallet,
      facade,
      zswapSecretKeys,
      dustSecretKey,
      unshieldedKeystore,

      async start(): Promise<void> {
        // Already started during creation
      },

      async close(): Promise<void> {
        try {
          await facade.stop();
        } catch (error) {
          console.error('Error stopping wallet:', error);
        }
      },

      state() {
        return facade.state();
      },

      async transferTransaction(transfers: any[]): Promise<any> {
        const ttl = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes
        return facade.transferTransaction(zswapSecretKeys, dustSecretKey, transfers, ttl);
      },

      async signTransaction(tx: any): Promise<any> {
        return facade.signTransaction(tx, (payload: Uint8Array) => 
          unshieldedKeystore.signData(payload)
        );
      },

      async finalizeTransaction(recipe: any): Promise<any> {
        return facade.finalizeTransaction(recipe);
      },

      async submitTransaction(tx: any): Promise<string> {
        return facade.submitTransaction(tx);
      },

      async getBalances(): Promise<WalletBalances> {
        const { firstValueFrom } = await import('rxjs');
        const { nativeToken } = await import('@midnight-ntwrk/ledger');
        
        const state: any = await firstValueFrom(facade.state());
        const token = String(nativeToken());
        
        const shieldedBalance: bigint = state.shielded?.state?.balances?.[token] ?? 0n;
        const unshieldedBalance: bigint = state.unshielded?.balances?.[token] ?? 0n;
        const dustBalance: bigint = BigInt(state.dust?.availableCoins?.length ?? 0);
        
        return {
          shielded: shieldedBalance,
          unshielded: unshieldedBalance,
          dust: dustBalance,
          total: shieldedBalance + unshieldedBalance,
        };
      },
    };
    
  } catch (error) {
    if (error instanceof WalletCreationError) {
      throw error;
    }
    if ((error as any).code === 'ERR_MODULE_NOT_FOUND') {
      throw new WalletCreationError(
        'Midnight SDK not installed. Run `make build && make run` to build the container.',
        'module-load',
        error as Error
      );
    }
    throw new WalletCreationError(
      `Unexpected error creating wallet: ${(error as Error).message}`,
      'unknown',
      error as Error
    );
  }
}

/**
 * Create providers for contract operations
 * 
 * Returns the full set of providers needed for contract deployment
 * and interaction.
 */
export async function createContractProviders(
  seedInput: string,
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
    // @ts-ignore - SDK packages are available at runtime via file: references in package.json
    const { indexerPublicDataProvider } = await import('@midnight-ntwrk/midnight-js-indexer-public-data-provider');
    // @ts-ignore - SDK packages are available at runtime via file: references in package.json
    const { httpClientProofProvider } = await import('@midnight-ntwrk/midnight-js-http-client-proof-provider');
    // @ts-ignore - SDK packages are available at runtime via file: references in package.json
    const { levelPrivateStateProvider } = await import('@midnight-ntwrk/midnight-js-level-private-state-provider');
    // @ts-ignore - SDK packages are available at runtime via file: references in package.json
    const { NodeZkConfigProvider } = await import('@midnight-ntwrk/midnight-js-node-zk-config-provider');
    
    // Create wallet provider first
    const wallet = await createWalletProvider(seedInput, config);
    
    // Create wallet/midnight provider adapter
    const walletProvider = await createWalletMidnightProvider(wallet);
    
    return {
      privateStateProvider: levelPrivateStateProvider({
        privateStateStoreName: options.privateStateDir,
        signingKeyStoreName: `${options.privateStateDir}-signing-keys`,
        privateStoragePasswordProvider: () => 'midnight-cli-storage',
      }),
      publicDataProvider: indexerPublicDataProvider(
        config.urls.indexerUrl!,
        config.urls.indexerWsUrl || config.urls.indexerUrl!.replace('http', 'ws')
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
        'Midnight SDK not installed. Run `make build && make run` to build the container.'
      );
    }
    throw error;
  }
}

/**
 * Create a combined wallet/midnight provider from a wallet instance
 * Implements WalletProvider and MidnightProvider interfaces from SDK 3.x
 */
async function createWalletMidnightProvider(wallet: Sdk3Wallet): Promise<any> {
  const { firstValueFrom } = await import('rxjs');
  
  // Wait for initial state
  const state: any = await firstValueFrom(wallet.state());
  
  return {
    // WalletProvider interface
    async balanceTx(tx: any, newCoins?: any[], ttl?: Date): Promise<any> {
      const actualTtl = ttl || new Date(Date.now() + 30 * 60 * 1000);
      return wallet.facade.balanceTransaction(
        wallet.zswapSecretKeys,
        wallet.dustSecretKey,
        tx,
        actualTtl
      );
    },
    
    getCoinPublicKey() {
      return state.shielded?.state?.address;
    },
    
    getEncryptionPublicKey() {
      return state.shielded?.state?.encryptionPublicKey;
    },
    
    // MidnightProvider interface
    async submitTx(tx: any): Promise<string> {
      return wallet.submitTransaction(tx);
    },
  };
}

/**
 * Wait for wallet to sync and optionally have sufficient balance
 * Updated for SDK 3.x wallet state structure using WalletFacade
 */
export async function waitForWalletSync(
  wallet: Sdk3Wallet,
  options: {
    minBalance?: bigint;
    onProgress?: (state: { shielded: boolean; unshielded: boolean; dust: boolean }) => void;
    timeout?: number;
  } = {}
): Promise<{ balances: WalletBalances; synced: boolean }> {
  const { firstValueFrom, timeout: rxTimeout, filter, tap, map } = await import('rxjs');
  const { nativeToken } = await import('@midnight-ntwrk/ledger');
  
  const minBalance = options.minBalance ?? 0n;
  const timeoutMs = options.timeout ?? 120000; // 2 minutes default
  
  const stateObs = wallet.state();
  
  if (!stateObs) {
    throw new Error('Wallet does not have a state observable');
  }
  
  try {
    const result: { balances: WalletBalances; synced: boolean } = await firstValueFrom(
      stateObs.pipe(
        tap((state: any) => {
          if (options.onProgress) {
            options.onProgress({
              shielded: state.shielded?.state?.progress?.isStrictlyComplete?.() ?? false,
              unshielded: state.unshielded?.progress?.isStrictlyComplete?.() ?? false,
              dust: state.dust?.state?.progress?.isStrictlyComplete?.() ?? false,
            });
          }
        }),
        filter((state: any) => {
          // Check if all wallets are synced
          const isSynced = state.isSynced === true;
          
          if (!isSynced) return false;
          
          // Check balance if required
          if (minBalance > 0n) {
            const token = String(nativeToken());
            const shieldedBalance: bigint = state.shielded?.state?.balances?.[token] ?? 0n;
            const unshieldedBalance: bigint = state.unshielded?.balances?.[token] ?? 0n;
            const totalBalance = shieldedBalance + unshieldedBalance;
            return totalBalance >= minBalance;
          }
          
          return true;
        }),
        map((state: any): { balances: WalletBalances; synced: boolean } => {
          const token = String(nativeToken());
          const shieldedBalance: bigint = state.shielded?.state?.balances?.[token] ?? 0n;
          const unshieldedBalance: bigint = state.unshielded?.balances?.[token] ?? 0n;
          const dustCoins = state.dust?.availableCoins?.length ?? 0;
          
          return {
            balances: {
              shielded: shieldedBalance,
              unshielded: unshieldedBalance,
              dust: BigInt(dustCoins),
              total: shieldedBalance + unshieldedBalance,
            },
            synced: true,
          };
        }),
        rxTimeout(timeoutMs)
      )
    ) as { balances: WalletBalances; synced: boolean };
    
    return result;
    
  } catch (error) {
    // Timeout or other error - return current state
    try {
      const balances = await wallet.getBalances();
      return { balances, synced: false };
    } catch {
      return {
        balances: { shielded: 0n, unshielded: 0n, dust: 0n, total: 0n },
        synced: false,
      };
    }
  }
}
