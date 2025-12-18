/**
 * midnightctl contract deploy <path>
 * 
 * Deploy a compiled Compact contract to the network.
 */

import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import { logger } from '../../utils/logger';
import { 
  WalletManager,
  getNetworkDisplayName,
  getProviderConfig,
  createContractProviders,
  validateServiceConfig,
  waitForWalletSync,
  truncateAddress,
} from '../../lib/midnight/index';
import { generateWitnesses, getWitnessSummary } from '../../lib/midnight/witness-gen';

/**
 * Contract metadata stored in .private/contracts/
 */
interface ContractMetadata {
  contractAddress: string;
  deployedAt: string;
  contractPath: string;
  network: string;
  deployTxHash: string;
  circuits: string[];
}

/**
 * Format balance for display
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

export const deployCommand = new Command('deploy')
  .description('Deploy a compiled contract')
  .argument('<path>', 'Path to compiled contract directory')
  .option('-w, --wallet <name>', 'Wallet to use for deployment')
  .option('--initial-state <json>', 'Initial private state as JSON', '{}')
  .option('--initial-state-file <path>', 'Path to initial private state file')
  .option('--witnesses <path>', 'Path to custom witnesses file')
  .option('--dry-run', 'Build transaction without submitting')
  .option('--json', 'Output as JSON')
  .action(async (contractPath: string, options: {
    wallet?: string;
    initialState?: string;
    initialStateFile?: string;
    witnesses?: string;
    dryRun?: boolean;
    json?: boolean;
  }) => {
    try {
      const manager = new WalletManager();
      const config = getProviderConfig();
      const projectRoot = manager.getProjectRoot();
      
      // Resolve absolute contract path
      const absContractPath = path.isAbsolute(contractPath) 
        ? contractPath 
        : path.resolve(process.cwd(), contractPath);
      
      // Validate contract path exists
      if (!fs.existsSync(absContractPath)) {
        throw new Error(`Contract not found at ${absContractPath}`);
      }
      
      // Check for compiled contract artifacts
      const contractModulePath = path.join(absContractPath, 'contract', 'index.cjs');
      const contractInfoPath = path.join(absContractPath, 'compiler', 'contract-info.json');
      
      if (!fs.existsSync(contractModulePath)) {
        throw new Error(
          `Contract module not found at ${contractModulePath}. ` +
          'Run `midnightctl compile` first.'
        );
      }
      
      if (!fs.existsSync(contractInfoPath)) {
        throw new Error(
          `Contract info not found at ${contractInfoPath}. ` +
          'Run `midnightctl compile` first.'
        );
      }
      
      // Get contract name
      const contractName = path.basename(absContractPath);
      
      // Validate services
      const validation = validateServiceConfig(config);
      if (!validation.valid) {
        throw new Error(
          `Services not configured: ${validation.missing.join(', ')}. ` +
          'Check your .env file or run `midnightctl services status`.'
        );
      }
      
      // Resolve wallet
      const wallet = await manager.resolve(options.wallet, true);
      
      if (!options.json) {
        logger.title(`Deploying Contract: ${contractName}`);
        console.log('');
        console.log(`  Network:       ${getNetworkDisplayName(config.network)}`);
        console.log(`  Wallet:        ${wallet.name}`);
        console.log(`  Contract Path: ${absContractPath}`);
        console.log('');
      }
      
      // Load contract info
      if (!options.json) {
        logger.info('Loading contract...');
      }
      
      const contractInfo = JSON.parse(fs.readFileSync(contractInfoPath, 'utf-8'));
      const circuits = Object.keys(contractInfo.circuits || {});
      
      if (!options.json) {
        console.log(`    ✓ Contract info loaded`);
        console.log(`    ✓ ZK keys loaded (${circuits.length} circuits: ${circuits.join(', ')})`);
      }
      
      // Generate or load witnesses
      if (!options.json) {
        console.log('');
        logger.info('Generating witnesses...');
      }
      
      // Create private state directory for this contract (pending address)
      const pendingDir = path.join(projectRoot, '.private', 'contracts', '_pending');
      
      let witnessPath: string;
      if (options.witnesses) {
        witnessPath = path.isAbsolute(options.witnesses)
          ? options.witnesses
          : path.resolve(process.cwd(), options.witnesses);
        
        if (!fs.existsSync(witnessPath)) {
          throw new Error(`Witnesses file not found: ${witnessPath}`);
        }
        
        if (!options.json) {
          console.log(`    ✓ Using custom witnesses from ${witnessPath}`);
        }
      } else {
        // Auto-generate witnesses
        const result = generateWitnesses(absContractPath, pendingDir);
        witnessPath = result.witnessPath;
        
        const summary = getWitnessSummary(result.witnesses);
        
        if (!options.json) {
          for (const w of result.witnesses) {
            if (w.modifiesPrivateState) {
              console.log(`    ⚠ ${w.name}: auto-generated no-op (review recommended)`);
            } else {
              console.log(`    ✓ ${w.name}: passthrough`);
            }
          }
          console.log('');
          console.log(`    Witnesses saved to: ${witnessPath}`);
        }
      }
      
      // Parse initial private state
      let initialPrivateState: Record<string, unknown> = {};
      if (options.initialStateFile) {
        const statePath = path.isAbsolute(options.initialStateFile)
          ? options.initialStateFile
          : path.resolve(process.cwd(), options.initialStateFile);
        initialPrivateState = JSON.parse(fs.readFileSync(statePath, 'utf-8'));
      } else if (options.initialState) {
        initialPrivateState = JSON.parse(options.initialState);
      }
      
      if (!options.json) {
        console.log('');
        console.log(`  Initial Private State:`);
        console.log(`    ${JSON.stringify(initialPrivateState)}`);
        console.log('');
      }
      
      // Create providers
      if (!options.json) {
        logger.info('Connecting to services...');
      }
      
      const providers = await createContractProviders(wallet.seed, config, {
        privateStateDir: path.join(projectRoot, '.private', 'contracts', '_pending', 'state'),
        zkConfigPath: absContractPath,
      });
      
      // Start wallet and wait for sync
      providers.wallet.start();
      
      try {
        if (!options.json) {
          console.log('  Syncing wallet...');
        }
        
        const { balance, synced } = await waitForWalletSync(providers.wallet, {
          minBalance: 1_000_000n, // Minimum 1 tDUST for fees
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
        
        if (!options.json) {
          console.log(`  Balance: ${formatBalance(balance)} tDUST`);
          console.log('');
        }
        
        if (balance < 1_000_000n) {
          throw new Error(
            `Insufficient balance for deployment. ` +
            `Need at least 1 tDUST, have ${formatBalance(balance)}`
          );
        }
        
        if (options.dryRun) {
          if (!options.json) {
            logger.info('Dry run - skipping deployment');
            console.log('');
          } else {
            console.log(JSON.stringify({
              dryRun: true,
              contractPath: absContractPath,
              wallet: wallet.name,
              initialPrivateState,
            }, null, 2));
          }
          return;
        }
        
        // Deploy contract
        if (!options.json) {
          logger.info('Deploying contract...');
        }
        
        // Load contract module
        const contractModule = await import(contractModulePath);
        const Contract = contractModule.Contract || contractModule.default;
        
        // Load witnesses
        const witnessModule = await import(witnessPath);
        const witnesses = witnessModule.witnesses || witnessModule.default || {};
        
        // Create contract instance with witnesses
        const contractInstance = new Contract(witnesses);
        
        // Deploy using SDK
        const { deployContract } = await import('@midnight-ntwrk/midnight-js-contracts');
        
        const deployedContract = await deployContract(providers, {
          privateStateId: `${contractName}-${Date.now()}`,
          contract: contractInstance,
          initialPrivateState: () => initialPrivateState,
        });
        
        const contractAddress = deployedContract.deployTxData.public.contractAddress;
        const txHash = deployedContract.deployTxData.public.txHash;
        const blockHeight = deployedContract.deployTxData.public.blockHeight;
        
        if (!options.json) {
          console.log('');
          logger.success('Contract Deployed!');
          console.log('');
          console.log(`  Address:     ${contractAddress}`);
          console.log(`  Transaction: ${txHash}`);
          console.log(`  Block:       #${blockHeight}`);
          console.log('');
        }
        
        // Save contract metadata
        const contractDir = path.join(projectRoot, '.private', 'contracts', contractAddress);
        if (!fs.existsSync(contractDir)) {
          fs.mkdirSync(contractDir, { recursive: true });
        }
        
        const metadata: ContractMetadata = {
          contractAddress,
          deployedAt: new Date().toISOString(),
          contractPath: absContractPath,
          network: config.network,
          deployTxHash: txHash,
          circuits,
        };
        
        fs.writeFileSync(
          path.join(contractDir, 'metadata.json'),
          JSON.stringify(metadata, null, 2)
        );
        
        // Copy witnesses to contract directory
        fs.copyFileSync(witnessPath, path.join(contractDir, 'witnesses.ts'));
        
        // Save private state
        fs.writeFileSync(
          path.join(contractDir, 'private-state.json'),
          JSON.stringify(initialPrivateState, null, 2)
        );
        
        if (!options.json) {
          console.log(`  Private state saved to: ${contractDir}`);
          console.log('');
          console.log('  Next steps:');
          console.log(`    midnightctl contract call ${truncateAddress(contractAddress)} <circuit> [args...]`);
          console.log(`    midnightctl contract state ${truncateAddress(contractAddress)}`);
          console.log('');
        } else {
          console.log(JSON.stringify({
            success: true,
            contractAddress,
            txHash,
            blockHeight,
            network: config.network,
            circuits,
            privateStateDir: contractDir,
          }, null, 2));
        }
        
        // Clean up pending directory
        if (fs.existsSync(pendingDir)) {
          fs.rmSync(pendingDir, { recursive: true, force: true });
        }
        
      } finally {
        try {
          await providers.wallet.close();
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
