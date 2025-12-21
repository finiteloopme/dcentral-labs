/**
 * midnightctl wallet address [name]
 * 
 * Display wallet addresses.
 * 
 * Midnight wallets have three address types:
 * - Unshielded (mn_addr_...): For public/transparent transactions
 * - Shielded (mn_shield-addr_...): For private transactions
 * - DUST (mn_dust_...): For DUST generation registration
 * 
 * Implementation:
 * - Uses SDK 3.x by default to derive/fetch addresses
 * - Legacy toolkit available via --use-legacy-toolkit flag (deprecated)
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger.js';
import { 
  WalletManager, 
  getNetworkDisplayName,
  getProviderConfig,
  createToolkit,
  isToolkitAvailable,
  createWalletProvider,
  waitForWalletSync,
} from '../../lib/midnight/index.js';

export const addressCommand = new Command('address')
  .description('Display wallet addresses (unshielded, shielded, DUST)')
  .argument('[name]', 'Wallet name (uses default if not specified)')
  .option('--all', 'Get all addresses including shielded and DUST')
  .option('--json', 'Output as JSON')
  .option('--use-legacy-toolkit', 'Use legacy toolkit binary instead of SDK (deprecated)')
  .option('--timeout <ms>', 'Timeout for wallet sync in milliseconds', '30000')
  .option('--debug', 'Show debug information')
  .action(async (name: string | undefined, options: { 
    all?: boolean; 
    json?: boolean;
    useLegacyToolkit?: boolean;
    timeout?: string;
    debug?: boolean;
  }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      const timeoutMs = parseInt(options.timeout || '30000', 10);
      
      // Debug: show service URLs
      if (options.debug) {
        console.log('');
        console.log('  [DEBUG] Service URLs:');
        console.log(`    Node WS:      ${config.urls.nodeWsUrl}`);
        console.log(`    Indexer:      ${config.urls.indexerUrl}`);
        console.log(`    Using:        ${options.useLegacyToolkit ? 'Legacy Toolkit' : 'SDK 3.x'}`);
        console.log('');
      }
      
      // Show legacy toolkit warning if flag is used
      if (options.useLegacyToolkit && !options.json) {
        logger.showLegacyToolkitWarning();
      }
      
      // Resolve wallet (auto-create if needed)
      const wallet = await manager.resolve(name, true);
      
      // Initialize addresses from stored wallet
      let unshieldedAddress = wallet.addresses.unshielded;
      let shieldedAddress: string | undefined;
      let dustAddress: string | undefined;
      
      // If --all requested, get addresses from SDK or toolkit
      if (options.all) {
        if (options.useLegacyToolkit) {
          // Legacy path: use toolkit
          const result = await getAddressesViaToolkit(wallet, config, options);
          unshieldedAddress = result.unshielded || unshieldedAddress;
          shieldedAddress = result.shielded;
          dustAddress = result.dust;
        } else {
          // Primary path: use SDK
          const result = await getAddressesViaSdk(wallet, config, { ...options, timeout: timeoutMs });
          unshieldedAddress = result.unshielded || unshieldedAddress;
          shieldedAddress = result.shielded;
          dustAddress = result.dust;
        }
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          name: wallet.name,
          network: wallet.network,
          method: options.all ? (options.useLegacyToolkit ? 'toolkit' : 'sdk') : 'stored',
          addresses: {
            unshielded: unshieldedAddress,
            shielded: shieldedAddress || null,
            dust: dustAddress || null,
            coinPublicKey: wallet.addresses.coinPublicKey,
          },
        }, null, 2));
        return;
      }
      
      logger.title(`Wallet Addresses: ${wallet.name}`);
      console.log('');
      
      console.log(`  Network:       ${getNetworkDisplayName(wallet.network)}`);
      console.log('');
      
      // Unshielded address (always available)
      console.log(`  Unshielded:    ${unshieldedAddress}`);
      console.log(`                 (For public/transparent transactions)`);
      console.log('');
      
      // Shielded address
      if (shieldedAddress) {
        console.log(`  Shielded:      ${shieldedAddress}`);
        console.log(`                 (For private transactions)`);
      } else if (options.all) {
        console.log(`  Shielded:      (not available)`);
      } else {
        console.log(`  Shielded:      (use --all to fetch)`);
      }
      console.log('');
      
      // DUST address (if --all was used)
      if (options.all) {
        if (dustAddress) {
          console.log(`  DUST:          ${dustAddress}`);
          console.log(`                 (For DUST generation registration)`);
        } else {
          console.log(`  DUST:          (not available)`);
        }
        console.log('');
      }
      
      // Coin public key
      console.log(`  Coin Public:   ${wallet.addresses.coinPublicKey}`);
      console.log('');
      
      // Usage hints
      console.log('  Usage:');
      console.log('    - Share UNSHIELDED address to receive public NIGHT transfers');
      if (shieldedAddress) {
        console.log('    - Share SHIELDED address to receive private NIGHT transfers');
      }
      if (dustAddress) {
        console.log('    - Register DUST address with `midnightctl wallet register-dust` for fee resources');
      }
      console.log('');
      
    } catch (error) {
      if (options.json) {
        console.log(JSON.stringify({ error: (error as Error).message }));
      } else {
        logger.error((error as Error).message);
      }
      process.exit(1);
    }
  });

/**
 * Get addresses via SDK 3.x
 */
async function getAddressesViaSdk(
  wallet: any,
  config: any,
  options: { json?: boolean; debug?: boolean; timeout?: number }
): Promise<{ unshielded?: string; shielded?: string; dust?: string }> {
  const timeoutMs = options.timeout || 30000;
  
  if (!options.json) {
    logger.info('Fetching addresses via SDK...');
  }
  
  let sdkWallet;
  try {
    sdkWallet = await createWalletProvider(wallet.seed, config);
    
    // Wait for initial sync (quick, just need addresses)
    await waitForWalletSync(sdkWallet, {
      timeout: timeoutMs,
      onProgress: !options.json ? (progress) => {
        logger.showSyncProgress(progress);
      } : undefined,
    });
    
    // Clear progress line
    if (!options.json) {
      logger.clearSyncProgress();
    }
    
    // Get addresses from wallet state
    const { firstValueFrom } = await import('rxjs');
    const state: any = await firstValueFrom(sdkWallet.state());
    
    // Extract addresses from state
    const shieldedState = state.shielded?.state;
    const unshieldedState = state.unshielded;
    const dustState = state.dust;
    
    // Shielded address is the coin public key in encoded form
    const shieldedAddress = shieldedState?.address ? String(shieldedState.address) : undefined;
    
    // Unshielded address
    const unshieldedAddress = unshieldedState?.address ? String(unshieldedState.address) : undefined;
    
    // DUST address
    const dustAddress = dustState?.address ? String(dustState.address) : undefined;
    
    if (options.debug) {
      console.log('');
      console.log('  [DEBUG] SDK addresses:');
      console.log(`    Unshielded: ${unshieldedAddress || '(not available)'}`);
      console.log(`    Shielded:   ${shieldedAddress || '(not available)'}`);
      console.log(`    DUST:       ${dustAddress || '(not available)'}`);
      console.log('');
    }
    
    return {
      unshielded: unshieldedAddress,
      shielded: shieldedAddress,
      dust: dustAddress,
    };
    
  } catch (sdkError) {
    if (!options.json) {
      logger.clearSyncProgress();
    }
    if (options.debug) {
      console.log(`  [DEBUG] SDK error: ${(sdkError as Error).message}`);
    }
    if (!options.json) {
      logger.warning('SDK query failed, showing stored addresses only');
    }
    return {};
  } finally {
    if (sdkWallet) {
      try {
        await sdkWallet.close();
      } catch {
        // Ignore close errors
      }
    }
  }
}

/**
 * Get addresses via legacy toolkit (deprecated)
 */
async function getAddressesViaToolkit(
  wallet: any,
  config: any,
  options: { json?: boolean; debug?: boolean }
): Promise<{ unshielded?: string; shielded?: string; dust?: string }> {
  const toolkitAvailable = await isToolkitAvailable();
  
  if (!toolkitAvailable) {
    if (!options.json) {
      logger.warning('Legacy toolkit not available, showing stored addresses only');
    }
    return {};
  }
  
  if (!options.json) {
    logger.info('Querying addresses via legacy toolkit...');
  }
  
  try {
    const toolkit = createToolkit({
      nodeWsUrl: config.urls.nodeWsUrl || 'ws://localhost:9944',
      network: wallet.network,
    });
    
    const addresses = await toolkit.getAddresses(wallet.seed);
    
    if (options.debug) {
      console.log('');
      console.log('  [DEBUG] Toolkit addresses:');
      console.log(`    Unshielded: ${addresses.unshielded || '(empty)'}`);
      console.log(`    Shielded:   ${addresses.shielded || '(empty)'}`);
      console.log(`    DUST:       ${addresses.dust || '(empty)'}`);
      console.log('');
    }
    
    return {
      unshielded: addresses.unshielded || undefined,
      shielded: addresses.shielded || undefined,
      dust: addresses.dust || undefined,
    };
    
  } catch (toolkitError) {
    if (options.debug) {
      console.log(`  [DEBUG] Toolkit error: ${(toolkitError as Error).message}`);
    }
    if (!options.json) {
      logger.warning('Toolkit query failed, showing stored addresses only');
    }
    return {};
  }
}
