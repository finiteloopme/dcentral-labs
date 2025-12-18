#!/usr/bin/env node

// Load environment variables from .env file (if present)
// This must be done before any other imports that might use process.env
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Try to load .env from current directory, then from home directory
dotenv.config(); // .env in current directory
dotenv.config({ path: path.join(process.env.HOME || '', '.env') }); // ~/.env

import { Command } from 'commander';
import chalk from 'chalk';
import { initCommand } from './commands/init.js';
import { compileCommand } from './commands/compile.js';
import { servicesCommand } from './commands/services.js';
import { envCommand } from './commands/env.js';
import { walletCommand } from './commands/wallet/index.js';
import { contractCommand } from './commands/contract/index.js';

const program = new Command();

program
  .name('midnightctl')
  .description('Midnight Development CLI')
  .version('0.1.0');

// Project commands (top-level for convenience)
program.addCommand(initCommand);
program.addCommand(compileCommand);

// Namespaced commands
program.addCommand(servicesCommand);
program.addCommand(envCommand);
program.addCommand(walletCommand);
program.addCommand(contractCommand);

// Custom help footer
program.addHelpText('after', `
${chalk.cyan('Examples:')}
  $ midnightctl init my-project         Create a new Midnight project
  $ midnightctl compile                  Compile Compact contracts
  $ midnightctl services start           Start local development services
  $ midnightctl services status          Check service status
  $ midnightctl env show                 Show current environment
  $ midnightctl wallet create dev        Create a new wallet
  $ midnightctl wallet balance           Check wallet balance
  $ midnightctl contract deploy ./build  Deploy a compiled contract

${chalk.cyan('Documentation:')}
  https://docs.midnight.network
`);

program.parse();
