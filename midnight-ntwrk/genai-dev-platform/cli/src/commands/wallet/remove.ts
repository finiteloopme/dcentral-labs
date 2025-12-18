/**
 * midnightctl wallet remove <name>
 * 
 * Remove a wallet from storage.
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger.js';
import { WalletManager } from '../../lib/midnight/index.js';

export const removeCommand = new Command('remove')
  .description('Remove a wallet')
  .argument('<name>', 'Wallet name')
  .option('--json', 'Output as JSON')
  .action((name: string, options: { json?: boolean }) => {
    try {
      const manager = new WalletManager();
      
      // Check if wallet exists
      const wallet = manager.get(name);
      if (!wallet) {
        throw new Error(`Wallet "${name}" not found`);
      }
      
      // Remove wallet (no confirmation per user request)
      manager.remove(name);
      
      if (options.json) {
        console.log(JSON.stringify({ removed: name }));
        return;
      }
      
      logger.success(`Wallet "${name}" removed`);
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
