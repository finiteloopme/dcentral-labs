/**
 * Midnight SDK Integration Module
 * 
 * This module provides integration with the Midnight Network SDK
 * for zero-knowledge proof generation and contract deployment.
 */

import { httpClientProofProvider } from '@midnight-ntwrk/midnight-js-http-client-proof-provider';
import { indexerPublicDataProvider } from '@midnight-ntwrk/midnight-js-indexer-public-data-provider';
import { levelPrivateStateProvider } from '@midnight-ntwrk/midnight-js-level-private-state-provider';
import { NodeZkConfigProvider } from '@midnight-ntwrk/midnight-js-node-zk-config-provider';
import { deployContract, findDeployedContract } from '@midnight-ntwrk/midnight-js-contracts';
import { NetworkId, setNetworkId } from '@midnight-ntwrk/midnight-js-network-id';
import { WalletBuilder } from '@midnight-ntwrk/wallet';
import { createLogger } from './logger.js';
import * as dotenv from 'dotenv';

dotenv.config();

// Auto-detect containerized environment
function getProofServerUrl() {
    // Check if explicitly configured
    if (process.env.PROOF_SERVER_URL) {
        return process.env.PROOF_SERVER_URL;
    }
    
    // Check if running in container (Cloud Workstation or local container)
    if (process.env.WORKSTATION_CLUSTER || process.env.CONTAINER_ENV === 'midnight') {
        // Use internal proof server port
        return 'http://localhost:8081';
    }
    
    // Default for standalone development
    return 'http://localhost:6300';
}

// Configuration
const config = {
    // Network configuration
    network: process.env.MIDNIGHT_NETWORK || 'testnet',
    indexer: process.env.MIDNIGHT_INDEXER || 'https://indexer.testnet-02.midnight.network/api/v1/graphql',
    indexerWS: process.env.MIDNIGHT_INDEXER_WS || 'wss://indexer.testnet-02.midnight.network/api/v1/graphql/ws',
    node: process.env.MIDNIGHT_NODE || 'https://rpc.testnet-02.midnight.network',
    proofServer: getProofServerUrl(),
    
    // Private state storage
    privateStateStoreName: 'token-private-state',
    
    // ZK config path (where compiled circuits are stored)
    zkConfigPath: './src/managed/token'
};

// Set network ID based on configuration
export function initializeNetwork() {
    switch (config.network) {
        case 'testnet':
            setNetworkId(NetworkId.TestNet);
            break;
        case 'mainnet':
            setNetworkId(NetworkId.MainNet);
            break;
        case 'local':
            setNetworkId(NetworkId.Undeployed);
            break;
        default:
            setNetworkId(NetworkId.TestNet);
    }
}

/**
 * Create providers for Midnight SDK
 */
export function createProviders() {
    return {
        privateStateProvider: levelPrivateStateProvider({
            privateStateStoreName: config.privateStateStoreName,
        }),
        publicDataProvider: indexerPublicDataProvider(config.indexer, config.indexerWS),
        zkConfigProvider: new NodeZkConfigProvider(config.zkConfigPath),
        proofProvider: httpClientProofProvider(config.proofServer),
    };
}

/**
 * Create a wallet from seed
 * @param {string} seed - The wallet seed (64 character hex string)
 * @returns {Promise<Wallet>} The wallet instance
 */
export async function createWallet(seed) {
    const wallet = await WalletBuilder.buildFromSeed(
        config.indexer,
        config.indexerWS,
        config.proofServer,
        config.node,
        seed,
        config.network === 'testnet' ? 'testnet' : 'undeployed',
        'warn'
    );
    
    wallet.start();
    return wallet;
}

/**
 * Deploy a token contract
 * @param {Object} contract - The compiled contract
 * @param {Object} providers - The SDK providers
 * @param {Object} walletProvider - The wallet provider
 * @param {string} name - Token name
 * @param {string} symbol - Token symbol
 * @param {number} totalSupply - Initial supply
 */
export async function deployTokenContract(contract, providers, walletProvider, name, symbol, totalSupply) {
    const logger = createLogger();
    logger.info('Deploying token contract...');
    
    try {
        // Deploy contract with initial parameters
        const deployedContract = await deployContract(
            providers,
            {
                contract,
                initialState: {
                    name,
                    symbol,
                    totalSupply,
                    balances: {}
                }
            },
            walletProvider
        );
        
        logger.info(`Contract deployed at: ${deployedContract.contractAddress}`);
        return deployedContract;
    } catch (error) {
        logger.error('Contract deployment failed:', error);
        throw error;
    }
}

/**
 * Call a contract method with zero-knowledge proof
 * @param {Object} contract - The deployed contract instance
 * @param {string} method - Method name to call
 * @param {Array} args - Method arguments
 */
export async function callContractMethod(contract, method, args) {
    const logger = createLogger();
    logger.info(`Calling contract method: ${method}`);
    
    try {
        // The SDK automatically generates ZK proofs via the proof server
        const txData = await contract.callTx[method](...args);
        
        logger.info(`Transaction submitted: ${txData.txHash}`);
        return txData;
    } catch (error) {
        logger.error(`Method call failed:`, error);
        throw error;
    }
}

/**
 * Get contract state
 * @param {Object} providers - The SDK providers
 * @param {string} contractAddress - The contract address
 */
export async function getContractState(providers, contractAddress) {
    const contractState = await providers.publicDataProvider.contractState(
        contractAddress,
        { type: 'latest' }
    );
    
    return contractState;
}

/**
 * Check if proof server is available
 */
export async function checkProofServer() {
    try {
        const response = await fetch(`${config.proofServer}/health`);
        if (response.ok) {
            const text = await response.text();
            return text.includes('alive');
        }
        return false;
    } catch (error) {
        return false;
    }
}

/**
 * Initialize Midnight SDK connection
 */
export async function initializeMidnight() {
    const logger = createLogger();
    
    // Check proof server
    const proofServerAvailable = await checkProofServer();
    if (!proofServerAvailable) {
        logger.warn('Proof server not available at', config.proofServer);
        logger.warn('Please start the proof server with: npm run proof-server');
        throw new Error('Proof server not available');
    }
    
    logger.info('Proof server connected:', config.proofServer);
    
    // Initialize network
    initializeNetwork();
    logger.info('Network initialized:', config.network);
    
    // Create providers
    const providers = createProviders();
    logger.info('Providers created');
    
    return {
        config,
        providers,
        logger
    };
}

export default {
    initializeMidnight,
    createWallet,
    deployTokenContract,
    callContractMethod,
    getContractState,
    checkProofServer
};