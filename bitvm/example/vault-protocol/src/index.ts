#!/usr/bin/env node

/**
 * BitVM3 CLI - Interactive command-line interface for BitVM3 protocol
 */

import { Command } from 'commander';
import chalk from 'chalk';
import inquirer from 'inquirer';
import ora from 'ora';
import { BitVM3Protocol } from './core/BitVM3Protocol';
import { TrustlessVault } from './vault/TrustlessVault';
import { TransactionManager } from './core/TransactionManager';
import { Participant } from './core/types';
import { ChallengeResponseSystem } from './challenge/ChallengeResponse';

const program = new Command();

// Global instances
let protocol: BitVM3Protocol;
let vault: TrustlessVault;
let challengeSystem: ChallengeResponseSystem;
let transactionManager: TransactionManager;

/**
 * Initialize the system
 */
async function initialize() {
  const spinner = ora('Initializing BitVM3 system...').start();
  
  try {
    // Initialize components
    protocol = new BitVM3Protocol();
    vault = new TrustlessVault();
    challengeSystem = new ChallengeResponseSystem();
    transactionManager = new TransactionManager();
    
    // Generate key pairs for participants
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
    await protocol.initialize(alice, bob);
    
    spinner.succeed('BitVM3 system initialized successfully!');
    
    // Display participant info
    console.log('\n' + chalk.cyan('📊 Participants:'));
    console.log(chalk.yellow('Alice:'), `${alice.balance.BTC} BTC, ${alice.balance.USDT} USDT`);
    console.log(chalk.yellow('Bob:'), `${bob.balance.BTC} BTC, ${bob.balance.USDT} USDT`);
    
  } catch (error) {
    spinner.fail('Initialization failed');
    console.error(chalk.red(error));
    process.exit(1);
  }
}

/**
 * Interactive menu
 */
async function interactiveMenu() {
  const choices = [
    { name: '💰 Deposit BTC (Alice)', value: 'deposit_btc' },
    { name: '💵 Deposit USDT (Bob)', value: 'deposit_usdt' },
    { name: '💸 Withdraw BTC', value: 'withdraw_btc' },
    { name: '💸 Withdraw USDT', value: 'withdraw_usdt' },
    { name: '📝 Create Lending Position', value: 'create_lending' },
    { name: '💵 Repay Loan', value: 'repay_loan' },
    { name: '⚔️  Challenge Transaction', value: 'challenge' },
    { name: '📊 View Vault Statistics', value: 'stats' },
    { name: '👥 View Participants', value: 'participants' },
    { name: '🔍 Check Liquidations', value: 'liquidations' },
    { name: '❌ Exit', value: 'exit' }
  ];
  
  const { action } = await inquirer.prompt([
    {
      type: 'list',
      name: 'action',
      message: 'What would you like to do?',
      choices
    }
  ]);
  
  return action;
}

/**
 * Handle deposit BTC
 */
async function handleDepositBTC() {
  const { amount } = await inquirer.prompt([
    {
      type: 'number',
      name: 'amount',
      message: 'Enter BTC amount to deposit:',
      default: 1.0,
      validate: (value) => value > 0 || 'Amount must be positive'
    }
  ]);
  
  const spinner = ora('Processing BTC deposit...').start();
  
  try {
    await protocol.deposit('alice', amount, 'BTC');
    await vault.depositBTC('alice', amount);
    spinner.succeed(`Successfully deposited ${amount} BTC`);
  } catch (error) {
    spinner.fail('Deposit failed');
    console.error(chalk.red(error));
  }
}

/**
 * Handle deposit USDT
 */
async function handleDepositUSDT() {
  const { amount } = await inquirer.prompt([
    {
      type: 'number',
      name: 'amount',
      message: 'Enter USDT amount to deposit:',
      default: 10000,
      validate: (value) => value > 0 || 'Amount must be positive'
    }
  ]);
  
  const spinner = ora('Processing USDT deposit...').start();
  
  try {
    await protocol.deposit('bob', amount, 'USDT');
    await vault.depositUSDT('bob', amount);
    spinner.succeed(`Successfully deposited ${amount} USDT`);
  } catch (error) {
    spinner.fail('Deposit failed');
    console.error(chalk.red(error));
  }
}

/**
 * Handle withdraw BTC
 */
async function handleWithdrawBTC() {
  const { participant, amount } = await inquirer.prompt([
    {
      type: 'list',
      name: 'participant',
      message: 'Who is withdrawing?',
      choices: ['alice', 'bob']
    },
    {
      type: 'number',
      name: 'amount',
      message: 'Enter BTC amount to withdraw:',
      default: 0.5,
      validate: (value) => value > 0 || 'Amount must be positive'
    }
  ]);
  
  const spinner = ora('Processing BTC withdrawal with garbled circuits...').start();
  
  try {
    const success = await protocol.withdraw(participant, amount, 'BTC');
    if (success) {
      await vault.withdrawBTC(participant, amount);
      spinner.succeed(`Successfully withdrew ${amount} BTC`);
    } else {
      spinner.fail('Withdrawal failed verification');
    }
  } catch (error) {
    spinner.fail('Withdrawal failed');
    console.error(chalk.red(error));
  }
}

/**
 * Handle create lending position
 */
async function handleCreateLending() {
  const { amountUSDT, collateralBTC } = await inquirer.prompt([
    {
      type: 'number',
      name: 'amountUSDT',
      message: 'Enter USDT amount to lend:',
      default: 5000,
      validate: (value) => value > 0 || 'Amount must be positive'
    },
    {
      type: 'number',
      name: 'collateralBTC',
      message: 'Enter BTC collateral amount:',
      default: 0.15,
      validate: (value) => value > 0 || 'Collateral must be positive'
    }
  ]);
  
  const spinner = ora('Creating lending position...').start();
  
  try {
    const position = await vault.createLendingPosition(
      'bob',  // lender
      'alice', // borrower
      amountUSDT,
      collateralBTC
    );
    spinner.succeed('Lending position created successfully');
    console.log(chalk.green('Position details:'), position);
  } catch (error) {
    spinner.fail('Failed to create lending position');
    console.error(chalk.red(error));
  }
}

/**
 * Handle challenge
 */
async function handleChallenge() {
  const { transactionId } = await inquirer.prompt([
    {
      type: 'input',
      name: 'transactionId',
      message: 'Enter transaction ID to challenge:',
      default: 'bob_withdraw'
    }
  ]);
  
  const spinner = ora('Initiating challenge...').start();
  
  try {
    const challenge = await protocol.challengeTransaction(
      'alice',
      transactionId,
      'malicious_withdrawal_proof'
    );
    spinner.succeed('Challenge initiated successfully');
    console.log(chalk.green('Challenge details:'), challenge);
  } catch (error) {
    spinner.fail('Challenge failed');
    console.error(chalk.red(error));
  }
}

/**
 * Display vault statistics
 */
async function displayStats() {
  const stats = vault.getStatistics();
  const protocolState = protocol.getVaultState();
  
  console.log('\n' + chalk.cyan('📊 Vault Statistics:'));
  console.log(chalk.yellow('Total BTC:'), stats.totalBTC);
  console.log(chalk.yellow('Total USDT:'), stats.totalUSDT);
  console.log(chalk.yellow('Active Positions:'), stats.activePositions);
  console.log(chalk.yellow('Total Lent USDT:'), stats.totalLentUSDT);
  console.log(chalk.yellow('Total Collateral BTC:'), stats.totalCollateralBTC);
  console.log(chalk.yellow('Block Height:'), stats.blockHeight);
  console.log(chalk.yellow('State Root:'), stats.stateRoot.substring(0, 16) + '...');
  console.log(chalk.yellow('Collateral Ratio:'), protocolState.collateralRatio);
}

/**
 * Display participants
 */
async function displayParticipants() {
  const alice = protocol.getParticipant('alice');
  const bob = protocol.getParticipant('bob');
  
  console.log('\n' + chalk.cyan('👥 Participants:'));
  
  if (alice) {
    console.log(chalk.yellow('\nAlice:'));
    console.log('  BTC Balance:', alice.balance.BTC);
    console.log('  USDT Balance:', alice.balance.USDT);
    console.log('  Public Key:', alice.publicKey.substring(0, 20) + '...');
  }
  
  if (bob) {
    console.log(chalk.yellow('\nBob:'));
    console.log('  BTC Balance:', bob.balance.BTC);
    console.log('  USDT Balance:', bob.balance.USDT);
    console.log('  Public Key:', bob.publicKey.substring(0, 20) + '...');
  }
}

/**
 * Check liquidations
 */
async function checkLiquidations() {
  const spinner = ora('Checking for liquidations...').start();
  
  try {
    const liquidated = await vault.checkLiquidations();
    if (liquidated.length > 0) {
      spinner.succeed(`Liquidated ${liquidated.length} positions`);
      console.log(chalk.yellow('Liquidated positions:'), liquidated);
    } else {
      spinner.succeed('No positions require liquidation');
    }
  } catch (error) {
    spinner.fail('Liquidation check failed');
    console.error(chalk.red(error));
  }
}

/**
 * Main CLI loop
 */
async function main() {
  console.log(chalk.cyan.bold('\n🔷 Welcome to BitVM3 Trustless Vault\n'));
  
  await initialize();
  
  let running = true;
  while (running) {
    console.log('\n' + chalk.gray('─'.repeat(50)));
    const action = await interactiveMenu();
    
    switch (action) {
      case 'deposit_btc':
        await handleDepositBTC();
        break;
      case 'deposit_usdt':
        await handleDepositUSDT();
        break;
      case 'withdraw_btc':
        await handleWithdrawBTC();
        break;
      case 'withdraw_usdt':
        console.log(chalk.yellow('USDT withdrawal not implemented in MVP'));
        break;
      case 'create_lending':
        await handleCreateLending();
        break;
      case 'repay_loan':
        console.log(chalk.yellow('Loan repayment not implemented in MVP'));
        break;
      case 'challenge':
        await handleChallenge();
        break;
      case 'stats':
        await displayStats();
        break;
      case 'participants':
        await displayParticipants();
        break;
      case 'liquidations':
        await checkLiquidations();
        break;
      case 'exit':
        running = false;
        break;
    }
  }
  
  console.log(chalk.cyan('\n👋 Thank you for using BitVM3!\n'));
  process.exit(0);
}

// CLI Commands
program
  .name('bitvm3')
  .description('BitVM3 Trustless Vault CLI')
  .version('1.0.0');

program
  .command('start')
  .description('Start interactive BitVM3 session')
  .action(main);

program
  .command('demo')
  .description('Run automated demo scenario')
  .action(async () => {
    console.log(chalk.cyan.bold('\n🎬 Running BitVM3 Demo Scenario\n'));
    
    await initialize();
    
    console.log(chalk.green('\n1. Alice deposits 1 BTC'));
    await protocol.deposit('alice', 1, 'BTC');
    await vault.depositBTC('alice', 1);
    
    console.log(chalk.green('\n2. Bob deposits 10000 USDT'));
    await protocol.deposit('bob', 10000, 'USDT');
    await vault.depositUSDT('bob', 10000);
    
    console.log(chalk.green('\n3. Creating lending position'));
    await vault.createLendingPosition('bob', 'alice', 5000, 0.15);
    
    console.log(chalk.green('\n4. Alice attempts withdrawal'));
    const success = await protocol.withdraw('alice', 0.5, 'BTC');
    if (success) {
      await vault.withdrawBTC('alice', 0.5);
    }
    
    console.log(chalk.green('\n5. Bob challenges a transaction'));
    const challenge = await protocol.challengeTransaction(
      'alice',
      'suspicious_tx',
      'proof_of_misconduct'
    );
    
    console.log(chalk.green('\n6. Final statistics'));
    await displayStats();
    
    console.log(chalk.cyan('\n✅ Demo completed successfully!\n'));
  });

// Parse command line arguments
program.parse(process.argv);

// If no command specified, show help
if (!process.argv.slice(2).length) {
  program.outputHelp();
}