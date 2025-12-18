/**
 * midnightctl wallet send <from> <to-address> <amount>
 * 
 * Send tDUST tokens to another address.
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
  validateAddress,
  truncateAddress,
} from '../../lib/midnight/index';

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

export const sendCommand = new Command('send')
  .description('Send tDUST to another address')
  .argument('<from>', 'Source wallet name')
  .argument('<to>', 'Destination address (bech32m)')
  .argument('<amount>', 'Amount of tDUST to send')
  .option('--json', 'Output as JSON')
  .action(async (from: string, to: string, amountStr: string, options: { json?: boolean }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      
      // Validate services
      const validation = validateServiceConfig(config);
      if (!validation.valid) {
        throw new Error(
          `Services not configured: ${validation.missing.join(', ')}. ` +
          'Check your .env file.'
        );
      }
      
      // Resolve source wallet
      const sourceWallet = await manager.resolve(from, false);
      
      // Validate destination address
      const addrValidation = validateAddress(to);
      if (!addrValidation.valid) {
        throw new Error(`Invalid destination address: ${addrValidation.error}`);
      }
      
      // Parse amount (in whole units, convert to smallest unit)
      const amount = BigInt(Math.floor(parseFloat(amountStr) * 1_000_000));
      if (amount <= 0n) {
        throw new Error('Amount must be positive');
      }
      
      if (!options.json) {
        logger.title('Sending Transaction');
        console.log('');
        console.log(`  From:    ${sourceWallet.name} (${truncateAddress(sourceWallet.addresses.unshielded)})`);
        console.log(`  To:      ${truncateAddress(to)}`);
        console.log(`  Amount:  ${formatBalance(amount)} tDUST`);
        console.log('');
      }
      
      // Connect to wallet
      if (!options.json) {
        logger.info('Connecting to wallet...');
      }
      
      const wallet = await createWalletProvider(sourceWallet.seed, config);
      wallet.start();
      
      try {
        // Wait for sync
        if (!options.json) {
          console.log('  Syncing wallet...');
        }
        
        const { balance, synced } = await waitForWalletSync(wallet, {
          minBalance: amount,
          timeout: 60000,
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
          console.log('');
        }
        
        if (!synced) {
          throw new Error('Wallet sync timed out. Check service connectivity.');
        }
        
        if (balance < amount) {
          throw new Error(
            `Insufficient balance. ` +
            `Available: ${formatBalance(balance)}, Requested: ${formatBalance(amount)}`
          );
        }
        
        // Send transaction
        if (!options.json) {
          logger.info('Sending transaction...');
        }
        
        const txHash = await wallet.transfer(to, amount);
        
        if (!options.json) {
          console.log('');
        }
        
        // Get new balance
        const newBalance = balance - amount; // Approximate (doesn't include fees)
        
        if (options.json) {
          console.log(JSON.stringify({
            success: true,
            from: sourceWallet.name,
            fromAddress: sourceWallet.addresses.unshielded,
            to,
            amount: amount.toString(),
            formatted: formatBalance(amount),
            txHash,
          }, null, 2));
        } else {
          logger.success('Transaction submitted!');
          console.log('');
          console.log(`  Transaction: ${txHash}`);
          console.log(`  Amount:      ${formatBalance(amount)} tDUST`);
          console.log('');
        }
        
      } finally {
        try {
          await wallet.close();
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
