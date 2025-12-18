/**
 * midnightctl wallet balance [name]
 * 
 * Check wallet balance.
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger';
import { 
  WalletManager, 
  getNetworkDisplayName,
  getProviderConfig,
  createWalletProvider,
  waitForWalletSync,
  validateServiceConfig,
} from '../../lib/midnight/index';

/**
 * Format a balance for display (convert from smallest unit)
 */
function formatBalance(balance: bigint): string {
  // Assuming 6 decimal places for tDUST
  const whole = balance / 1_000_000n;
  const fraction = balance % 1_000_000n;
  
  if (fraction === 0n) {
    return whole.toLocaleString() + '.00';
  }
  
  const fractionStr = fraction.toString().padStart(6, '0').replace(/0+$/, '');
  return `${whole.toLocaleString()}.${fractionStr}`;
}

export const balanceCommand = new Command('balance')
  .description('Check wallet balance')
  .argument('[name]', 'Wallet name (uses default if not specified)')
  .option('--json', 'Output as JSON')
  .option('--no-sync', 'Skip wallet sync (show cached balance)')
  .action(async (name: string | undefined, options: { json?: boolean; sync?: boolean }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      
      // Validate services are configured
      const validation = validateServiceConfig(config);
      if (!validation.valid) {
        throw new Error(
          `Services not configured: ${validation.missing.join(', ')}. ` +
          'Check your .env file or run `midnightctl services status`.'
        );
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
        console.log('\x1b[33m  ⚠ WARNING: Store this mnemonic securely!\x1b[0m');
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
      
      // Connect to wallet and sync
      if (!options.json) {
        logger.info('Connecting to services...');
      }
      
      const walletProvider = await createWalletProvider(wallet.seed, config);
      walletProvider.start();
      
      try {
        if (!options.json) {
          console.log('  Syncing wallet...');
        }
        
        const { balance, synced } = await waitForWalletSync(walletProvider, {
          timeout: 60000, // 1 minute
          onProgress: (syncedBlocks, remaining) => {
            if (!options.json) {
              const pct = remaining > 0n 
                ? Math.round(Number(syncedBlocks * 100n / (syncedBlocks + remaining)))
                : 100;
              process.stdout.write(`\r  Sync progress: ${pct}%   `);
            }
          },
        });
        
        if (!options.json) {
          console.log(''); // Clear progress line
          console.log('');
        }
        
        if (options.json) {
          console.log(JSON.stringify({
            name: wallet.name,
            network: wallet.network,
            address: wallet.addresses.unshielded,
            balance: {
              tDUST: balance.toString(),
              formatted: formatBalance(balance),
            },
            synced,
          }, null, 2));
        } else {
          console.log(`  Balance:`);
          console.log(`    tDUST: ${formatBalance(balance)}`);
          console.log('');
          
          if (balance === 0n) {
            logger.info('Wallet is unfunded.');
            logger.info(`Run \`midnightctl wallet fund ${wallet.name} 10000\` to fund from genesis.`);
            console.log('');
          }
        }
        
      } finally {
        // Close wallet connection
        try {
          await walletProvider.close();
        } catch {
          // Ignore close errors
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
