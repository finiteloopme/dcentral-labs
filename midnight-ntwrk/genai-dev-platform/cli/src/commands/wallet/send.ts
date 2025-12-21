/**
 * midnightctl wallet send <from> <to-address> <amount>
 * 
 * Send NIGHT tokens to another address.
 * 
 * Automatically detects address type:
 * - Shielded addresses (mn_shield-addr_...): Uses SDK shielded transfer (Zswap)
 * - Unshielded addresses (mn_addr_...): Uses SDK unshielded transfer
 * 
 * Implementation:
 * - Uses SDK 3.x by default for all transfers (shielded and unshielded)
 * - Legacy toolkit available via --use-legacy-toolkit flag (deprecated)
 */

import { Command } from 'commander';
import { logger } from '../../utils/logger.js';
import { 
  WalletManager, 
  getProviderConfig,
  createWalletProvider,
  waitForWalletSync,
  validateServiceConfig,
  validateAddress,
  truncateAddress,
  detectAddressType,
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

export const sendCommand = new Command('send')
  .description('Send NIGHT to another address (auto-detects shielded vs unshielded)')
  .argument('<from>', 'Source wallet name')
  .argument('<to>', 'Destination address (shielded or unshielded)')
  .argument('<amount>', 'Amount of NIGHT to send')
  .option('--json', 'Output as JSON')
  .option('--force-shielded', 'Force shielded transfer even for unshielded addresses')
  .option('--force-unshielded', 'Force unshielded transfer even for shielded addresses')
  .option('--use-legacy-toolkit', 'Use legacy toolkit binary instead of SDK (deprecated)')
  .option('--timeout <ms>', 'Timeout for wallet sync in milliseconds', '60000')
  .option('--debug', 'Show debug information including service URLs')
  .action(async (from: string, to: string, amountStr: string, options: { 
    json?: boolean; 
    forceShielded?: boolean; 
    forceUnshielded?: boolean;
    useLegacyToolkit?: boolean;
    timeout?: string;
    debug?: boolean;
  }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      const timeoutMs = parseInt(options.timeout || '60000', 10);
      
      // Debug: show service URLs
      if (options.debug) {
        console.log('');
        console.log('  [DEBUG] Service URLs:');
        console.log(`    Node WS:      ${config.urls.nodeWsUrl}`);
        console.log(`    Indexer:      ${config.urls.indexerUrl}`);
        console.log(`    Indexer WS:   ${config.urls.indexerWsUrl}`);
        console.log(`    Proof Server: ${config.urls.proofServerUrl}`);
        console.log(`    Using:        ${options.useLegacyToolkit ? 'Legacy Toolkit' : 'SDK 3.x'}`);
        console.log('');
      }
      
      // Show legacy toolkit warning if flag is used
      if (options.useLegacyToolkit && !options.json) {
        logger.showLegacyToolkitWarning();
      }
      
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
      
      // Detect address type to determine transfer method
      const addrInfo = detectAddressType(to);
      
      // Determine transfer method
      let useShieldedTransfer: boolean;
      
      if (options.forceShielded && options.forceUnshielded) {
        throw new Error('Cannot use both --force-shielded and --force-unshielded');
      } else if (options.forceShielded) {
        useShieldedTransfer = true;
        if (addrInfo.type === 'unshielded' && !options.json) {
          logger.info('Using shielded transfer for unshielded address (--force-shielded)');
        }
      } else if (options.forceUnshielded) {
        useShieldedTransfer = false;
        if (addrInfo.type === 'shielded' && !options.json) {
          logger.info('Using unshielded transfer for shielded address (--force-unshielded)');
        }
      } else {
        // Auto-detect based on address type
        useShieldedTransfer = addrInfo.type === 'shielded';
        
        if (!options.json) {
          if (addrInfo.type === 'shielded') {
            logger.info('Detected shielded address, using shielded transfer (private)');
          } else if (addrInfo.type === 'unshielded') {
            logger.info('Detected unshielded address, using unshielded transfer (public)');
          } else {
            throw new Error(
              `Unknown address type: ${addrInfo.type}. ` +
              `Expected mn_shield-addr_... (shielded) or mn_addr_... (unshielded).`
            );
          }
        }
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
        console.log(`  Amount:  ${formatBalance(amount)} NIGHT`);
        console.log(`  Type:    ${useShieldedTransfer ? 'Shielded (private)' : 'Unshielded (public)'}`);
        console.log(`  Method:  ${options.useLegacyToolkit ? 'Legacy Toolkit' : 'SDK 3.x'}`);
        console.log('');
      }
      
      let txHash: string;
      
      if (options.useLegacyToolkit && !useShieldedTransfer) {
        // Legacy path: use toolkit for unshielded transfers only
        txHash = await sendUnshieldedViaToolkit(sourceWallet, to, amount, config, options);
      } else {
        // Primary path: use SDK for both shielded and unshielded
        txHash = await sendViaSdk(sourceWallet, to, amount, useShieldedTransfer, config, { ...options, timeout: timeoutMs });
      }
      
      if (options.json) {
        console.log(JSON.stringify({
          success: true,
          from: sourceWallet.name,
          fromAddress: sourceWallet.addresses.unshielded,
          to,
          amount: amount.toString(),
          formatted: formatBalance(amount),
          txHash,
          transferType: useShieldedTransfer ? 'shielded' : 'unshielded',
          method: options.useLegacyToolkit && !useShieldedTransfer ? 'toolkit' : 'sdk',
        }, null, 2));
      } else {
        logger.success('Transaction submitted!');
        console.log('');
        console.log(`  Transaction: ${txHash}`);
        console.log(`  Amount:      ${formatBalance(amount)} NIGHT`);
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
 * Send transfer using SDK 3.x (supports both shielded and unshielded)
 */
async function sendViaSdk(
  sourceWallet: any,
  to: string,
  amount: bigint,
  useShieldedTransfer: boolean,
  config: any,
  options: { json?: boolean; debug?: boolean; timeout?: number }
): Promise<string> {
  const timeoutMs = options.timeout || 60000;
  
  // Connect to wallet
  if (!options.json) {
    logger.info('Connecting to wallet...');
  }
  
  const wallet = await createWalletProvider(sourceWallet.seed, config);
  
  try {
    // Wait for sync with progress indicator
    if (!options.json) {
      logger.info('Syncing wallet...');
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
    
    // Check balance based on transfer type
    const availableBalance = useShieldedTransfer ? balances.shielded : balances.unshielded;
    const balanceType = useShieldedTransfer ? 'shielded' : 'unshielded';
    
    if (availableBalance < amount) {
      throw new Error(
        `Insufficient ${balanceType} balance. ` +
        `Available: ${formatBalance(availableBalance)}, Requested: ${formatBalance(amount)}`
      );
    }
    
    if (options.debug) {
      console.log('');
      console.log(`  [DEBUG] ${balanceType} balance: ${formatBalance(availableBalance)}`);
      console.log(`  [DEBUG] Transfer amount: ${formatBalance(amount)}`);
      console.log('');
    }
    
    let txHash: string;
    
    if (useShieldedTransfer) {
      // Shielded transfer via SDK
      txHash = await sendShieldedViaSdk(wallet, to, amount, options);
    } else {
      // Unshielded transfer via SDK (using the new sendUnshielded method)
      if (!options.json) {
        logger.info('Submitting unshielded transfer...');
      }
      
      txHash = await wallet.sendUnshielded(to, amount);
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
 * Send shielded transfer using SDK 3.x
 */
async function sendShieldedViaSdk(
  wallet: any,
  to: string,
  amount: bigint,
  options: { json?: boolean; debug?: boolean }
): Promise<string> {
  // Import shieldedToken to get the shielded NIGHT token type
  // For shielded transfers, use shieldedToken().raw
  // @ts-ignore - ledger-v6 available at runtime in container
  const { shieldedToken } = await import('@midnight-ntwrk/ledger-v6');
  const tokenType = shieldedToken().raw;
  
  if (!options.json) {
    logger.info('Preparing shielded transfer transaction...');
  }
  
  // Step 1: Prepare the transfer transaction
  const transferRecipe = await wallet.transferTransaction([{
    type: 'shielded',
    outputs: [{
      amount,
      type: tokenType,
      receiverAddress: to,
    }],
  }]);
  
  if (!options.json) {
    logger.info('Signing transaction...');
  }
  
  // Step 2: Sign the transaction
  const signedTx = await wallet.signTransaction(transferRecipe.transaction);
  
  if (!options.json) {
    logger.info('Finalizing transaction...');
  }
  
  // Step 3: Finalize (prove) the transaction
  const finalizedTx = await wallet.finalizeTransaction({ ...transferRecipe, transaction: signedTx });
  
  if (!options.json) {
    logger.info('Submitting transaction...');
  }
  
  // Step 4: Submit the transaction
  let txHash: string;
  try {
    txHash = await wallet.submitTransaction(finalizedTx);
  } catch (submitError: any) {
    // Extract detailed error information
    const errorMessage = submitError?.message || 'Unknown error';
    const errorCause = submitError?.cause;
    const errorCode = errorCause?.code || submitError?.code;
    
    // Build detailed error message
    let detailedMessage = `Transaction submission failed: ${errorMessage}`;
    
    if (errorCause) {
      detailedMessage += `\n  Cause: ${errorCause.message || errorCause}`;
    }
    if (errorCode) {
      detailedMessage += `\n  Error code: ${errorCode}`;
    }
    
    // Log full error in debug mode
    if (options.debug) {
      console.error('\n  [DEBUG] Full error object:');
      console.error('  ', JSON.stringify(submitError, Object.getOwnPropertyNames(submitError), 2));
    }
    
    throw new Error(detailedMessage);
  }
  
  return txHash;
}

/**
 * Send unshielded transfer using legacy toolkit binary (deprecated)
 */
async function sendUnshieldedViaToolkit(
  sourceWallet: any,
  to: string,
  amount: bigint,
  config: any,
  options: { json?: boolean; debug?: boolean }
): Promise<string> {
  // Check if toolkit is available
  const toolkitAvailable = await isToolkitAvailable();
  if (!toolkitAvailable) {
    throw new Error(
      'Legacy toolkit binary not found. ' +
      'Set MIDNIGHT_TOOLKIT_PATH or ensure the binary is installed at /usr/local/bin/midnight-node-toolkit. ' +
      'Alternatively, remove --use-legacy-toolkit to use the SDK.'
    );
  }
  
  if (!options.json) {
    logger.info('Preparing unshielded transfer via legacy toolkit...');
  }
  
  const toolkit = createToolkit({
    nodeWsUrl: config.urls.nodeWsUrl || 'ws://localhost:9944',
    network: sourceWallet.network,
  });
  
  // Check unshielded balance first
  if (!options.json) {
    logger.info('Checking wallet balance...');
  }
  
  try {
    const balanceInfo = await toolkit.getWalletBalance(sourceWallet.seed);
    
    if (balanceInfo.unshieldedBalance < amount) {
      throw new Error(
        `Insufficient unshielded balance. ` +
        `Available: ${formatBalance(balanceInfo.unshieldedBalance)}, Requested: ${formatBalance(amount)}`
      );
    }
    
    if (options.debug) {
      console.log(`  [DEBUG] Unshielded balance: ${formatBalance(balanceInfo.unshieldedBalance)}`);
    }
  } catch (balanceError) {
    if (options.debug) {
      console.log(`  [DEBUG] Balance check failed: ${(balanceError as Error).message}`);
    }
    // Continue anyway - let the transfer fail with a more specific error
  }
  
  if (!options.json) {
    logger.info('Submitting unshielded transfer...');
  }
  
  const result = await toolkit.sendUnshielded(sourceWallet.seed, to, amount);
  
  if (!result.success) {
    throw new Error(result.error || 'Unshielded transfer failed');
  }
  
  if (options.debug && result.output) {
    console.log('');
    console.log('  [DEBUG] Toolkit output:');
    console.log(`    ${result.output.split('\n').join('\n    ')}`);
  }
  
  return result.txHash || 'submitted';
}
