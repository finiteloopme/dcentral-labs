/**
 * Centralized configuration and URL resolution for Midnight CLI
 * 
 * URL Resolution Priority:
 * 1. Explicit environment variables (always respected)
 * 2. Auto-detected GCP Workstation (expects Terraform-injected URLs)
 * 3. Localhost defaults (for local development)
 */

/**
 * Check if running in a GCP Workstation environment
 */
export function isGcpWorkstation(): boolean {
  return !!process.env.WORKSTATION_ID;
}

/**
 * Get the current chain environment
 */
export function getChainEnvironment(): string {
  return process.env.CHAIN_ENVIRONMENT || 'standalone';
}

/**
 * Service URL configuration
 */
export interface ServiceUrls {
  nodeUrl: string | undefined;
  indexerUrl: string | undefined;
  proofServerUrl: string | undefined;
}

/**
 * Get service URLs based on environment
 * 
 * - If env vars are set, use them
 * - If in GCP Workstation without env vars, return undefined (misconfigured)
 * - If local development, fall back to localhost
 */
export function getServiceUrls(): ServiceUrls {
  const isWorkstation = isGcpWorkstation();
  
  return {
    nodeUrl: process.env.MIDNIGHT_NODE_URL || 
             (isWorkstation ? undefined : 'ws://localhost:9944'),
    indexerUrl: process.env.INDEXER_URL || 
                (isWorkstation ? undefined : 'http://localhost:8088'),
    proofServerUrl: process.env.PROOF_SERVER_URL || 
                    (isWorkstation ? undefined : 'http://localhost:6300'),
  };
}

/**
 * Service metadata for health checks and display
 */
export const SERVICES = [
  { 
    name: 'Midnight Node', 
    key: 'nodeUrl' as const,
    healthPath: '/health', 
    port: 9944,
    // Node URL may be ws:// but health check needs http://
    convertWsToHttp: true,
  },
  { 
    name: 'Proof Server', 
    key: 'proofServerUrl' as const,
    healthPath: null,  // TCP check only
    port: 6300,
    convertWsToHttp: false,
  },
  { 
    name: 'Indexer', 
    key: 'indexerUrl' as const,
    healthPath: null,  // No /health endpoint, use TCP check
    port: 8088,
    convertWsToHttp: false,
  },
];

/**
 * Well-known chain environment configurations (informational only)
 */
export const CHAIN_ENVIRONMENTS = {
  standalone: {
    name: 'Standalone',
    description: 'Local/cloud development environment',
    // URLs come from env vars or localhost defaults
  },
  testnet: {
    name: 'Testnet',
    description: 'Public test network',
    nodeUrl: 'wss://testnet-node.midnight.network',
    indexerUrl: 'https://testnet-indexer.midnight.network',
    proofServerUrl: 'Local proof server required',
  },
  mainnet: {
    name: 'Mainnet',
    description: 'Production network',
    nodeUrl: 'wss://mainnet-node.midnight.network',
    indexerUrl: 'https://mainnet-indexer.midnight.network',
    proofServerUrl: 'Local proof server required',
  },
} as const;

export type ChainEnvironment = keyof typeof CHAIN_ENVIRONMENTS;
