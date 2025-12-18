/**
 * midnightctl wallet fund <name> <amount>
 * 
 * Fund a wallet from genesis (standalone/devnet only).
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
  isFundableNetwork,
  getDefaultGenesisWallet,
  getGenesisWallet,
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

export const fundCommand = new Command('fund')
  .description('Fund a wallet from genesis (standalone/devnet only)')
  .argument('<name>', 'Wallet name to fund')
  .argument('<amount>', 'Amount of tDUST to send')
  .option('--from <index>', 'Genesis wallet index (1-4)', '1')
  .option('--json', 'Output as JSON')
  .action(async (name: string, amountStr: string, options: { from: string; json?: boolean }) => {
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
      
      // Validate network supports funding
      if (!isFundableNetwork(config.network)) {
        throw new Error(
          `Funding from genesis is only available on standalone/devnet networks. ` +
          `Current network: ${config.network}`
        );
      }
      
      // Resolve target wallet
      const targetWallet = await manager.resolve(name, false);
      
      // Parse amount (in whole units, convert to smallest unit)
      const amount = BigInt(Math.floor(parseFloat(amountStr) * 1_000_000));
      if (amount <= 0n) {
        throw new Error('Amount must be positive');
      }
      
      // Get genesis wallet
      const genesisIndex = parseInt(options.from, 10);
      const genesisWallet = getGenesisWallet(genesisIndex);
      if (!genesisWallet) {
        throw new Error(`Invalid genesis wallet index: ${options.from}. Use 1-4.`);
      }
      
      if (!options.json) {
        logger.title(`Funding Wallet: ${name}`);
        console.log('');
        console.log(`  Network:  ${getNetworkDisplayName(config.network)}`);
        console.log(`  From:     ${genesisWallet.name}`);
        console.log(`  To:       ${targetWallet.addresses.unshielded}`);
        console.log(`  Amount:   ${formatBalance(amount)} tDUST`);
        console.log('');
      }
      
      // Connect to genesis wallet
      if (!options.json) {
        logger.info('Connecting to genesis wallet...');
      }
      
      const sourceWallet = await createWalletProvider(genesisWallet.seed, config);
      sourceWallet.start();
      
      try {
        // Wait for sync
        if (!options.json) {
          console.log('  Syncing genesis wallet...');
        }
        
        const { balance: sourceBalance, synced } = await waitForWalletSync(sourceWallet, {
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
        
        if (sourceBalance < amount) {
          throw new Error(
            `Insufficient balance in genesis wallet. ` +
            `Available: ${formatBalance(sourceBalance)}, Requested: ${formatBalance(amount)}`
          );
        }
        
        // Send transaction
        if (!options.json) {
          logger.info('Sending transaction...');
        }
        
        // Use wallet SDK to send transaction
        // Note: This is a simplified version - actual implementation would use
        // the wallet's transfer method
        const txHash = await sourceWallet.transfer(
          targetWallet.addresses.unshielded,
          amount
        );
        
        if (!options.json) {
          console.log('');
        }
        
        if (options.json) {
          console.log(JSON.stringify({
            success: true,
            from: genesisWallet.name,
            to: targetWallet.name,
            toAddress: targetWallet.addresses.unshielded,
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
          console.log('  Check balance with:');
          console.log(`    midnightctl wallet balance ${name}`);
          console.log('');
        }
        
      } finally {
        try {
          await sourceWallet.close();
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
