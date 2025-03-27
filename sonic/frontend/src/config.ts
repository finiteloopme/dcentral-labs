export const config = {
    agentApiBaseUrl: process.env.REACT_APP_AGENT_API_BASE_URL || "http://localhost:5001/api/agent",
    registryContractAddress: process.env.REACT_APP_REGISTRY_CONTRACT_ADDRESS!,
    agentWalletAddress: process.env.REACT_APP_AGENT_WALLET_ADDRESS!,
    sonicRpcUrl: process.env.REACT_APP_SONIC_RPC_URL!,
    attestationIntervalHours: process.env.REACT_APP_ATTESTATION_INTERVAL_HOURS || "1",
    // Add ABI path or import directly
    registryAbi: [ /* --- PASTE YOUR REGISTRY ABI HERE --- */ ]
};

if (!config.agentApiBaseUrl || !config.registryContractAddress || !config.agentWalletAddress || !config.sonicRpcUrl) {
    console.error("ERROR: Frontend environment variables not set!");
    // Handle this more gracefully in UI
}