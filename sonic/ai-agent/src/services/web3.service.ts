import { ethers, Contract, Wallet, JsonRpcProvider, ContractTransactionResponse, NonceManager } from 'ethers';
// import { solidityPackedKeccak256 } from 'web3-utils'; // Using web3-utils for easy solidity packed keccak
import fs from 'fs';
import path from 'path';
import { config } from '../config';
import { OffChainMessageStore } from '../types';

// --- Simple In-Memory Off-Chain Store ---
export const offChainStore: OffChainMessageStore = {}; // Replace with DB/IPFS

export const provider = new JsonRpcProvider(config.sonicRpcUrl);
export const agentWallet = new Wallet(config.agentPrivateKey, provider);
// Use NonceManager to handle nonce automatically
export const agentSigner = new NonceManager(agentWallet);

let contractAbi: any;
try {
    // Construct the absolute path relative to the current file
    const abiPath = path.resolve(__dirname, config.contractAbiPath);
    const abiFile = fs.readFileSync(abiPath, 'utf-8');
    contractAbi = JSON.parse(abiFile).abi; // Assuming truffle/hardhat output format
} catch (error) {
    console.error("ERROR loading contract ABI:", error);
    process.exit(1);
}

export const contract = new Contract(config.contractAddress, contractAbi, agentSigner);

console.log(`Agent Wallet Address: ${agentWallet.address}`);
console.log(`Connected to RPC: ${config.sonicRpcUrl}`);
console.log(`Registry Contract: ${config.contractAddress}`);

// --- Transaction Sending Helper ---
export async function sendAgentTx(
    contractMethodCall: Promise<ContractTransactionResponse>, // The result of contract.functionName(...)
    txDescription: string,
    gasEstimateMultiplier: number = 1.2 // Ethers v6 often handles gas well, but keep option
): Promise<ethers.ContractTransactionResponse | null> {
    try {
        console.log(`Sending TX for: ${txDescription}`);
        // Ethers v6 attempts gas estimation automatically when calling the method
        const txResponse: ContractTransactionResponse = await contractMethodCall;

        console.log(`Sent TX ${txResponse.hash} for ${txDescription}, waiting for confirmation...`);
        // Optional: Wait for 1 confirmation for better assurance, but slows API response
        // const receipt = await txResponse.wait(1);
        // console.log(`TX ${txResponse.hash} confirmed in block ${receipt?.blockNumber}`);
        return txResponse;
    } catch (error: any) {
        console.error(`ERROR sending agent TX for ${txDescription}:`, error.message);
        // TODO: Implement retry logic or more robust error handling/state management
        return null;
    }
}

// --- Token Transfer Helper ---
export async function sendRewardTx(
    recipient: string,
    amountWei: bigint
): Promise<ethers.TransactionResponse | null> {
     try {
        console.log(`Initiating reward transfer of ${ethers.formatEther(amountWei)} SONIC to ${recipient}`);
        const tx = await agentSigner.sendTransaction({
            to: recipient,
            value: amountWei
            // Gas limit/price usually handled by ethers v6, but can specify if needed
        });
        console.log(`Sent reward transfer TX: ${tx.hash}`);
        // Optional: await tx.wait();
        return tx;
    } catch (error: any) {
        console.error(`ERROR sending reward transfer:`, error.message);
         return null;
    }
}


// --- Hashing Utilities ---
export function hashMessage(message: string): string {
    // Equivalent to Solidity's keccak256(abi.encodePacked(message))
    return ethers.solidityPackedKeccak256(['string'], [message]);
}

export function getLogKey(sessionId: string): string {
    // Consistent log key generation matching contract
    return ethers.solidityPackedKeccak256(['address', 'bytes32'], [agentWallet.address, ethers.toUtf8Bytes(sessionId)]);
}

// --- Off-Chain Store Simulation ---
export function storeOffChain(hash: string, message: string): void {
    offChainStore[hash] = message;
    console.log(`Stored off-chain (simulated): <span class="math-inline">\{hash\} \-\> "</span>{message.substring(0, 30)}..."`);
}

export function retrieveFromOffChain(hash: string): string | undefined {
    return offChainStore[hash];
}