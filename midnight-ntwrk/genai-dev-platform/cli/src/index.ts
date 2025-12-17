#!/usr/bin/env node

// Load environment variables from .env file (if present)
// This must be done before any other imports that might use process.env
import * as dotenv from 'dotenv';
import * as path from 'path';

// Try to load .env from current directory, then from home directory
dotenv.config(); // .env in current directory
dotenv.config({ path: path.join(process.env.HOME || '', '.env') }); // ~/.env

import { Command } from 'commander';
import chalk from 'chalk';
import { initCommand } from './commands/init';
import { compileCommand } from './commands/compile';
import { servicesCommand } from './commands/services';
import { envCommand } from './commands/env';

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

// Custom help footer
program.addHelpText('after', `
${chalk.cyan('Examples:')}
  $ midnightctl init my-project       Create a new Midnight project
  $ midnightctl compile                Compile Compact contracts
  $ midnightctl services start         Start local development services
  $ midnightctl services status        Check service status
  $ midnightctl env show               Show current environment

${chalk.cyan('Documentation:')}
  https://docs.midnight.network
`);

program.parse();
