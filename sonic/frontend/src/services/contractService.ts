import { ethers, Contract, JsonRpcProvider } from 'ethers';
import { config } from '../config';

// Read-only provider for fetching contract state
const readOnlyProvider = new JsonRpcProvider(config.sonicRpcUrl);
const agentRegistryContract = new Contract(config.registryContractAddress, config.registryAbi, readOnlyProvider);

export interface AgentInfo {
    agentWallet: string;
    endpointUrl: string;
    currentAttestationReportHash: string;
    lastAttestationTimestamp: bigint; // Changed to bigint based on Solidity uint256
    isActive: boolean;
}

export async function getAgentInfo(agentWalletAddress: string): Promise<AgentInfo | null> {
    try {
        const info = await agentRegistryContract.getAgentInfo(agentWalletAddress);
        // Ethers v6 returns struct data mapped correctly
        return info as AgentInfo;
    } catch (error) {
        console.error("Error fetching agent info:", error);
        return null;
    }
}

// Add functions to fetch interaction/guess logs if needed