/**
 * midnightctl wallet list
 * 
 * List all stored wallets.
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger';
import { WalletManager, getNetworkDisplayName, truncateAddress } from '../../lib/midnight/index';

export const listCommand = new Command('list')
  .description('List all wallets')
  .option('--json', 'Output as JSON')
  .action((options: { json?: boolean }) => {
    try {
      const manager = new WalletManager();
      const wallets = manager.list();
      const defaultName = manager.getDefaultName();
      
      if (options.json) {
        const output = wallets.map(w => ({
          name: w.name,
          network: w.network,
          addresses: w.addresses,
          isDefault: w.name === defaultName,
          createdAt: w.createdAt,
        }));
        console.log(JSON.stringify(output, null, 2));
        return;
      }
      
      logger.title('Wallets');
      console.log('');
      
      if (wallets.length === 0) {
        console.log('  No wallets found.');
        console.log('');
        console.log('  Create one with:');
        console.log('    midnightctl wallet create <name>');
        console.log('');
        return;
      }
      
      console.log(`  Location: .private/wallets/`);
      console.log('');
      
      for (const wallet of wallets) {
        const isDefault = wallet.name === defaultName;
        const marker = isDefault ? '\x1b[32m●\x1b[0m' : '○';
        const defaultLabel = isDefault ? ' \x1b[90m(default)\x1b[0m' : '';
        
        console.log(`  ${marker} ${wallet.name}${defaultLabel}`);
        console.log(`    Network: ${getNetworkDisplayName(wallet.network)}`);
        console.log(`    Address: ${truncateAddress(wallet.addresses.unshielded)}`);
        console.log('');
      }
      
      if (wallets.length > 1 && !defaultName) {
        logger.info('Tip: Set a default wallet with `midnightctl wallet set-default <name>`');
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
