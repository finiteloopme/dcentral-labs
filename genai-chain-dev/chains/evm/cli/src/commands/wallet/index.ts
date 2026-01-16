/**
 * Wallet command group
 */

import { Command } from 'commander';
import type { ChainConfig } from '../../lib/config.js';
import { WalletStore } from '../../lib/wallet-store.js';
import { createProvider, getBalance, sendTransaction, createWallet, getExplorerTxUrl, formatEther } from '../../lib/provider.js';

export function registerWalletCommands(program: Command, config: ChainConfig): void {
  const wallet = program
    .command('wallet')
    .description('Manage wallets');

  // wallet create
  wallet
    .command('create <name>')
    .description('Create a new wallet with generated mnemonic')
    .action(async (name: string) => {
      const store = new WalletStore(config);
      const result = store.create(name);
      
      console.log(`\nWallet '${name}' created successfully.\n`);
      console.log('Mnemonic (24 words):');
      console.log('====================');
      if (result.mnemonic) {
        const words = result.mnemonic.split(' ');
        for (let i = 0; i < words.length; i += 4) {
          const row = words.slice(i, i + 4)
            .map((w, j) => `${(i + j + 1).toString().padStart(2)}. ${w.padEnd(12)}`)
            .join('');
          console.log(`  ${row}`);
        }
      }
      console.log('\n\x1b[33mWARNING: This mnemonic is stored in plaintext for development.');
      console.log('Do not use this wallet for real funds.\x1b[0m\n');
      console.log(`Address: ${result.address}`);
    });

  // wallet import
  wallet
    .command('import <name>')
    .description('Import wallet from mnemonic or private key')
    .option('-m, --mnemonic <phrase>', 'BIP39 mnemonic phrase')
    .option('-k, --private-key <key>', 'Private key (hex)')
    .action(async (name: string, options: { mnemonic?: string; privateKey?: string }) => {
      if (!options.mnemonic && !options.privateKey) {
        console.error('Error: Either --mnemonic or --private-key is required');
        process.exit(1);
      }
      
      const store = new WalletStore(config);
      const secret = options.mnemonic || options.privateKey!;
      const result = store.import(name, secret);
      
      console.log(`\nWallet '${name}' imported successfully.`);
      console.log(`Address: ${result.address}`);
    });

  // wallet list
  wallet
    .command('list')
    .description('List all wallets')
    .action(async () => {
      const store = new WalletStore(config);
      const wallets = store.list();
      const defaultName = store.getDefaultName();
      
      if (wallets.length === 0) {
        console.log('\nNo wallets found. Create one with: wallet create <name>\n');
        return;
      }
      
      console.log('\nWallets');
      console.log('=======');
      console.log('  NAME            DEFAULT   ADDRESS');
      for (const w of wallets) {
        const isDefault = w.name === defaultName ? 'yes' : 'no';
        const shortAddr = `${w.address.slice(0, 10)}...${w.address.slice(-8)}`;
        console.log(`  ${w.name.padEnd(15)} ${isDefault.padEnd(9)} ${shortAddr}`);
      }
      console.log('');
    });

  // wallet balance
  wallet
    .command('balance [name]')
    .description('Check wallet balance')
    .action(async (name?: string) => {
      const store = new WalletStore(config);
      const w = store.getOrDefault(name);
      
      const client = createProvider(config);
      const { balance, formatted } = await getBalance(client, w.address, config);
      
      console.log(`\nWallet Balance: ${w.name}`);
      console.log('='.repeat(25 + w.name.length));
      console.log(`  Address: ${w.address}`);
      console.log(`  Balance: ${formatted}`);
      console.log('');
    });

  // wallet address
  wallet
    .command('address [name]')
    .description('Show wallet address')
    .action(async (name?: string) => {
      const store = new WalletStore(config);
      const w = store.getOrDefault(name);
      console.log(w.address);
    });

  // wallet send
  wallet
    .command('send <to> <amount>')
    .description(`Send ${config.nativeCurrency} tokens`)
    .option('-w, --wallet <name>', 'Wallet to send from (uses default if not specified)')
    .action(async (to: string, amount: string, options: { wallet?: string }) => {
      const store = new WalletStore(config);
      const w = store.getOrDefault(options.wallet);
      
      console.log(`\nSending ${config.nativeCurrency}`);
      console.log('='.repeat(20));
      console.log(`  From:   ${w.address}`);
      console.log(`  To:     ${to}`);
      console.log(`  Amount: ${amount} ${config.nativeCurrency}`);
      console.log('');
      
      const publicClient = createProvider(config);
      const { walletClient } = createWallet(w.privateKey, config);
      const result = await sendTransaction(walletClient, publicClient, to, amount, config);
      
      console.log(`  Transaction: ${result.hash}`);
      if (result.blockNumber) {
        console.log(`  Block:       ${result.blockNumber}`);
      }
      const explorerUrl = getExplorerTxUrl(config, result.hash);
      if (explorerUrl) {
        console.log(`  Explorer:    ${explorerUrl}`);
      }
      console.log('\n\x1b[32mTransaction confirmed!\x1b[0m\n');
    });

  // wallet remove
  wallet
    .command('remove <name>')
    .description('Remove a wallet')
    .action(async (name: string) => {
      const store = new WalletStore(config);
      store.remove(name);
      console.log(`Wallet '${name}' removed.`);
    });

  // wallet set-default
  wallet
    .command('set-default <name>')
    .description('Set default wallet')
    .action(async (name: string) => {
      const store = new WalletStore(config);
      store.setDefault(name);
      console.log(`Default wallet set to '${name}'.`);
    });

  // wallet export
  wallet
    .command('export <name>')
    .description('Export wallet private key')
    .option('--private-key', 'Output only the private key')
    .action(async (name: string, options: { privateKey?: boolean }) => {
      const store = new WalletStore(config);
      const w = store.get(name);
      if (!w) {
        console.error(`Wallet '${name}' not found`);
        process.exit(1);
      }
      
      if (options.privateKey) {
        console.log(w.privateKey);
      } else {
        console.log(`\nWallet: ${name}`);
        console.log(`Address: ${w.address}`);
        console.log(`Private Key: ${w.privateKey}`);
        if (w.mnemonic) {
          console.log(`Mnemonic: ${w.mnemonic}`);
        }
      }
    });
}
