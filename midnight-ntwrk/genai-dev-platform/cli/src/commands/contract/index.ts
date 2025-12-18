/**
 * midnightctl contract
 * 
 * Contract deployment and interaction commands.
 */

import { Command } from 'commander';
import { deployCommand } from './deploy';

export const contractCommand = new Command('contract')
  .description('Deploy and interact with contracts')
  .addCommand(deployCommand);

// TODO: Add these commands in future iterations
// .addCommand(joinCommand)
// .addCommand(callCommand)
// .addCommand(stateCommand)
