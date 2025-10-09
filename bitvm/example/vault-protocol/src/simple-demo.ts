#!/usr/bin/env node

/**
 * Simple demo for BitVM3 - No compilation errors version
 */

import { BitVM3Protocol } from './core/BitVM3Protocol';
import { TrustlessVault } from './vault/TrustlessVault';
import { TransactionManager } from './core/TransactionManager';
import { Participant } from './core/types';

const chalk = require('chalk');

async function runDemo() {
  console.log(chalk.cyan.bold('\n🔷 BitVM3 Trustless Vault - Simple Demo\n'));

  // Initialize components
  const protocol = new BitVM3Protocol();
  const vault = new TrustlessVault();
  const transactionManager = new TransactionManager();

  // Generate key pairs
  const aliceKeys = transactionManager.generateKeyPair();
  const bobKeys = transactionManager.generateKeyPair();

  // Create participants
  const alice: Participant = {
    name: 'Alice',
    publicKey: aliceKeys.publicKey,
    privateKey: aliceKeys.privateKey,
    balance: { BTC: 2.0, USDT: 0 }
  };

  const bob: Participant = {
    name: 'Bob',
    publicKey: bobKeys.publicKey,
    privateKey: bobKeys.privateKey,
    balance: { BTC: 0, USDT: 20000 }
  };

  // Initialize protocol
  console.log('Initializing BitVM3 Protocol...');
  await protocol.initialize(alice, bob);
  console.log('✅ Protocol initialized\n');

  // Display initial state
  console.log('Initial Balances:');
  console.log(`  Alice: ${alice.balance.BTC} BTC, ${alice.balance.USDT} USDT`);
  console.log(`  Bob: ${bob.balance.BTC} BTC, ${bob.balance.USDT} USDT\n`);

  // 1. Alice deposits BTC
  console.log('1. Alice deposits 1 BTC to vault...');
  await protocol.deposit('alice', 1, 'BTC');
  await vault.depositBTC('alice', 1);
  console.log('✅ Deposit successful\n');

  // 2. Bob deposits USDT
  console.log('2. Bob deposits 10,000 USDT to vault...');
  await protocol.deposit('bob', 10000, 'USDT');
  await vault.depositUSDT('bob', 10000);
  console.log('✅ Deposit successful\n');

  // 3. Show vault state
  const vaultStats = vault.getStatistics();
  console.log('Vault State:');
  console.log(`  Total BTC: ${vaultStats.totalBTC}`);
  console.log(`  Total USDT: ${vaultStats.totalUSDT}`);
  console.log(`  Block Height: ${vaultStats.blockHeight}\n`);

  // 4. Create lending position
  console.log('3. Creating lending position...');
  await vault.createLendingPosition('bob', 'alice', 5000, 0.15);
  console.log('✅ Lending position created\n');

  // 5. Alice withdraws
  console.log('4. Alice withdraws 0.5 BTC...');
  const success = await protocol.withdraw('alice', 0.5, 'BTC');
  if (success) {
    await vault.withdrawBTC('alice', 0.5);
    console.log('✅ Withdrawal successful\n');
  }

  // 6. Final state
  const finalStats = vault.getStatistics();
  console.log('Final Vault State:');
  console.log(`  Total BTC: ${finalStats.totalBTC}`);
  console.log(`  Total USDT: ${finalStats.totalUSDT}`);
  console.log(`  Active Positions: ${finalStats.activePositions}`);
  console.log(`  Block Height: ${finalStats.blockHeight}`);

  console.log(chalk.green('\n✅ Demo completed successfully!\n'));
}

// Run the demo
runDemo().catch(error => {
  console.error(chalk.red('Demo failed:'), error);
  process.exit(1);
});