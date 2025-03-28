import dotenv from 'dotenv';
dotenv.config();

export const config = {
    port: process.env.PORT || 3000,
    sonicRpcUrl: process.env.SONIC_RPC_URL!,
    agentPrivateKey: process.env.AGENT_WALLET_PRIVATE_KEY!,
    contractAddress: process.env.CONTRACT_ADDRESS!,
    geminiApiKey: process.env.GEMINI_API_KEY!,
    agentDob: process.env.AGENT_DOB!,
    attestationIntervalHours: parseInt(process.env.ATTESTATION_INTERVAL_HOURS || '1', 10),
    // Add path to ABI file if loading dynamically
    contractAbiPath: process.env.CONTRACT_ABI_PATH || '../AIAgentRegistry.json', // Adjust path relative to dist/config
};

// Basic validation
if (!config.sonicRpcUrl || !config.agentPrivateKey || !config.contractAddress || !config.geminiApiKey || !config.agentDob) {
    console.error("ERROR: Missing required environment variables!");
    process.exit(1);
}