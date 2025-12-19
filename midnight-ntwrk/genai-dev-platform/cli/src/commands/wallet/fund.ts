/**
 * midnightctl wallet fund <name> <amount>
 * 
 * Fund a wallet from genesis (standalone/devnet only).
 * 
 * Uses the midnight-node-toolkit for unshielded transfers, avoiding
 * SDK/Indexer GraphQL compatibility issues.
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger.js';
import { 
  WalletManager, 
  getNetworkDisplayName,
  getProviderConfig,
  validateServiceConfig,
  isFundableNetwork,
  getGenesisWallet,
  createToolkit,
  isToolkitAvailable,
} from '../../lib/midnight/index.js';

/**
 * Format a balance for display (raw units to human-readable)
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
  .argument('<amount>', 'Amount of NIGHT tokens to send')
  .option('--from <index>', 'Genesis wallet index (1-4)', '1')
  .option('--json', 'Output as JSON')
  .option('--debug', 'Show debug information including service URLs')
  .action(async (name: string, amountStr: string, options: { from: string; json?: boolean; debug?: boolean }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      
      // Check toolkit availability first
      if (!(await isToolkitAvailable())) {
        throw new Error(
          'Toolkit binary not found. The midnight-node-toolkit is required for funding operations.\n' +
          'Set MIDNIGHT_TOOLKIT_PATH environment variable or ensure the binary is installed at /usr/local/bin/midnight-node-toolkit'
        );
      }
      
      // Debug: show service URLs
      if (options.debug) {
        console.log('');
        console.log('  [DEBUG] Service URLs:');
        console.log(`    Node WS:      ${config.urls.nodeWsUrl}`);
        console.log(`    Indexer:      ${config.urls.indexerUrl}`);
        console.log(`    Indexer WS:   ${config.urls.indexerWsUrl}`);
        console.log(`    Proof Server: ${config.urls.proofServerUrl}`);
        console.log('');
      }
      
      // Validate services (only need node for toolkit-based transfers)
      if (!config.urls.nodeWsUrl) {
        throw new Error(
          'MIDNIGHT_NODE_URL not configured. Check your .env file.'
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
      
      // Parse amount (in whole units, convert to smallest unit - 6 decimal places)
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
      
      // Use the target wallet's UNSHIELDED address from stored metadata
      // Genesis wallets have unshielded NIGHT tokens, so we send to unshielded addresses
      const targetAddress = targetWallet.addresses.unshielded;
      if (!targetAddress) {
        throw new Error('Target wallet does not have an unshielded address');
      }
      
      if (!options.json) {
        logger.title(`Funding Wallet: ${name}`);
        console.log('');
        console.log(`  Network:  ${getNetworkDisplayName(config.network)}`);
        console.log(`  From:     ${genesisWallet.name}`);
        console.log(`  To:       ${targetAddress}`);
        console.log(`  Amount:   ${formatBalance(amount)} NIGHT`);
        console.log('');
      }
      
      // Create toolkit instance
      const toolkit = createToolkit({
        nodeWsUrl: config.urls.nodeWsUrl,
        network: config.network,
      });
      
      // Check genesis wallet balance first (optional but helpful for user feedback)
      if (!options.json) {
        logger.info('Checking genesis wallet balance...');
      }
      
      try {
        const genesisBalance = await toolkit.getWalletBalance(genesisWallet.seed);
        const availableBalance = genesisBalance.unshieldedBalance;
        
        if (options.debug) {
          console.log('');
          console.log('  [DEBUG] Genesis wallet state:');
          console.log(`    Unshielded: ${formatBalance(availableBalance)} NIGHT`);
          console.log(`    Shielded:   ${formatBalance(genesisBalance.shieldedBalance)} NIGHT`);
          console.log(`    DUST:       ${formatBalance(genesisBalance.dustBalance)}`);
          console.log('');
        }
        
        if (availableBalance < amount) {
          throw new Error(
            `Insufficient unshielded balance in genesis wallet. ` +
            `Available: ${formatBalance(availableBalance)} NIGHT, Requested: ${formatBalance(amount)} NIGHT`
          );
        }
      } catch (balanceError: any) {
        // Balance check failed - continue anyway, the transfer will fail if insufficient
        if (options.debug) {
          console.log(`  [DEBUG] Balance check failed: ${balanceError.message}`);
          console.log('  [DEBUG] Proceeding with transfer anyway...');
        }
      }
      
      // Send unshielded transfer using toolkit
      if (!options.json) {
        logger.info('Sending unshielded transfer...');
        console.log('  This may take a minute while the transaction is processed...');
      }
      
      const result = await toolkit.sendUnshielded(
        genesisWallet.seed,
        targetAddress,
        amount
      );
      
      if (!result.success) {
        // Include raw output in debug mode
        if (options.debug && result.output) {
          console.log('');
          console.log('  [DEBUG] Toolkit output:');
          console.log(result.output.split('\n').map(l => `    ${l}`).join('\n'));
        }
        throw new Error(result.error || 'Transfer failed');
      }
      
      if (!options.json) {
        console.log('');
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          success: true,
          from: genesisWallet.name,
          to: targetWallet.name,
          toAddress: targetAddress,
          amount: amount.toString(),
          formatted: formatBalance(amount),
          txHash: result.txHash,
        }, null, 2));
      } else {
        logger.success('Transaction submitted!');
        console.log('');
        if (result.txHash && result.txHash !== 'submitted') {
          console.log(`  Transaction: ${result.txHash}`);
        }
        console.log(`  Amount:      ${formatBalance(amount)} NIGHT`);
        console.log('');
        console.log('  Check balance with:');
        console.log(`    midnightctl wallet balance ${name}`);
        console.log('');
        
        if (options.debug && result.output) {
          console.log('  [DEBUG] Toolkit output:');
          console.log(result.output.split('\n').map(l => `    ${l}`).join('\n'));
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
