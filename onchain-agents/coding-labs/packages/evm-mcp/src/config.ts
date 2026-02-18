/**
 * Configuration for the EVM MCP server.
 *
 * This server wraps the Foundry toolchain (Anvil, Forge, Cast) for EVM development.
 * It provides a shared infrastructure for all EVM chain agents.
 */

// -----------------------------------------------------------------------------
// Chain Presets
// -----------------------------------------------------------------------------

export interface ChainConfig {
  name: string;
  chainId: number;
  rpcUrl: string;
  explorerUrl: string;
  explorerApiUrl?: string;
  nativeCurrency: {
    name: string;
    symbol: string;
    decimals: number;
  };
}

/**
 * Built-in chain presets.
 * Agents can use these by name, or provide custom chain config.
 */
export const CHAIN_PRESETS: Record<string, ChainConfig> = {
  'sonic-mainnet': {
    name: 'Sonic Mainnet',
    chainId: 146,
    rpcUrl: 'https://rpc.soniclabs.com',
    explorerUrl: 'https://sonicscan.org',
    nativeCurrency: { name: 'Sonic', symbol: 'S', decimals: 18 },
  },
  'somnia-testnet': {
    name: 'Somnia Shannon Testnet',
    chainId: 50312,
    rpcUrl: 'https://dream-rpc.somnia.network/',
    explorerUrl: 'https://shannon-explorer.somnia.network',
    nativeCurrency: { name: 'Somnia Test Token', symbol: 'STT', decimals: 18 },
  },
  'ethereum-sepolia': {
    name: 'Ethereum Sepolia',
    chainId: 11155111,
    rpcUrl: 'https://rpc.sepolia.org',
    explorerUrl: 'https://sepolia.etherscan.io',
    nativeCurrency: { name: 'Sepolia Ether', symbol: 'ETH', decimals: 18 },
  },
  'base-sepolia': {
    name: 'Base Sepolia',
    chainId: 84532,
    rpcUrl: 'https://sepolia.base.org',
    explorerUrl: 'https://sepolia.basescan.org',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  },
};

/**
 * Get a chain config by preset name.
 */
export function getChainPreset(name: string): ChainConfig | undefined {
  return CHAIN_PRESETS[name];
}

/**
 * Get chain name by chain ID.
 */
export function getChainName(chainId: number): string {
  for (const [, config] of Object.entries(CHAIN_PRESETS)) {
    if (config.chainId === chainId) {
      return config.name;
    }
  }
  return `Chain ${chainId}`;
}

// -----------------------------------------------------------------------------
// Anvil Default Accounts
// -----------------------------------------------------------------------------

/**
 * Anvil's default pre-funded accounts.
 * These are deterministic and always the same.
 * Each account starts with 10,000 ETH.
 */
export const ANVIL_ACCOUNTS = [
  {
    address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    privateKey:
      '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
  },
  {
    address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    privateKey:
      '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
  },
  {
    address: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    privateKey:
      '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
  },
  {
    address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
    privateKey:
      '0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6',
  },
  {
    address: '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65',
    privateKey:
      '0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a',
  },
] as const;

// -----------------------------------------------------------------------------
// Server Configuration
// -----------------------------------------------------------------------------

export interface EvmMcpConfig {
  /** Server port */
  port: number;
  /** Server host */
  host: string;
  /** Anvil port for local fork */
  anvilPort: number;
  /** Temp directory for Foundry projects */
  tempDir: string;
  /** Default Solidity version */
  defaultSolcVersion: string;
}

export function loadConfig(): EvmMcpConfig {
  return {
    port: parseInt(process.env.EVM_MCP_PORT || '4011', 10),
    host: process.env.EVM_MCP_HOST || 'localhost',
    anvilPort: parseInt(process.env.ANVIL_PORT || '8545', 10),
    tempDir: process.env.FOUNDRY_TEMP_DIR || '/tmp/foundry-projects',
    defaultSolcVersion: process.env.DEFAULT_SOLC_VERSION || '0.8.28',
  };
}
