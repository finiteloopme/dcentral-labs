#!/usr/bin/env node

/**
 * Midnight Token CLI
 * Command-line interface for interacting with token contracts
 */

import { createInterface } from 'readline';
import { initializeMidnight, createWallet, deployTokenContract, callContractMethod, getContractState } from './midnight-sdk.js';
import { createLogger } from './logger.js';
import * as dotenv from 'dotenv';

dotenv.config();

const logger = createLogger();
const rl = createInterface({
    input: process.stdin,
    output: process.stdout
});

function prompt(question) {
    return new Promise((resolve) => {
        rl.question(question, resolve);
    });
}

async function generateWalletSeed() {
    // Generate a random 64-character hex seed
    const bytes = new Uint8Array(32);
    crypto.getRandomValues(bytes);
    return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function main() {
    logger.info('🌙 Midnight Token CLI');
    logger.info('====================');
    
    try {
        // Initialize Midnight SDK
        logger.info('Initializing Midnight SDK...');
        const { config, providers } = await initializeMidnight();
        
        // Check for wallet seed
        let walletSeed = process.env.WALLET_SEED;
        if (!walletSeed) {
            logger.warn('No wallet seed found in environment');
            const choice = await prompt('Generate new wallet? (y/n): ');
            
            if (choice.toLowerCase() === 'y') {
                walletSeed = await generateWalletSeed();
                logger.info(`Generated wallet seed: ${walletSeed}`);
                logger.warn('Save this seed securely! Add it to your .env file');
            } else {
                logger.error('Wallet seed required. Add WALLET_SEED to .env');
                process.exit(1);
            }
        }
        
        // Create wallet
        logger.info('Creating wallet...');
        const wallet = await createWallet(walletSeed);
        const walletState = await wallet.state();
        logger.info(`Wallet address: ${walletState.address}`);
        
        // Main menu loop
        let running = true;
        let deployedContract = null;
        
        while (running) {
            console.log('\n=== Main Menu ===');
            console.log('1. Deploy new token contract');
            console.log('2. Connect to existing contract');
            console.log('3. Check balance');
            console.log('4. Transfer tokens');
            console.log('5. Get contract info');
            console.log('6. Exit');
            
            const choice = await prompt('\nSelect option: ');
            
            switch (choice) {
                case '1':
                    // Deploy new contract
                    const name = await prompt('Token name: ');
                    const symbol = await prompt('Token symbol: ');
                    const supply = await prompt('Total supply: ');
                    
                    logger.info('Deploying contract...');
                    try {
                        // Load compiled contract
                        const contractModule = await import('../src/managed/token/contract/index.cjs');
                        const { Contract } = contractModule;
                        
                        deployedContract = await deployTokenContract(
                            Contract,
                            providers,
                            wallet,
                            name,
                            symbol,
                            parseInt(supply)
                        );
                        
                        logger.info(`✅ Contract deployed at: ${deployedContract.contractAddress}`);
                    } catch (error) {
                        logger.error('Deployment failed:', error.message);
                        logger.info('Make sure to compile the contract first: npm run compile');
                    }
                    break;
                    
                case '2':
                    // Connect to existing contract
                    const address = await prompt('Contract address: ');
                    try {
                        const state = await getContractState(providers, address);
                        deployedContract = { contractAddress: address };
                        logger.info('✅ Connected to contract');
                        logger.info(`State: ${JSON.stringify(state, null, 2)}`);
                    } catch (error) {
                        logger.error('Failed to connect:', error.message);
                    }
                    break;
                    
                case '3':
                    // Check balance
                    if (!deployedContract) {
                        logger.warn('No contract connected. Deploy or connect first.');
                        break;
                    }
                    
                    const balanceAddress = await prompt('Address to check: ');
                    try {
                        const state = await getContractState(providers, deployedContract.contractAddress);
                        const balance = state.balances[balanceAddress] || 0;
                        logger.info(`Balance: ${balance}`);
                    } catch (error) {
                        logger.error('Failed to check balance:', error.message);
                    }
                    break;
                    
                case '4':
                    // Transfer tokens
                    if (!deployedContract) {
                        logger.warn('No contract connected. Deploy or connect first.');
                        break;
                    }
                    
                    const to = await prompt('Recipient address: ');
                    const amount = await prompt('Amount: ');
                    
                    logger.info('Generating ZK proof and transferring...');
                    try {
                        const txData = await callContractMethod(
                            deployedContract,
                            'transfer',
                            [to, parseInt(amount)]
                        );
                        logger.info(`✅ Transfer complete! Tx: ${txData.txHash}`);
                    } catch (error) {
                        logger.error('Transfer failed:', error.message);
                    }
                    break;
                    
                case '5':
                    // Get contract info
                    if (!deployedContract) {
                        logger.warn('No contract connected. Deploy or connect first.');
                        break;
                    }
                    
                    try {
                        const state = await getContractState(providers, deployedContract.contractAddress);
                        logger.info('Contract State:');
                        console.log(JSON.stringify(state, null, 2));
                    } catch (error) {
                        logger.error('Failed to get contract info:', error.message);
                    }
                    break;
                    
                case '6':
                    running = false;
                    break;
                    
                default:
                    logger.warn('Invalid option');
            }
        }
        
        // Cleanup
        await wallet.close();
        rl.close();
        logger.info('Goodbye! 🌙');
        
    } catch (error) {
        logger.error('Fatal error:', error.message);
        if (error.message.includes('Proof server')) {
            logger.info('Start the proof server with: npm run proof-server');
        }
        process.exit(1);
    }
}

// Run the CLI
main().catch(console.error);