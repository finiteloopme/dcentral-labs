/**
 * midnightctl wallet
 * 
 * Wallet management commands.
 */

import { Command } from 'commander';
import { createCommand } from './create.js';
import { importCommand } from './import.js';
import { listCommand } from './list.js';
import { addressCommand } from './address.js';
import { removeCommand } from './remove.js';
import { setDefaultCommand } from './set-default.js';
import { balanceCommand } from './balance.js';
import { fundCommand } from './fund.js';
import { sendCommand } from './send.js';

export const walletCommand = new Command('wallet')
  .description('Manage wallets')
  .addCommand(createCommand)
  .addCommand(importCommand)
  .addCommand(listCommand)
  .addCommand(addressCommand)
  .addCommand(removeCommand)
  .addCommand(setDefaultCommand)
  .addCommand(balanceCommand)
  .addCommand(fundCommand)
  .addCommand(sendCommand);
