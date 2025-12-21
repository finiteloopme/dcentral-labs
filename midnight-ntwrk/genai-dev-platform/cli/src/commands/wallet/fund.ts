/**
 * midnightctl wallet fund <name> <amount>
 * 
 * Fund a wallet from genesis (standalone/devnet only).
 * 
 * Implementation:
 * - Uses SDK 3.x by default for unshielded transfers
 * - Legacy toolkit available via --use-legacy-toolkit flag (deprecated)
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger.js';
import { 
  WalletManager, 
  getNetworkDisplayName,
  getProviderConfig,
  isFundableNetwork,
  getGenesisWallet,
  createToolkit,
  isToolkitAvailable,
  createWalletProvider,
  waitForWalletSync,
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
  .option('--use-toolkit', 'Use toolkit binary instead of SDK (deprecated)')
  .option('--timeout <ms>', 'Timeout for wallet sync in milliseconds', '120000')
  .option('--debug', 'Show debug information including service URLs')
  .action(async (name: string, amountStr: string, options: { 
    from: string; 
    json?: boolean;
    useToolkit?: boolean;
    timeout?: string;
    debug?: boolean;
  }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      const timeoutMs = parseInt(options.timeout || '60000', 10);
      
      // Debug: show service URLs
      const useToolkit = options.useToolkit === true;
      
      if (options.debug) {
        console.log('');
        console.log('  [DEBUG] Service URLs:');
        console.log(`    Node WS:      ${config.urls.nodeWsUrl}`);
        console.log(`    Indexer:      ${config.urls.indexerUrl}`);
        console.log(`    Indexer WS:   ${config.urls.indexerWsUrl}`);
        console.log(`    Proof Server: ${config.urls.proofServerUrl}`);
        console.log(`    Using:        ${useToolkit ? 'Toolkit (deprecated)' : 'SDK 3.x'}`);
        console.log('');
      }
      
      // Show deprecation warning if toolkit is used
      if (useToolkit && !options.json) {
        logger.warning('--use-toolkit is deprecated. SDK 3.x is now the default.');
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
        console.log(`  Method:   ${useToolkit ? 'Toolkit' : 'SDK 3.x'}`);
        console.log('');
      }
      
      let txHash: string;
      
      if (useToolkit) {
        // Deprecated: use toolkit for unshielded transfers
        txHash = await fundViaToolkit(genesisWallet, targetAddress, amount, config, options);
      } else {
        // Primary path: use SDK 3.x for unshielded transfers
        txHash = await fundViaSdk(genesisWallet, targetAddress, amount, config, { ...options, timeout: timeoutMs });
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          success: true,
          from: genesisWallet.name,
          to: targetWallet.name,
          toAddress: targetAddress,
          amount: amount.toString(),
          formatted: formatBalance(amount),
          txHash,
          method: useToolkit ? 'toolkit' : 'sdk',
        }, null, 2));
      } else {
        logger.success('Transaction submitted!');
        console.log('');
        if (txHash && txHash !== 'submitted') {
          console.log(`  Transaction: ${txHash}`);
        }
        console.log(`  Amount:      ${formatBalance(amount)} NIGHT`);
        console.log('');
        console.log('  Check balance with:');
        console.log(`    midnightctl wallet balance ${name}`);
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

/**
 * Fund via SDK 3.x unshielded transfer
 */
async function fundViaSdk(
  genesisWallet: { seed: string; name: string },
  targetAddress: string,
  amount: bigint,
  config: any,
  options: { json?: boolean; debug?: boolean; timeout?: number }
): Promise<string> {
  const timeoutMs = options.timeout || 60000;
  
  if (!options.json) {
    logger.info('Connecting to genesis wallet...');
  }
  
  // Create wallet using SDK 3.x with standard BIP44 HD derivation
  const wallet = await createWalletProvider(genesisWallet.seed, config);
  
  try {
    // Wait for sync with progress indicator
    if (!options.json) {
      logger.info('Syncing genesis wallet...');
    }
    
    const { balances, synced } = await waitForWalletSync(wallet, {
      minBalance: amount,
      timeout: timeoutMs,
      onProgress: !options.json ? (progress) => {
        logger.showSyncProgress(progress);
      } : undefined,
    });
    
    // Clear progress line
    if (!options.json) {
      logger.clearSyncProgress();
    }
    
    if (!synced) {
      if (!options.json) {
        logger.warning(`Wallet sync timed out after ${timeoutMs}ms. Attempting transfer anyway.`);
      }
    }
    
    // Check unshielded balance (genesis wallets have unshielded NIGHT)
    if (balances.unshielded < amount) {
      throw new Error(
        `Insufficient unshielded balance in genesis wallet. ` +
        `Available: ${formatBalance(balances.unshielded)}, Requested: ${formatBalance(amount)}`
      );
    }
    
    if (options.debug) {
      console.log('');
      console.log('  [DEBUG] Genesis wallet state:');
      console.log(`    Unshielded: ${formatBalance(balances.unshielded)} NIGHT`);
      console.log(`    Shielded:   ${formatBalance(balances.shielded)} NIGHT`);
      console.log(`    DUST:       ${formatBalance(balances.dust)}`);
      console.log('');
    }
    
    if (!options.json) {
      logger.info('Sending unshielded transfer...');
      console.log('  This may take a minute while the transaction is processed...');
    }
    
    // Use the sendUnshielded method
    const txHash = await wallet.sendUnshielded(targetAddress, amount);
    
    if (!options.json) {
      console.log('');
    }
    
    return txHash;
    
  } finally {
    try {
      await wallet.close();
    } catch {
      // Ignore close errors
    }
  }
}

/**
 * Fund via legacy toolkit binary (deprecated)
 */
async function fundViaToolkit(
  genesisWallet: { seed: string; name: string },
  targetAddress: string,
  amount: bigint,
  config: any,
  options: { json?: boolean; debug?: boolean }
): Promise<string> {
  // Check toolkit availability
  if (!(await isToolkitAvailable())) {
    throw new Error(
      'Legacy toolkit binary not found. ' +
      'Set MIDNIGHT_TOOLKIT_PATH or ensure the binary is installed at /usr/local/bin/midnight-node-toolkit. ' +
      'Alternatively, remove --use-legacy-toolkit to use the SDK.'
    );
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
  
  if (options.debug && result.output) {
    console.log('  [DEBUG] Toolkit output:');
    console.log(result.output.split('\n').map(l => `    ${l}`).join('\n'));
  }
  
  return result.txHash || 'submitted';
}
