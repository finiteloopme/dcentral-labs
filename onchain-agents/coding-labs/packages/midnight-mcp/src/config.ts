/**
 * Configuration for the Midnight MCP server.
 *
 * This server uses:
 *   - midnight-node-toolkit binary for blockchain operations (wallet, deploy, call)
 *   - compactc binary for Compact smart contract compilation
 *
 * Both binaries are installed at container build time from official releases.
 *
 * IMPORTANT: Node and toolkit are released together with matching versions.
 * MIDNIGHT_VERSION is the single source of truth for node/toolkit.
 * COMPACTC_VERSION must match the compatibility matrix for the node version.
 *
 * Compatibility Matrix (Ledger 7.0.0 / Compatibility v1.0):
 *   Node + Toolkit:   0.20.1 (version-aligned)
 *   Compact Compiler: 0.28.0 (separate binary, installed from GitHub releases)
 *   Indexer Image:    3.0.0 (separate versioning)
 *   Proof Server:     7.0.0
 *   Ledger:           7.0.0
 *   Indexer API:      v3.0.0
 *
 * Source: https://docs.midnight.network/next/relnotes/overview#compatibility-matrix
 */

/**
 * Single version for node and toolkit (they are released together).
 * This is used in Containerfile to copy the matching toolkit binary.
 */
export const MIDNIGHT_VERSION = '0.20.1';

/** Indexer uses separate versioning from node/toolkit */
export const INDEXER_VERSION = '3.0.0';

/** Proof server version */
export const PROOF_SERVER_VERSION = '7.0.0';

/** Compact compiler version (must match compatibility matrix for node version) */
export const COMPACTC_VERSION = '0.28.0';

export const COMPATIBILITY_MATRIX = {
  /** Single version for node + toolkit */
  version: MIDNIGHT_VERSION,
  ledger: '7.0.0',
  proofServer: PROOF_SERVER_VERSION,
  compactCompiler: COMPACTC_VERSION,
  /** Compact language version supported by this compiler version */
  compactLanguage: '0.20',
  indexer: INDEXER_VERSION,
} as const;

/**
 * Network identifier for Midnight.js SDK.
 * Maps to @midnight-ntwrk/midnight-js-network-id NetworkId enum values.
 */
export type MidnightNetworkId = 'undeployed' | 'testnet';

export interface NetworkConfig {
  name: string;
  /** Midnight.js NetworkId: 'undeployed' for standalone, 'testnet' for preview/preprod */
  networkId: MidnightNetworkId;
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
    networkId: 'testnet',
    nodeRpc: 'https://rpc.preview.midnight.network',
    indexerGraphql: 'https://indexer.preview.midnight.network/api/v3/graphql',
    indexerWs: 'wss://indexer.preview.midnight.network/api/v3/graphql/ws',
    proofServer: 'https://lace-proof-pub.preview.midnight.network',
    faucetUrl: 'https://faucet.preview.midnight.network/',
    explorerUrl: 'https://explorer.preview.midnight.network/',
  },
  preprod: {
    name: 'Preprod',
    networkId: 'testnet',
    nodeRpc: 'https://rpc.preprod.midnight.network',
    indexerGraphql: 'https://indexer.preprod.midnight.network/api/v3/graphql',
    indexerWs: 'wss://indexer.preprod.midnight.network/api/v3/graphql/ws',
    proofServer: 'https://lace-proof-pub.preprod.midnight.network',
    faucetUrl: 'https://faucet.preprod.midnight.network/',
    explorerUrl: 'https://explorer.preprod.midnight.network/',
  },
  local: {
    name: 'Local (Standalone)',
    networkId: 'undeployed',
    // Container URLs with environment variable overrides
    // In containers: midnight-node, midnight-indexer, midnight-proof-server
    // For local dev without containers: localhost
    nodeRpc: process.env.MIDNIGHT_NODE_RPC || 'ws://midnight-node:9944',
    indexerGraphql:
      process.env.MIDNIGHT_INDEXER_URL ||
      'http://midnight-indexer:8088/api/v1/graphql',
    indexerWs:
      process.env.MIDNIGHT_INDEXER_WS ||
      'ws://midnight-indexer:8088/api/v1/graphql/ws',
    proofServer:
      process.env.MIDNIGHT_PROOF_SERVER_URL ||
      'http://midnight-proof-server:6300',
    faucetUrl: '',
    explorerUrl: '',
  },
};

/**
 * Docker images for local infrastructure.
 */
export const DOCKER_IMAGES = {
  /** Node image (same version as toolkit) */
  node: `midnightntwrk/midnight-node:${MIDNIGHT_VERSION}`,
  /** Toolkit image (same version as node) */
  toolkit: `midnightntwrk/midnight-node-toolkit:${MIDNIGHT_VERSION}`,
  /** Proof server (separate versioning) */
  proofServer: `midnightnetwork/proof-server:${PROOF_SERVER_VERSION}`,
  /** Indexer (separate versioning from node) */
  indexer: `midnightntwrk/indexer-standalone:${INDEXER_VERSION}`,
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
  defaultNetwork: 'preview' | 'preprod' | 'local';
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
      (process.env.MIDNIGHT_DEFAULT_NETWORK as
        | 'preview'
        | 'preprod'
        | 'local') || 'local',
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

/**
 * Get the node RPC URL for a given network.
 */
export function getNodeRpcUrl(
  _config: MidnightMCPConfig,
  network: string
): string {
  const net = NETWORKS[network];
  if (!net) {
    throw new Error(
      `Unknown network: ${network}. Valid: ${Object.keys(NETWORKS).join(', ')}`
    );
  }
  return net.nodeRpc;
}
