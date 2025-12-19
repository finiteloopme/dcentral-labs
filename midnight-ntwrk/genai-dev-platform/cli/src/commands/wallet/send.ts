/**
 * midnightctl wallet send <from> <to-address> <amount>
 * 
 * Send NIGHT tokens to another address.
 * 
 * Automatically detects address type:
 * - Shielded addresses (mn_shield-addr_...): Uses JavaScript SDK (Zswap transfer)
 * - Unshielded addresses (mn_addr_...): Uses toolkit binary (native transfer)
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
  .option('--debug', 'Show debug information including service URLs')
  .action(async (from: string, to: string, amountStr: string, options: { json?: boolean; forceShielded?: boolean; forceUnshielded?: boolean; debug?: boolean }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      
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
            logger.info('Detected shielded address, using SDK transfer (private)');
          } else if (addrInfo.type === 'unshielded') {
            logger.info('Detected unshielded address, using toolkit transfer (public)');
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
        console.log('');
      }
      
      let txHash: string;
      
      if (useShieldedTransfer) {
        // Use SDK for shielded transfer
        txHash = await sendShielded(sourceWallet, to, amount, config, options);
      } else {
        // Use toolkit for unshielded transfer
        txHash = await sendUnshielded(sourceWallet, to, amount, config, options);
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
 * Send shielded (private) transfer using the JavaScript SDK
 */
async function sendShielded(
  sourceWallet: any,
  to: string,
  amount: bigint,
  config: any,
  options: { json?: boolean; debug?: boolean }
): Promise<string> {
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
        `Insufficient shielded balance. ` +
        `Available: ${formatBalance(balance)}, Requested: ${formatBalance(amount)}`
      );
    }
    
    // Send transaction using the 3-step wallet API
    if (!options.json) {
      logger.info('Preparing shielded transfer transaction...');
    }
    
    // Import nativeToken to get the NIGHT token type
    const { nativeToken } = await import('@midnight-ntwrk/ledger');
    const tokenType = nativeToken();
    
    // Step 1: Prepare the transfer transaction
    const transferRecipe = await wallet.transferTransaction([{
      amount,
      type: tokenType,
      receiverAddress: to,
    }]);
    
    if (!options.json) {
      logger.info('Proving transaction...');
    }
    
    // Step 2: Prove the transaction
    const provenTx = await wallet.proveTransaction(transferRecipe);
    
    if (!options.json) {
      logger.info('Submitting transaction...');
    }
    
    // Step 3: Submit the transaction
    let txHash: string;
    try {
      txHash = await wallet.submitTransaction(provenTx);
    } catch (submitError: any) {
      // Extract detailed error information
      const errorMessage = submitError?.message || 'Unknown error';
      const errorCause = submitError?.cause;
      const errorCode = errorCause?.code || submitError?.code;
      const errorErrno = errorCause?.errno || submitError?.errno;
      const errorSyscall = errorCause?.syscall || submitError?.syscall;
      const errorAddress = errorCause?.address || submitError?.address;
      const errorPort = errorCause?.port || submitError?.port;
      
      // Build detailed error message
      let detailedMessage = `Transaction submission failed: ${errorMessage}`;
      
      if (errorCause) {
        detailedMessage += `\n  Cause: ${errorCause.message || errorCause}`;
      }
      if (errorCode) {
        detailedMessage += `\n  Error code: ${errorCode}`;
      }
      if (errorErrno) {
        detailedMessage += `\n  Errno: ${errorErrno}`;
      }
      if (errorSyscall) {
        detailedMessage += `\n  Syscall: ${errorSyscall}`;
      }
      if (errorAddress) {
        detailedMessage += `\n  Address: ${errorAddress}:${errorPort || '?'}`;
      }
      
      // Log full error in debug mode
      if (options.debug) {
        console.error('\n  [DEBUG] Full error object:');
        console.error('  ', JSON.stringify(submitError, Object.getOwnPropertyNames(submitError), 2));
        if (errorCause) {
          console.error('  [DEBUG] Error cause:');
          console.error('  ', JSON.stringify(errorCause, Object.getOwnPropertyNames(errorCause), 2));
        }
      }
      
      throw new Error(detailedMessage);
    }
    
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
 * Send unshielded (public) transfer using the toolkit binary
 */
async function sendUnshielded(
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
      'Unshielded transfers require the midnight-node-toolkit binary. ' +
      'Set MIDNIGHT_TOOLKIT_PATH or ensure the binary is installed at /usr/local/bin/midnight-node-toolkit'
    );
  }
  
  if (!options.json) {
    logger.info('Preparing unshielded transfer via toolkit...');
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
