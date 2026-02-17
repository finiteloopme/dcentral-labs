/**
 * Configuration for the Midnight MCP server.
 *
 * Compatibility Matrix (Ledger 7.0.0 / Compatibility v1.0):
 *   Compact Compiler: 0.28.0 (language pragma 0.20)
 *   Compact DevTools: 0.4.0
 *   Compact Runtime:  0.14.0
 *   Compact JS:       v2.4.0
 *   Proof Server:     7.0.0
 *   Indexer:          v3.0.0
 *   Midnight.js:      v3.0.0
 *   Node:             0.20.1
 *   On-chain Runtime: v2 (2.0.0)
 *   DApp Connector:   v4.0.0
 *   Wallet SDK:       1.0.0
 *
 * Source: https://docs.midnight.network/next/relnotes/overview#compatibility-matrix
 */

export const COMPATIBILITY_MATRIX = {
  ledger: '7.0.0',
  node: '0.20.1',
  proofServer: '7.0.0',
  onchainRuntime: '2.0.0',
  compactRuntime: '0.14.0',
  compactCompiler: '0.28.0',
  compactLanguage: '0.20',
  compactDevTools: '0.4.0',
  compactJs: '2.4.0',
  indexer: '3.0.0',
  dappConnectorApi: '4.0.0',
  walletSdk: '1.0.0',
  midnightJs: '3.0.0',
} as const;

export interface NetworkConfig {
  name: string;
  nodeRpc: string;
  indexerGraphql: string;
  indexerWs: string;
  proofServer: string;
  faucetUrl: string;
  explorerUrl: string;
}

export const NETWORKS: Record<string, NetworkConfig> = {
  preview: {
    name: 'Preview',
    nodeRpc: 'https://rpc.preview.midnight.network',
    indexerGraphql: 'https://indexer.preview.midnight.network/api/v3/graphql',
    indexerWs: 'wss://indexer.preview.midnight.network/api/v3/graphql/ws',
    proofServer: 'https://lace-proof-pub.preview.midnight.network',
    faucetUrl: 'https://faucet.preview.midnight.network/',
    explorerUrl: 'https://explorer.preview.midnight.network/',
  },
  preprod: {
    name: 'Preprod',
    nodeRpc: 'https://rpc.preprod.midnight.network',
    indexerGraphql: 'https://indexer.preprod.midnight.network/api/v3/graphql',
    indexerWs: 'wss://indexer.preprod.midnight.network/api/v3/graphql/ws',
    proofServer: 'https://lace-proof-pub.preprod.midnight.network',
    faucetUrl: 'https://faucet.preprod.midnight.network/',
    explorerUrl: 'https://explorer.preprod.midnight.network/',
  },
};

/**
 * Docker images for local infrastructure (optional).
 */
export const DOCKER_IMAGES = {
  proofServer: 'midnightnetwork/proof-server:latest',
  indexerStandalone: 'midnightntwrk/indexer-standalone:3.0.0',
  node: 'midnightntwrk/midnight-node:0.20.0',
  nodeToolkit: 'midnightntwrk/midnight-node-toolkit:0.20.0',
} as const;

export interface MidnightMCPConfig {
  /** Server port */
  port: number;
  /** Server host */
  host: string;
  /** Path to compact binary (or 'compact' if in PATH) */
  compactBinaryPath: string;
  /** Local proof server URL (overrides network default) */
  proofServerUrl: string | null;
  /** Indexer URL overrides (overrides network defaults) */
  indexerOverrides: {
    preview: string | null;
    preprod: string | null;
  };
  /** Default network for tools */
  defaultNetwork: 'preview' | 'preprod';
}

export function loadConfig(): MidnightMCPConfig {
  return {
    port: parseInt(process.env.MIDNIGHT_MCP_PORT || '4010', 10),
    host: process.env.MIDNIGHT_MCP_HOST || 'localhost',
    compactBinaryPath: process.env.COMPACT_BINARY_PATH || 'compact',
    proofServerUrl: process.env.MIDNIGHT_PROOF_SERVER_URL || null,
    indexerOverrides: {
      preview: process.env.MIDNIGHT_INDEXER_PREVIEW_URL || null,
      preprod: process.env.MIDNIGHT_INDEXER_PREPROD_URL || null,
    },
    defaultNetwork:
      (process.env.MIDNIGHT_DEFAULT_NETWORK as 'preview' | 'preprod') ||
      'preview',
  };
}

/**
 * Get the indexer URL for a given network, respecting overrides.
 */
export function getIndexerUrl(
  config: MidnightMCPConfig,
  network: string
): string {
  const key = network as keyof typeof config.indexerOverrides;
  if (config.indexerOverrides[key]) {
    return config.indexerOverrides[key];
  }
  const net = NETWORKS[network];
  if (!net) {
    throw new Error(
      `Unknown network: ${network}. Valid: ${Object.keys(NETWORKS).join(', ')}`
    );
  }
  return net.indexerGraphql;
}

/**
 * Get the proof server URL, preferring local override then network default.
 */
export function getProofServerUrl(
  config: MidnightMCPConfig,
  network: string
): string {
  if (config.proofServerUrl) {
    return config.proofServerUrl;
  }
  const net = NETWORKS[network];
  if (!net) {
    throw new Error(
      `Unknown network: ${network}. Valid: ${Object.keys(NETWORKS).join(', ')}`
    );
  }
  return net.proofServer;
}

/**
 * Resolve network name, defaulting to config default.
 */
export function resolveNetwork(
  config: MidnightMCPConfig,
  network?: string
): string {
  const resolved = network || config.defaultNetwork;
  if (!NETWORKS[resolved]) {
    throw new Error(
      `Unknown network: ${resolved}. Valid: ${Object.keys(NETWORKS).join(', ')}`
    );
  }
  return resolved;
}
