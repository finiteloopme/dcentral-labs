/**
 * midnightctl wallet
 * 
 * Wallet management commands.
 */

import { Command } from 'commander';
import { createCommand } from './create';
import { importCommand } from './import';
import { listCommand } from './list';
import { addressCommand } from './address';
import { removeCommand } from './remove';
import { setDefaultCommand } from './set-default';
import { balanceCommand } from './balance';
import { fundCommand } from './fund';
import { sendCommand } from './send';

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
