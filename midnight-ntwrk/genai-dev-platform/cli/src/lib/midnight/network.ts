/**
 * Network auto-detection and configuration utilities
 * 
 * Detection priority:
 * 1. CHAIN_ENVIRONMENT env var (explicit override)
 * 2. Node RPC query (if node is reachable)
 * 3. URL pattern matching (testnet/mainnet in URL)
 * 4. Default to 'standalone'
 */

import { NetworkId, isValidNetworkId, type NetworkDetectionResult, type ServiceUrls } from './types.js';

/**
 * Check if running in a GCP Workstation environment
 */
export function isGcpWorkstation(): boolean {
  return !!process.env.WORKSTATION_ID;
}

/**
 * GraphQL API path for the indexer
 * 
 * Note: indexer-standalone 3.x uses v3 API.
 * v1 endpoints redirect to v3 automatically.
 * This is compatible with node 0.18.0+ and wallet SDK v5.0.0.
 */
const INDEXER_GRAPHQL_PATH = '/api/v3/graphql';
const INDEXER_GRAPHQL_WS_PATH = '/api/v3/graphql/ws';

/**
 * Get service URLs from environment variables
 * 
 * Automatically appends the GraphQL API paths to indexer URLs if missing.
 * Users can specify just the base URL (e.g., http://host:8088) and the
 * correct paths will be added automatically.
 */
export function getServiceUrls(): ServiceUrls {
  const isWorkstation = isGcpWorkstation();
  
  const nodeUrl = process.env.MIDNIGHT_NODE_URL || 
                  (isWorkstation ? undefined : 'ws://localhost:9944');
  
  // Derive HTTP URL from WebSocket URL for health checks
  const nodeHttpUrl = nodeUrl?.replace('ws://', 'http://').replace('wss://', 'https://');
  
  let indexerUrl = process.env.INDEXER_URL || 
                   (isWorkstation ? undefined : 'http://localhost:8088');
  
  // Auto-append GraphQL path if missing
  if (indexerUrl && !indexerUrl.includes(INDEXER_GRAPHQL_PATH)) {
    indexerUrl = indexerUrl.replace(/\/$/, '') + INDEXER_GRAPHQL_PATH;
  }
  
  // Indexer WebSocket URL (for subscriptions)
  let indexerWsUrl = process.env.INDEXER_WS_URL;
  if (!indexerWsUrl && indexerUrl) {
    // Derive from HTTP URL: replace protocol and change path to WS path
    indexerWsUrl = indexerUrl
      .replace('http://', 'ws://')
      .replace('https://', 'wss://')
      .replace(INDEXER_GRAPHQL_PATH, INDEXER_GRAPHQL_WS_PATH);
  } else if (indexerWsUrl && !indexerWsUrl.includes(INDEXER_GRAPHQL_WS_PATH)) {
    // User provided WS URL but without path - append it
    indexerWsUrl = indexerWsUrl.replace(/\/$/, '') + INDEXER_GRAPHQL_WS_PATH;
  }
  
  const proofServerUrl = process.env.PROOF_SERVER_URL || 
                         (isWorkstation ? undefined : 'http://localhost:6300');
  
  return {
    nodeUrl: nodeHttpUrl,
    nodeWsUrl: nodeUrl,
    indexerUrl,
    indexerWsUrl,
    proofServerUrl,
  };
}

/**
 * Try to detect network from URL patterns
 */
function detectNetworkFromUrl(url: string | undefined): NetworkId | null {
  if (!url) return null;
  
  const urlLower = url.toLowerCase();
  
  if (urlLower.includes('mainnet')) return NetworkId.MainNet;
  if (urlLower.includes('testnet')) return NetworkId.TestNet;
  if (urlLower.includes('devnet')) return NetworkId.DevNet;
  if (urlLower.includes('qanet')) return NetworkId.QaNet;
  if (urlLower.includes('preview')) return NetworkId.Preview;
  if (urlLower.includes('preprod')) return NetworkId.PreProd;
  if (urlLower.includes('localhost') || urlLower.includes('127.0.0.1')) return NetworkId.Standalone;
  
  return null;
}

/**
 * Query the node for its network ID
 * This is a placeholder - actual implementation would use RPC
 */
async function queryNodeNetworkId(nodeUrl: string): Promise<NetworkId | null> {
  // TODO: Implement actual RPC call to node
  // For now, return null to fall through to other detection methods
  try {
    // Future: Use WebSocket to query node's chain spec
    return null;
  } catch {
    return null;
  }
}

/**
 * Auto-detect the current network
 * 
 * @returns Network detection result with confidence level
 */
export async function detectNetwork(): Promise<NetworkDetectionResult> {
  // 1. Check explicit environment variable
  const envNetwork = process.env.CHAIN_ENVIRONMENT;
  if (envNetwork && isValidNetworkId(envNetwork)) {
    return {
      network: envNetwork,
      source: 'env',
      confidence: 'high',
    };
  }
  
  const urls = getServiceUrls();
  
  // 2. Try to query the node's network ID
  if (urls.nodeWsUrl) {
    try {
      const networkId = await queryNodeNetworkId(urls.nodeWsUrl);
      if (networkId) {
        return {
          network: networkId,
          source: 'node',
          confidence: 'high',
        };
      }
    } catch {
      // Node not reachable, continue to fallback
    }
  }
  
  // 3. Check URL patterns
  const urlNetwork = detectNetworkFromUrl(urls.nodeWsUrl) || 
                     detectNetworkFromUrl(urls.indexerUrl);
  if (urlNetwork) {
    return {
      network: urlNetwork,
      source: 'url-pattern',
      confidence: 'medium',
    };
  }
  
  // 4. Default to standalone
  return {
    network: NetworkId.Standalone,
    source: 'default',
    confidence: 'low',
  };
}

/**
 * Synchronously get the current network (uses env var only)
 * Use detectNetwork() for async auto-detection
 */
export function getNetworkSync(): NetworkId {
  const envNetwork = process.env.CHAIN_ENVIRONMENT;
  if (envNetwork && isValidNetworkId(envNetwork)) {
    return envNetwork;
  }
  return NetworkId.Standalone;
}

/**
 * Get human-readable network name
 */
export function getNetworkDisplayName(network: NetworkId): string {
  const names: Record<NetworkId, string> = {
    [NetworkId.MainNet]: 'Mainnet',
    [NetworkId.TestNet]: 'Testnet',
    [NetworkId.DevNet]: 'Devnet',
    [NetworkId.QaNet]: 'QA Network',
    [NetworkId.Undeployed]: 'Undeployed (Local)',
    [NetworkId.Preview]: 'Preview',
    [NetworkId.PreProd]: 'Pre-Production',
    [NetworkId.Standalone]: 'Standalone (Local)',
  };
  return names[network] || network;
}

/**
 * Normalize network ID for address encoding
 * 
 * The toolkit and on-chain state use 'undeployed' for local/dev networks,
 * but our UI/detection may use 'standalone'. This function ensures addresses
 * are always encoded with the network ID that matches on-chain expectations.
 * 
 * This is critical because the same raw address bytes encode to different
 * Bech32m strings depending on the network prefix in the address.
 * 
 * @param network - The detected or configured network ID
 * @returns The normalized network ID for address encoding
 */
export function normalizeNetworkForAddresses(network: NetworkId): NetworkId {
  // 'standalone' is our internal name, but on-chain uses 'undeployed'
  if (network === NetworkId.Standalone) {
    return NetworkId.Undeployed;
  }
  return network;
}
