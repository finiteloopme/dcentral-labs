/**
 * midnightctl wallet set-default <name>
 * 
 * Set the default wallet.
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger.js';
import { WalletManager } from '../../lib/midnight/index.js';

export const setDefaultCommand = new Command('set-default')
  .description('Set the default wallet')
  .argument('<name>', 'Wallet name')
  .option('--json', 'Output as JSON')
  .action((name: string, options: { json?: boolean }) => {
    try {
      const manager = new WalletManager();
      
      manager.setDefault(name);
      
      if (options.json) {
        console.log(JSON.stringify({ default: name }));
        return;
      }
      
      logger.success(`Default wallet set to "${name}"`);
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
