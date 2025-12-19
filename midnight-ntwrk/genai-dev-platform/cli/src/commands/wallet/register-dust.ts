/**
 * midnightctl wallet register-dust [name]
 * 
 * Register a wallet address for DUST generation.
 * 
 * DUST is a non-transferable resource used for transaction fees in Midnight.
 * It regenerates over time based on NIGHT token holdings.
 * 
 * Registration is required to enable DUST regeneration for a wallet.
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

/**
 * Format a balance for display
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

export const registerDustCommand = new Command('register-dust')
  .description('Register wallet for DUST generation (fee resource)')
  .argument('[name]', 'Wallet name (uses default if not specified)')
  .option('--json', 'Output as JSON')
  .option('--debug', 'Show debug information')
  .action(async (name: string | undefined, options: { json?: boolean; debug?: boolean }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      
      // Check if toolkit is available
      const toolkitAvailable = await isToolkitAvailable();
      if (!toolkitAvailable) {
        throw new Error(
          'DUST registration requires the midnight-node-toolkit binary. ' +
          'Set MIDNIGHT_TOOLKIT_PATH or ensure the binary is installed at /usr/local/bin/midnight-node-toolkit'
        );
      }
      
      // Resolve wallet
      const wallet = await manager.resolve(name, false);
      
      if (!options.json) {
        logger.title('DUST Registration');
        console.log('');
        console.log(`  Wallet:   ${wallet.name}`);
        console.log(`  Network:  ${getNetworkDisplayName(wallet.network)}`);
        console.log(`  Address:  ${wallet.addresses.unshielded}`);
        console.log('');
        console.log('  DUST is a non-transferable resource for transaction fees.');
        console.log('  It regenerates based on your NIGHT token holdings.');
        console.log('');
      }
      
      // Create toolkit instance
      const toolkit = createToolkit({
        nodeWsUrl: config.urls.nodeWsUrl || 'ws://localhost:9944',
        network: wallet.network,
      });
      
      // Check current DUST status
      if (!options.json) {
        logger.info('Checking current DUST status...');
      }
      
      let currentBalance = 0n;
      
      try {
        const status = await toolkit.getDustStatus(wallet.seed);
        currentBalance = status.balance;
        
        if (options.debug && status.rawOutput) {
          console.log('');
          console.log('  [DEBUG] DUST status raw output:');
          console.log(`    ${status.rawOutput.split('\n').join('\n    ')}`);
        }
        
        if (currentBalance > 0n && !options.json) {
          console.log(`  Current DUST balance: ${formatBalance(currentBalance)}`);
          console.log('');
        }
      } catch (statusError) {
        if (options.debug) {
          console.log(`  [DEBUG] Status check failed: ${(statusError as Error).message}`);
        }
        // Continue with registration attempt
      }
      
      // Submit registration
      if (!options.json) {
        logger.info('Submitting DUST registration transaction...');
      }
      
      const result = await toolkit.registerForDust(wallet.seed);
      
      if (!result.success) {
        throw new Error(result.error || 'DUST registration failed');
      }
      
      if (options.debug && result.output) {
        console.log('');
        console.log('  [DEBUG] Toolkit output:');
        console.log(`    ${result.output.split('\n').join('\n    ')}`);
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          success: true,
          wallet: wallet.name,
          address: wallet.addresses.unshielded,
          txHash: result.txHash,
        }, null, 2));
      } else {
        console.log('');
        logger.success('DUST registration submitted!');
        console.log('');
        if (result.txHash && result.txHash !== 'submitted') {
          console.log(`  Transaction: ${result.txHash}`);
        }
        console.log('');
        console.log('  Your wallet will now regenerate DUST based on NIGHT holdings.');
        console.log('  Use `midnightctl wallet balance --include-dust` to check status.');
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
