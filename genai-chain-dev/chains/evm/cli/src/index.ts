#!/usr/bin/env node
/**
 * EVM Chain CLI
 * 
 * This CLI wraps Foundry tools and provides wallet management for EVM chains.
 */

import { Command } from 'commander';
import { loadChainConfig } from './lib/config.js';
import { registerWalletCommands } from './commands/wallet/index.js';
import { registerNodeCommands } from './commands/node/index.js';
import { registerContractCommands } from './commands/contract/index.js';
import { registerInitCommand } from './commands/init.js';
import { registerNetworkCommands } from './commands/network.js';

async function main(): Promise<void> {
  const config = loadChainConfig();
  
  const program = new Command()
    .name(config.cliName)
    .version('1.0.0')
    .description(`${config.chainName} blockchain development CLI`)
    .option('-v, --verbose', 'Enable verbose output')
    .option('--json', 'Output as JSON');

  // Register command groups
  registerInitCommand(program, config);
  registerWalletCommands(program, config);
  registerContractCommands(program, config);
  registerNodeCommands(program, config);
  registerNetworkCommands(program, config);

  await program.parseAsync(process.argv);
}

main().catch((error) => {
  console.error(`\x1b[31m[ERROR]\x1b[0m ${error.message}`);
  process.exit(1);
});
