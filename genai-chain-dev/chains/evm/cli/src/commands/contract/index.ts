/**
 * Contract commands (wraps Foundry)
 */

import { Command } from 'commander';
import { spawn } from 'node:child_process';
import type { ChainConfig } from '../../lib/config.js';
import { WalletStore } from '../../lib/wallet-store.js';

export function registerContractCommands(program: Command, config: ChainConfig): void {
  // compile command (top-level alias for convenience)
  program
    .command('compile')
    .description('Compile smart contracts (forge build)')
    .option('--optimize', 'Enable optimizer')
    .option('--sizes', 'Show contract sizes')
    .action(async (options: { optimize?: boolean; sizes?: boolean }) => {
      const args = ['build'];
      if (options.optimize) args.push('--optimize');
      if (options.sizes) args.push('--sizes');
      
      await runForge(args);
    });

  // test command (top-level alias)
  program
    .command('test')
    .description('Run tests (forge test)')
    .option('-v, --verbosity <level>', 'Verbosity level (1-5)', '2')
    .option('-m, --match <pattern>', 'Test filter pattern')
    .option('--gas-report', 'Show gas report')
    .action(async (options: { verbosity: string; match?: string; gasReport?: boolean }) => {
      const args = ['test', `-${'v'.repeat(parseInt(options.verbosity, 10))}`];
      if (options.match) args.push('--match-test', options.match);
      if (options.gasReport) args.push('--gas-report');
      
      await runForge(args);
    });

  // deploy command
  program
    .command('deploy <script>')
    .description('Deploy contracts (forge script)')
    .option('-w, --wallet <name>', 'Wallet to use for deployment')
    .option('--network <name>', 'Network to deploy to')
    .option('--broadcast', 'Actually broadcast transactions')
    .option('--verify', 'Verify contracts after deployment')
    .action(async (script: string, options: {
      wallet?: string;
      network?: string;
      broadcast?: boolean;
      verify?: boolean;
    }) => {
      const store = new WalletStore(config);
      const wallet = store.getOrDefault(options.wallet);
      
      const args = ['script', script];
      args.push('--rpc-url', config.rpcUrl);
      args.push('--private-key', wallet.privateKey);
      
      if (options.broadcast) {
        args.push('--broadcast');
      }
      if (options.verify && config.explorerUrl) {
        args.push('--verify');
      }
      
      console.log(`\nDeploying with wallet: ${wallet.name}`);
      console.log(`Network: ${config.chainName} (${config.rpcUrl})\n`);
      
      await runForge(args);
    });

  // verify command
  program
    .command('verify <address> <contract>')
    .description('Verify contract on explorer (forge verify-contract)')
    .action(async (address: string, contract: string) => {
      if (!config.explorerUrl) {
        console.error('Error: No explorer URL configured for this chain');
        process.exit(1);
      }
      
      const args = [
        'verify-contract',
        address,
        contract,
        '--chain-id', String(config.chainId),
      ];
      
      await runForge(args);
    });
}

/**
 * Run forge command with inherited stdio
 */
async function runForge(args: string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn('forge', args, {
      stdio: 'inherit',
      shell: false,
    });
    
    child.on('error', (error) => {
      reject(new Error(`Failed to run forge: ${error.message}`));
    });
    
    child.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        process.exit(code || 1);
      }
    });
  });
}
