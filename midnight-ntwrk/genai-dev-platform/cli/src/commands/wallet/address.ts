/**
 * midnightctl wallet address [name]
 * 
 * Display wallet addresses.
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger';
import { WalletManager, getNetworkDisplayName } from '../../lib/midnight/index';

export const addressCommand = new Command('address')
  .description('Display wallet addresses')
  .argument('[name]', 'Wallet name (uses default if not specified)')
  .option('--json', 'Output as JSON')
  .action(async (name: string | undefined, options: { json?: boolean }) => {
    try {
      const manager = new WalletManager();
      
      // Resolve wallet (auto-create if needed)
      const wallet = await manager.resolve(name, true);
      
      if (options.json) {
        console.log(JSON.stringify({
          name: wallet.name,
          network: wallet.network,
          addresses: wallet.addresses,
        }, null, 2));
        return;
      }
      
      logger.title(`Wallet Addresses: ${wallet.name}`);
      console.log('');
      
      console.log(`  Network:       ${getNetworkDisplayName(wallet.network)}`);
      console.log('');
      console.log(`  Unshielded:    ${wallet.addresses.unshielded}`);
      
      if (wallet.addresses.shielded) {
        console.log(`  Shielded:      ${wallet.addresses.shielded}`);
      }
      
      console.log(`  Coin Public:   ${wallet.addresses.coinPublicKey}`);
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
