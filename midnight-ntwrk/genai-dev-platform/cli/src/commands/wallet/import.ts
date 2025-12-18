/**
 * midnightctl wallet import <name>
 * 
 * Import a wallet from a seed or mnemonic.
 */

import { Command } from 'commander';
import * as readline from 'readline';
import { logger } from '../../utils/logger';
import { WalletManager, getNetworkDisplayName, validateMnemonic, validateHexSeed } from '../../lib/midnight/index';

/**
 * Prompt for mnemonic phrase interactively
 */
async function promptForMnemonic(): Promise<string> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  
  return new Promise((resolve) => {
    console.log('');
    console.log('  Enter your mnemonic phrase (space-separated words):');
    console.log('');
    rl.question('  > ', (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

export const importCommand = new Command('import')
  .description('Import a wallet from seed or mnemonic')
  .argument('<name>', 'Wallet name')
  .option('-s, --seed <hex>', 'Import from hex seed')
  .option('-m, --mnemonic', 'Import from mnemonic (interactive prompt)')
  .option('-p, --passphrase <passphrase>', 'BIP39 passphrase for mnemonic')
  .option('-d, --set-default', 'Set as default wallet')
  .option('--json', 'Output as JSON')
  .action(async (name: string, options: { 
    seed?: string; 
    mnemonic?: boolean; 
    passphrase?: string;
    setDefault?: boolean; 
    json?: boolean;
  }) => {
    try {
      // Validate options
      if (!options.seed && !options.mnemonic) {
        throw new Error('Specify --seed <hex> or --mnemonic to import a wallet');
      }
      
      if (options.seed && options.mnemonic) {
        throw new Error('Cannot use both --seed and --mnemonic. Choose one.');
      }
      
      const manager = new WalletManager();
      let wallet;
      
      if (options.seed) {
        // Import from hex seed
        const validation = validateHexSeed(options.seed);
        if (!validation.valid) {
          throw new Error(validation.error);
        }
        
        if (!options.json) {
          logger.title(`Importing Wallet: ${name}`);
          console.log('');
          console.log('  Source: Hex seed');
          console.log('');
        }
        
        wallet = await manager.importFromSeed(name, options.seed, {
          setDefault: options.setDefault,
        });
        
      } else {
        // Import from mnemonic
        if (!options.json) {
          logger.title(`Importing Wallet: ${name}`);
        }
        
        const mnemonicStr = await promptForMnemonic();
        
        const validation = validateMnemonic(mnemonicStr);
        if (!validation.valid) {
          throw new Error(validation.error);
        }
        
        if (!options.json) {
          console.log('');
          console.log('  Source: Mnemonic phrase');
          console.log('');
        }
        
        wallet = await manager.importFromMnemonic(name, mnemonicStr, {
          setDefault: options.setDefault,
          passphrase: options.passphrase,
        });
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          name: wallet.name,
          network: wallet.network,
          addresses: wallet.addresses,
          createdAt: wallet.createdAt,
        }, null, 2));
        return;
      }
      
      // Human-readable output
      console.log(`  Network:     ${getNetworkDisplayName(wallet.network)}`);
      console.log('');
      console.log('  Addresses:');
      console.log(`    Unshielded: ${wallet.addresses.unshielded}`);
      if (wallet.addresses.shielded) {
        console.log(`    Shielded:   ${wallet.addresses.shielded}`);
      }
      console.log('');
      
      logger.success(`Wallet "${name}" imported and saved to .private/wallets/`);
      
      const defaultName = manager.getDefaultName();
      if (defaultName === name) {
        logger.info(`Set as default wallet`);
      }
      
      console.log('');
      
    } catch (error) {
      if (options.json) {
        console.log(JSON.stringify({ error: (error as Error).message }));
      } else {
        console.log('');
        logger.error((error as Error).message);
      }
      process.exit(1);
    }
  });
