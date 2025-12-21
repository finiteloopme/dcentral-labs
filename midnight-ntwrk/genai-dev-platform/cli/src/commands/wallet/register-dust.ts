/**
 * midnightctl wallet register-dust [name]
 * 
 * Register a wallet address for DUST generation.
 * 
 * DUST is a non-transferable resource used for transaction fees in Midnight.
 * It regenerates over time based on NIGHT token holdings.
 * 
 * Registration is required to enable DUST regeneration for a wallet.
 * 
 * Implementation:
 * - Uses SDK 3.x by default for DUST registration
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

/**
 * Format a balance for display
 */
function formatBalance(balance: bigint): string {
  const whole = balance / 1_000_000n;
  const fraction = balance % 1_000_000n;
  
  if (fraction === 0n) {
    return whole.toLocaleString() + '.00';
  }
  
  const fractionStr = fraction.toString().padStart(6, '0').replace(/0+$/, '');
  return `${whole.toLocaleString()}.${fractionStr}`;
}

export const registerDustCommand = new Command('register-dust')
  .description('Register wallet for DUST generation (fee resource)')
  .argument('[name]', 'Wallet name (uses default if not specified)')
  .option('--json', 'Output as JSON')
  .option('--use-legacy-toolkit', 'Use legacy toolkit binary instead of SDK (deprecated)')
  .option('--timeout <ms>', 'Timeout for wallet sync in milliseconds', '60000')
  .option('--debug', 'Show debug information')
  .action(async (name: string | undefined, options: { 
    json?: boolean;
    useLegacyToolkit?: boolean;
    timeout?: string;
    debug?: boolean;
  }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      const timeoutMs = parseInt(options.timeout || '60000', 10);
      
      // Debug: show service URLs
      if (options.debug) {
        console.log('');
        console.log('  [DEBUG] Service URLs:');
        console.log(`    Node WS:      ${config.urls.nodeWsUrl}`);
        console.log(`    Indexer:      ${config.urls.indexerUrl}`);
        console.log(`    Indexer WS:   ${config.urls.indexerWsUrl}`);
        console.log(`    Proof Server: ${config.urls.proofServerUrl}`);
        console.log(`    Using:        ${options.useLegacyToolkit ? 'Legacy Toolkit' : 'SDK 3.x'}`);
        console.log('');
      }
      
      // Show legacy toolkit warning if flag is used
      if (options.useLegacyToolkit && !options.json) {
        logger.showLegacyToolkitWarning();
      }
      
      // Resolve wallet
      const wallet = await manager.resolve(name, false);
      
      if (!options.json) {
        logger.title('DUST Registration');
        console.log('');
        console.log(`  Wallet:   ${wallet.name}`);
        console.log(`  Network:  ${getNetworkDisplayName(wallet.network)}`);
        console.log(`  Address:  ${wallet.addresses.unshielded}`);
        console.log(`  Method:   ${options.useLegacyToolkit ? 'Legacy Toolkit' : 'SDK 3.x'}`);
        console.log('');
        console.log('  DUST is a non-transferable resource for transaction fees.');
        console.log('  It regenerates based on your NIGHT token holdings.');
        console.log('');
      }
      
      let txHash: string;
      
      if (options.useLegacyToolkit) {
        // Legacy path: use toolkit
        txHash = await registerViaToolkit(wallet, config, options);
      } else {
        // Primary path: use SDK
        txHash = await registerViaSdk(wallet, config, { ...options, timeout: timeoutMs });
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          success: true,
          wallet: wallet.name,
          address: wallet.addresses.unshielded,
          txHash,
          method: options.useLegacyToolkit ? 'toolkit' : 'sdk',
        }, null, 2));
      } else {
        console.log('');
        logger.success('DUST registration submitted!');
        console.log('');
        if (txHash && txHash !== 'submitted') {
          console.log(`  Transaction: ${txHash}`);
        }
        console.log('');
        console.log('  Your wallet will now regenerate DUST based on NIGHT holdings.');
        console.log('  Use `midnightctl wallet balance --include-dust` to check status.');
        console.log('');
      }
      
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
 * Register for DUST via SDK 3.x
 */
async function registerViaSdk(
  wallet: any,
  config: any,
  options: { json?: boolean; debug?: boolean; timeout?: number }
): Promise<string> {
  const timeoutMs = options.timeout || 60000;
  
  if (!options.json) {
    logger.info('Connecting to wallet...');
  }
  
  const sdkWallet = await createWalletProvider(wallet.seed, config);
  
  try {
    // Wait for sync with progress indicator
    if (!options.json) {
      logger.info('Syncing wallet...');
    }
    
    const { balances, synced } = await waitForWalletSync(sdkWallet, {
      timeout: timeoutMs,
      onProgress: !options.json ? (progress) => {
        logger.showSyncProgress(progress);
      } : undefined,
    });
    
    // Clear progress line
    if (!options.json) {
      logger.clearSyncProgress();
    }
    
    if (!synced) {
      if (!options.json) {
        logger.warning(`Wallet sync timed out after ${timeoutMs}ms. Attempting registration anyway.`);
      }
    }
    
    // Show current DUST status
    if (!options.json && balances.dust > 0n) {
      console.log(`  Current DUST balance: ${formatBalance(balances.dust)}`);
      console.log('');
    }
    
    if (options.debug) {
      console.log('');
      console.log('  [DEBUG] Wallet state:');
      console.log(`    Unshielded: ${formatBalance(balances.unshielded)} NIGHT`);
      console.log(`    Shielded:   ${formatBalance(balances.shielded)} NIGHT`);
      console.log(`    DUST:       ${formatBalance(balances.dust)}`);
      console.log('');
    }
    
    // Check if wallet has unshielded NIGHT for registration
    if (balances.unshielded === 0n) {
      throw new Error(
        'No unshielded NIGHT tokens available for DUST registration. ' +
        'Fund wallet with unshielded NIGHT first using: midnightctl wallet fund ' + wallet.name + ' <amount>'
      );
    }
    
    // Submit registration
    if (!options.json) {
      logger.info('Submitting DUST registration transaction...');
    }
    
    const txHash = await sdkWallet.registerForDustGeneration();
    
    return txHash;
    
  } finally {
    try {
      await sdkWallet.close();
    } catch {
      // Ignore close errors
    }
  }
}

/**
 * Register for DUST via legacy toolkit (deprecated)
 */
async function registerViaToolkit(
  wallet: any,
  config: any,
  options: { json?: boolean; debug?: boolean }
): Promise<string> {
  // Check if toolkit is available
  const toolkitAvailable = await isToolkitAvailable();
  if (!toolkitAvailable) {
    throw new Error(
      'Legacy toolkit binary not found. ' +
      'Set MIDNIGHT_TOOLKIT_PATH or ensure the binary is installed at /usr/local/bin/midnight-node-toolkit. ' +
      'Alternatively, remove --use-legacy-toolkit to use the SDK.'
    );
  }
  
  // Create toolkit instance
  const toolkit = createToolkit({
    nodeWsUrl: config.urls.nodeWsUrl || 'ws://localhost:9944',
    network: wallet.network,
  });
  
  // Check current DUST status
  if (!options.json) {
    logger.info('Checking current DUST status...');
  }
  
  let currentBalance = 0n;
  
  try {
    const status = await toolkit.getDustStatus(wallet.seed);
    currentBalance = status.balance;
    
    if (options.debug && status.rawOutput) {
      console.log('');
      console.log('  [DEBUG] DUST status raw output:');
      console.log(`    ${status.rawOutput.split('\n').join('\n    ')}`);
    }
    
    if (currentBalance > 0n && !options.json) {
      console.log(`  Current DUST balance: ${formatBalance(currentBalance)}`);
      console.log('');
    }
  } catch (statusError) {
    if (options.debug) {
      console.log(`  [DEBUG] Status check failed: ${(statusError as Error).message}`);
    }
    // Continue with registration attempt
  }
  
  // Submit registration
  if (!options.json) {
    logger.info('Submitting DUST registration transaction...');
  }
  
  const result = await toolkit.registerForDust(wallet.seed);
  
  if (!result.success) {
    throw new Error(result.error || 'DUST registration failed');
  }
  
  if (options.debug && result.output) {
    console.log('');
    console.log('  [DEBUG] Toolkit output:');
    console.log(`    ${result.output.split('\n').join('\n    ')}`);
  }
  
  return result.txHash || 'submitted';
}
