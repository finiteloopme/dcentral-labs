/**
 * Node (Anvil) command group
 */

import { Command } from 'commander';
import type { ChainConfig } from '../../lib/config.js';
import { startAnvil, stopAnvil, getAnvilStatus, getAnvilLogs, type AnvilOptions } from '../../lib/anvil.js';

export function registerNodeCommands(program: Command, config: ChainConfig): void {
  const node = program
    .command('node')
    .description('Manage local Anvil node');

  // node start
  node
    .command('start')
    .description('Start local Anvil node')
    .option('-p, --port <port>', 'Port to listen on', '8545')
    .option('-a, --accounts <count>', 'Number of accounts to create', '10')
    .option('-b, --balance <amount>', 'Balance per account in ETH', '10000')
    .option('--block-time <seconds>', 'Block time in seconds (0 = instant mining)')
    .option('--fork <url>', 'Fork from RPC URL')
    .option('--fork-block <number>', 'Fork at specific block number')
    .action(async (options: {
      port: string;
      accounts: string;
      balance: string;
      blockTime?: string;
      fork?: string;
      forkBlock?: string;
    }) => {
      console.log('\nStarting Anvil...');
      
      const anvilOptions: AnvilOptions = {
        port: parseInt(options.port, 10),
        accounts: parseInt(options.accounts, 10),
        balance: options.balance,
        blockTime: options.blockTime ? parseInt(options.blockTime, 10) : undefined,
        forkUrl: options.fork,
        forkBlockNumber: options.forkBlock ? parseInt(options.forkBlock, 10) : undefined,
      };
      
      try {
        const status = await startAnvil(config, anvilOptions);
        
        console.log('\n\x1b[32mAnvil started successfully!\x1b[0m\n');
        console.log('  RPC URL:    ' + status.rpcUrl);
        console.log('  Chain ID:   31337');
        console.log('  Accounts:   ' + options.accounts);
        console.log('  Balance:    ' + options.balance + ' ETH each');
        console.log('  PID:        ' + status.pid);
        console.log('');
        console.log('Use "node stop" to stop the node.');
        console.log('Use "node logs" to view logs.\n');
      } catch (error) {
        console.error(`\n\x1b[31mError:\x1b[0m ${error instanceof Error ? error.message : error}\n`);
        process.exit(1);
      }
    });

  // node stop
  node
    .command('stop')
    .description('Stop local Anvil node')
    .action(async () => {
      try {
        await stopAnvil(config);
        console.log('\nAnvil stopped.\n');
      } catch (error) {
        console.error(`\n\x1b[31mError:\x1b[0m ${error instanceof Error ? error.message : error}\n`);
        process.exit(1);
      }
    });

  // node status
  node
    .command('status')
    .description('Check Anvil node status')
    .action(async () => {
      const status = await getAnvilStatus(config);
      
      console.log('\nAnvil Status');
      console.log('============');
      if (status.running) {
        console.log('  Status:   \x1b[32mrunning\x1b[0m');
        console.log('  PID:      ' + status.pid);
        console.log('  Port:     ' + status.port);
        console.log('  RPC URL:  ' + status.rpcUrl);
      } else {
        console.log('  Status:   \x1b[33mnot running\x1b[0m');
        console.log('\n  Use "node start" to start Anvil.');
      }
      console.log('');
    });

  // node logs
  node
    .command('logs')
    .description('View Anvil logs')
    .option('-n, --lines <count>', 'Number of lines to show', '50')
    .action(async (options: { lines: string }) => {
      const lines = parseInt(options.lines, 10);
      const logs = getAnvilLogs(config, lines);
      
      if (!logs) {
        console.log('\nNo logs available.\n');
        return;
      }
      
      console.log('\nAnvil Logs');
      console.log('==========\n');
      console.log(logs);
    });
}
