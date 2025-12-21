/**
 * midnightctl wallet balance [name]
 * 
 * Check wallet balance. Shows both shielded (private) and unshielded (public) NIGHT balances.
 * Optionally shows DUST resource status.
 * 
 * Token Model:
 * - NIGHT: Native token, can be shielded (private) or unshielded (public)
 * - DUST: Non-transferable resource for transaction fees, regenerates based on NIGHT holdings
 * 
 * Implementation:
 * - Uses SDK 3.x by default for balance queries
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
 * Format a balance for display (convert from smallest unit)
 * NIGHT uses 6 decimal places
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

export const balanceCommand = new Command('balance')
  .description('Check wallet balance (shielded + unshielded NIGHT)')
  .argument('[name]', 'Wallet name (uses default if not specified)')
  .option('--json', 'Output as JSON')
  .option('--include-dust', 'Show DUST resource status')
  .option('--use-legacy-toolkit', 'Use legacy toolkit binary instead of SDK (deprecated)')
  .option('--timeout <ms>', 'Timeout for wallet sync in milliseconds', '60000')
  .option('--debug', 'Show debug information including service URLs')
  .action(async (name: string | undefined, options: { 
    json?: boolean; 
    includeDust?: boolean; 
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
      
      // Resolve wallet (auto-create if needed)
      const result = await manager.getOrCreateDefault();
      
      if (result.created && !options.json) {
        // Show mnemonic for newly created wallet
        logger.title('No wallets found. Creating default wallet...');
        console.log('');
        
        console.log(`  Mnemonic (${result.mnemonic!.length} words):`);
        const cols = 4;
        const rows = Math.ceil(result.mnemonic!.length / cols);
        for (let row = 0; row < rows; row++) {
          const words: string[] = [];
          for (let col = 0; col < cols; col++) {
            const idx = row * cols + col;
            if (idx < result.mnemonic!.length) {
              words.push(`${(idx + 1).toString().padStart(2)}. ${result.mnemonic![idx].padEnd(10)}`);
            }
          }
          console.log(`    ${words.join('  ')}`);
        }
        console.log('');
        console.log('\x1b[33m  WARNING: Store this mnemonic securely!\x1b[0m');
        console.log('');
      }
      
      const wallet = name ? await manager.resolve(name, false) : result.wallet;
      
      if (!options.json) {
        logger.title(`Wallet Balance: ${wallet.name}`);
        console.log('');
        console.log(`  Network:     ${getNetworkDisplayName(wallet.network)}`);
        console.log(`  Address:     ${wallet.addresses.unshielded}`);
        console.log('');
      }
      
      // Initialize balances
      let shieldedBalance = 0n;
      let unshieldedBalance = 0n;
      let dustBalance = 0n;
      let method = 'sdk';
      
      if (options.useLegacyToolkit) {
        // Legacy path: use toolkit binary
        method = 'toolkit';
        const toolkitAvailable = await isToolkitAvailable();
        
        if (!toolkitAvailable) {
          throw new Error(
            'Legacy toolkit binary not found. ' +
            'Set MIDNIGHT_TOOLKIT_PATH or ensure the binary is installed at /usr/local/bin/midnight-node-toolkit. ' +
            'Alternatively, remove --use-legacy-toolkit to use the SDK.'
          );
        }
        
        if (!options.json) {
          logger.info('Querying wallet balance via legacy toolkit...');
        }
        
        const toolkit = createToolkit({
          nodeWsUrl: config.urls.nodeWsUrl || 'ws://localhost:9944',
          network: wallet.network,
        });
        
        try {
          const balanceInfo = await toolkit.getWalletBalance(wallet.seed);
          
          shieldedBalance = balanceInfo.shieldedBalance;
          unshieldedBalance = balanceInfo.unshieldedBalance;
          dustBalance = balanceInfo.dustBalance;
          
          if (options.debug && balanceInfo.rawState) {
            console.log('');
            console.log('  [DEBUG] Raw wallet state:');
            console.log(`    ${JSON.stringify(balanceInfo.rawState, null, 2).split('\n').join('\n    ')}`);
            console.log('');
          }
          
        } catch (toolkitError) {
          if (!options.json) {
            logger.error(`Toolkit query failed: ${(toolkitError as Error).message}`);
          }
          throw toolkitError;
        }
        
        // Get separate DUST status if requested and not already retrieved
        if (options.includeDust && dustBalance === 0n) {
          try {
            if (!options.json) {
              logger.info('Querying DUST resource status...');
            }
            
            const dustStatus = await toolkit.getDustStatus(wallet.seed);
            dustBalance = dustStatus.balance;
            
            if (options.debug && dustStatus.rawOutput) {
              console.log('');
              console.log('  [DEBUG] DUST balance raw output:');
              console.log(`    ${dustStatus.rawOutput.split('\n').join('\n    ')}`);
            }
          } catch (dustError) {
            if (options.debug) {
              console.log(`  [DEBUG] DUST query failed: ${(dustError as Error).message}`);
            }
            // DUST query failed, but continue with balance display
          }
        }
        
      } else {
        // Primary path: use SDK 3.x
        if (!options.json) {
          logger.info('Syncing wallet via SDK...');
        }
        
        let sdkWallet;
        try {
          sdkWallet = await createWalletProvider(wallet.seed, config);
          
          // Wait for sync with progress indicator
          const syncResult = await waitForWalletSync(sdkWallet, {
            timeout: timeoutMs,
            onProgress: !options.json ? (progress) => {
              logger.showSyncProgress(progress);
            } : undefined,
          });
          
          // Clear progress line
          if (!options.json) {
            logger.clearSyncProgress();
          }
          
          if (!syncResult.synced) {
            if (!options.json) {
              logger.warning(`Wallet sync timed out after ${timeoutMs}ms. Showing partial balances.`);
            }
          }
          
          // Get balances
          const balances = await sdkWallet.getBalances();
          shieldedBalance = balances.shielded;
          unshieldedBalance = balances.unshielded;
          dustBalance = balances.dust;
          
          if (options.debug) {
            console.log('');
            console.log('  [DEBUG] SDK wallet state:');
            console.log(`    Synced: ${syncResult.synced}`);
            console.log(`    Shielded: ${shieldedBalance}`);
            console.log(`    Unshielded: ${unshieldedBalance}`);
            console.log(`    DUST: ${dustBalance}`);
            console.log('');
          }
          
        } catch (sdkError) {
          if (!options.json) {
            logger.clearSyncProgress();
            logger.error(`SDK query failed: ${(sdkError as Error).message}`);
          }
          throw sdkError;
        } finally {
          // Always close wallet connection
          if (sdkWallet) {
            try {
              await sdkWallet.close();
            } catch {
              // Ignore close errors
            }
          }
        }
      }
      
      // Calculate total NIGHT balance
      const totalBalance = shieldedBalance + unshieldedBalance;
      
      if (options.json) {
        const jsonOutput: Record<string, any> = {
          name: wallet.name,
          network: wallet.network,
          address: wallet.addresses.unshielded,
          method,
          balances: {
            shielded: {
              NIGHT: shieldedBalance.toString(),
              formatted: formatBalance(shieldedBalance),
            },
            unshielded: {
              NIGHT: unshieldedBalance.toString(),
              formatted: formatBalance(unshieldedBalance),
            },
            total: {
              NIGHT: totalBalance.toString(),
              formatted: formatBalance(totalBalance),
            },
          },
        };
        
        if (options.includeDust) {
          jsonOutput.dust = {
            balance: dustBalance.toString(),
            formatted: formatBalance(dustBalance),
          };
        }
        
        console.log(JSON.stringify(jsonOutput, null, 2));
      } else {
        console.log('');
        console.log(`  NIGHT Balances:`);
        console.log(`    Shielded (private):   ${formatBalance(shieldedBalance)} NIGHT`);
        console.log(`    Unshielded (public):  ${formatBalance(unshieldedBalance)} NIGHT`);
        console.log(`    ────────────────────────────────`);
        console.log(`    Total:                ${formatBalance(totalBalance)} NIGHT`);
        console.log('');
        
        if (options.includeDust) {
          console.log(`  DUST Resource:`);
          console.log(`    Balance:     ${formatBalance(dustBalance)} DUST`);
          console.log('');
        }
        
        if (totalBalance === 0n) {
          logger.info('Wallet is unfunded.');
          logger.info(`Run \`midnightctl wallet fund ${wallet.name} 10000\` to fund from genesis.`);
          console.log('');
        }
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
