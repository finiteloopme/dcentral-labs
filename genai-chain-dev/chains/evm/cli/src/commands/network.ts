/**
 * Network commands
 */

import { Command } from 'commander';
import type { ChainConfig } from '../lib/config.js';

export function registerNetworkCommands(program: Command, config: ChainConfig): void {
  const network = program
    .command('network')
    .description('Manage network configuration');

  // network list
  network
    .command('list')
    .description('List available networks')
    .action(async () => {
      console.log('\nAvailable Networks');
      console.log('==================\n');
      
      // Local network (always available via Anvil)
      console.log('  \x1b[33mlocalnet\x1b[0m');
      console.log('    RPC URL:  http://127.0.0.1:8545');
      console.log('    Chain ID: 31337');
      console.log('    Type:     Local (Anvil)');
      console.log('');
      
      // Configured network from chain config
      console.log(`  \x1b[32m${config.chainName.toLowerCase()}\x1b[0m (default)`);
      console.log(`    RPC URL:  ${config.rpcUrl}`);
      console.log(`    Chain ID: ${config.chainId}`);
      if (config.explorerUrl) {
        console.log(`    Explorer: ${config.explorerUrl}`);
      }
      if (config.faucetUrl) {
        console.log(`    Faucet:   ${config.faucetUrl}`);
      }
      console.log('');
    });

  // network current
  network
    .command('current')
    .description('Show current network configuration')
    .action(async () => {
      console.log('\nCurrent Network');
      console.log('===============\n');
      console.log(`  Chain:     ${config.chainName}`);
      console.log(`  Chain ID:  ${config.chainId}`);
      console.log(`  RPC URL:   ${config.rpcUrl}`);
      console.log(`  Currency:  ${config.nativeCurrency}`);
      if (config.explorerUrl) {
        console.log(`  Explorer:  ${config.explorerUrl}`);
      }
      if (config.faucetUrl) {
        console.log(`  Faucet:    ${config.faucetUrl}`);
      }
      console.log('');
    });
}
