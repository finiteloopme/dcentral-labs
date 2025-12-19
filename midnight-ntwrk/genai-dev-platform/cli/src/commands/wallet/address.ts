/**
 * midnightctl wallet address [name]
 * 
 * Display wallet addresses.
 * 
 * Midnight wallets have three address types:
 * - Unshielded (mn_addr_...): For public/transparent transactions
 * - Shielded (mn_shield-addr_...): For private transactions
 * - DUST (mn_dust_...): For DUST generation registration
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger.js';
import { 
  WalletManager, 
  getNetworkDisplayName,
  getProviderConfig,
  createToolkit,
  isToolkitAvailable,
} from '../../lib/midnight/index.js';

export const addressCommand = new Command('address')
  .description('Display wallet addresses (unshielded, shielded, DUST)')
  .argument('[name]', 'Wallet name (uses default if not specified)')
  .option('--all', 'Get all addresses including shielded and DUST (requires toolkit)')
  .option('--json', 'Output as JSON')
  .option('--debug', 'Show debug information')
  .action(async (name: string | undefined, options: { all?: boolean; json?: boolean; debug?: boolean }) => {
    try {
      const manager = new WalletManager();
      
      // Resolve wallet (auto-create if needed)
      const wallet = await manager.resolve(name, true);
      
      // Initialize addresses from stored wallet
      let unshieldedAddress = wallet.addresses.unshielded;
      let shieldedAddress: string | undefined;
      let dustAddress: string | undefined;
      
      // If --all requested, get addresses from toolkit
      if (options.all) {
        const toolkitAvailable = await isToolkitAvailable();
        
        if (toolkitAvailable) {
          if (!options.json) {
            logger.info('Querying addresses via toolkit...');
          }
          
          try {
            const config = getProviderConfig();
            const toolkit = createToolkit({
              nodeWsUrl: config.urls.nodeWsUrl || 'ws://localhost:9944',
              network: wallet.network,
            });
            
            const addresses = await toolkit.getAddresses(wallet.seed);
            
            // Use toolkit addresses if available
            if (addresses.unshielded) {
              unshieldedAddress = addresses.unshielded;
            }
            shieldedAddress = addresses.shielded || undefined;
            dustAddress = addresses.dust || undefined;
            
            if (options.debug) {
              console.log('');
              console.log('  [DEBUG] Toolkit addresses:');
              console.log(`    Unshielded: ${addresses.unshielded || '(empty)'}`);
              console.log(`    Shielded:   ${addresses.shielded || '(empty)'}`);
              console.log(`    DUST:       ${addresses.dust || '(empty)'}`);
              console.log('');
            }
          } catch (toolkitError) {
            if (options.debug) {
              console.log(`  [DEBUG] Toolkit error: ${(toolkitError as Error).message}`);
            }
            if (!options.json) {
              logger.info('Toolkit query failed, showing stored addresses only');
            }
          }
        } else if (!options.json) {
          logger.info('Toolkit not available, showing stored addresses only');
        }
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          name: wallet.name,
          network: wallet.network,
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
