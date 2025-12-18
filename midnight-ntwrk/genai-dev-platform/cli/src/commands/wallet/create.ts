/**
 * midnightctl wallet create <name>
 * 
 * Create a new wallet with a generated mnemonic.
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger';
import { WalletManager, getNetworkDisplayName } from '../../lib/midnight/index';

export const createCommand = new Command('create')
  .description('Create a new wallet')
  .argument('<name>', 'Wallet name')
  .option('-w, --words <count>', 'Mnemonic word count (12 or 24)', '24')
  .option('-d, --set-default', 'Set as default wallet')
  .option('--json', 'Output as JSON')
  .action(async (name: string, options: { words: string; setDefault?: boolean; json?: boolean }) => {
    try {
      const wordCount = options.words === '12' ? 12 : 24;
      
      const manager = new WalletManager();
      
      if (!options.json) {
        logger.title(`Creating Wallet: ${name}`);
        console.log('');
      }
      
      const { wallet, mnemonic } = await manager.create(name, {
        wordCount,
        setDefault: options.setDefault,
      });
      
      if (options.json) {
        // JSON output (includes mnemonic for backup)
        console.log(JSON.stringify({
          name: wallet.name,
          network: wallet.network,
          mnemonic: mnemonic,
          addresses: wallet.addresses,
          createdAt: wallet.createdAt,
        }, null, 2));
        return;
      }
      
      // Human-readable output
      console.log(`  Network:     ${getNetworkDisplayName(wallet.network)} (auto-detected)`);
      console.log('');
      
      // Display mnemonic in a grid
      console.log(`  Mnemonic (${mnemonic.length} words):`);
      console.log('');
      
      // Display in 4 columns
      const cols = 4;
      const rows = Math.ceil(mnemonic.length / cols);
      for (let row = 0; row < rows; row++) {
        const words: string[] = [];
        for (let col = 0; col < cols; col++) {
          const idx = row * cols + col;
          if (idx < mnemonic.length) {
            words.push(`${(idx + 1).toString().padStart(2)}. ${mnemonic[idx].padEnd(10)}`);
          }
        }
        console.log(`    ${words.join('  ')}`);
      }
      
      console.log('');
      console.log('\x1b[33m  ⚠ WARNING: Store this mnemonic securely!\x1b[0m');
      console.log('    Anyone with access to these words can control your wallet.');
      console.log('    Never share it with anyone.');
      console.log('');
      
      console.log('  Addresses:');
      console.log(`    Unshielded: ${wallet.addresses.unshielded}`);
      if (wallet.addresses.shielded) {
        console.log(`    Shielded:   ${wallet.addresses.shielded}`);
      }
      console.log('');
      
      logger.success(`Wallet "${name}" created and saved to .private/wallets/`);
      
      const defaultName = manager.getDefaultName();
      if (defaultName === name) {
        logger.info(`Set as default wallet`);
      }
      
      console.log('');
      console.log('  Next steps:');
      console.log(`    midnightctl wallet fund ${name} 10000  # Fund from genesis (standalone)`);
      console.log(`    midnightctl wallet balance ${name}     # Check balance`);
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
