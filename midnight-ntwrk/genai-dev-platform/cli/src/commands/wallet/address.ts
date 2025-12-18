/**
 * midnightctl wallet address [name]
 * 
 * Display wallet addresses.
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger.js';
import { 
  WalletManager, 
  getNetworkDisplayName,
  getProviderConfig,
  createWalletProvider,
  validateServiceConfig,
} from '../../lib/midnight/index.js';

export const addressCommand = new Command('address')
  .description('Display wallet addresses')
  .argument('[name]', 'Wallet name (uses default if not specified)')
  .option('--shielded', 'Get shielded address by connecting to Midnight services')
  .option('--json', 'Output as JSON')
  .action(async (name: string | undefined, options: { shielded?: boolean; json?: boolean }) => {
    try {
      const manager = new WalletManager();
      
      // Resolve wallet (auto-create if needed)
      const wallet = await manager.resolve(name, true);
      
      // If --shielded requested, we need to connect to the SDK
      let shieldedAddress: string | undefined = wallet.addresses.shielded;
      
      if (options.shielded && !shieldedAddress) {
        const config = getProviderConfig();
        
        // Validate services
        const validation = validateServiceConfig(config);
        if (!validation.valid) {
          throw new Error(
            `Services not configured: ${validation.missing.join(', ')}. ` +
            'The --shielded option requires Midnight services to be running.'
          );
        }
        
        if (!options.json) {
          logger.info('Connecting to Midnight services to get shielded address...');
        }
        
        const { firstValueFrom } = await import('rxjs');
        const walletProvider = await createWalletProvider(wallet.seed, config);
        walletProvider.start();
        
        try {
          const state: any = await firstValueFrom(walletProvider.state());
          shieldedAddress = state.address;
        } finally {
          try {
            await walletProvider.close();
          } catch {
            // Ignore close errors
          }
        }
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          name: wallet.name,
          network: wallet.network,
          addresses: {
            ...wallet.addresses,
            shielded: shieldedAddress,
          },
        }, null, 2));
        return;
      }
      
      logger.title(`Wallet Addresses: ${wallet.name}`);
      console.log('');
      
      console.log(`  Network:       ${getNetworkDisplayName(wallet.network)}`);
      console.log('');
      console.log(`  Unshielded:    ${wallet.addresses.unshielded}`);
      
      if (shieldedAddress) {
        console.log(`  Shielded:      ${shieldedAddress}`);
      } else if (options.shielded) {
        console.log(`  Shielded:      (failed to retrieve)`);
      } else {
        console.log(`  Shielded:      (use --shielded to fetch from network)`);
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
